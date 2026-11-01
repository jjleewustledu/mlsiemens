#!/usr/bin/env python3
"""Find and download CT DICOMs from CNDA (XNAT 1.9) for bottle-phantom PET sessions.

Credentials are an XNAT alias token (CNDA: user menu -> Manage Alias Tokens), used as HTTP
basic auth, and are never printed.  They come from, in order:

  1. environment variables CNDA_ALIAS and CNDA_SECRET (the CNDA guide's convention), or
  2. the macOS Keychain item with service "cnda.wustl.edu" (account = alias, password = secret),
     created once with:  security add-generic-password -s cnda.wustl.edu -a <alias> -w

Subcommands (all read-only on CNDA):

  sessions  --project P --subject S            experiments of a subject, with date/time/type
  scans     --experiment ID                    scans of an experiment (ID, type, description, frames)
  download  --experiment ID --scans 2,3 --out DIR
            writes DIR/<experiment label>/DICOMS/<scan>/DICOM/*.dcm, the layout that
            mlsiemens.BrainMoCoBuilder.dcm2niix() searches, plus a provenance sidecar
            DIR/<experiment label>/cnda_fetch.json (URL, scans, file counts, SHA-256 of the zip)

Example (run by the operator, e.g. with "!" in Claude Code):
  conda run -n dynesty2026-feature-mlsiemens python ~/MATLAB-Drive/mlsiemens/bin/cnda_fetch_ct.py \
      sessions --project CCIR_00970 --subject 108250

Standard library only.  Created 01-Nov-2026 for mlsiemens/data/crosscal_phantoms.csv.
"""
from __future__ import annotations

import argparse
import base64
import datetime as _dt
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

DEFAULT_SERVER = "https://cnda.wustl.edu"
KEYCHAIN_SERVICE = "cnda.wustl.edu"


class CndaError(RuntimeError):
    """Raised for HTTP or authentication failures, with a message safe to print."""


def credentials() -> tuple[str, str]:
    """Return (alias, secret) from the environment or the macOS Keychain; never print them."""
    alias, secret = os.environ.get("CNDA_ALIAS"), os.environ.get("CNDA_SECRET")
    if alias and secret:
        return alias, secret
    if sys.platform == "darwin" and shutil.which("security"):
        attrs = subprocess.run(["security", "find-generic-password", "-s", KEYCHAIN_SERVICE],
                               capture_output=True, text=True)
        secret_out = subprocess.run(
            ["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
            capture_output=True, text=True)
        if attrs.returncode == 0 and secret_out.returncode == 0:
            acct = next((ln.split("=", 1)[1].strip().strip('"')
                         for ln in attrs.stdout.splitlines() if '"acct"<blob>=' in ln), "")
            pw = secret_out.stdout.rstrip("\n")
            if acct and pw:
                return acct, pw
    raise CndaError("no credentials: set CNDA_ALIAS and CNDA_SECRET, or add a Keychain item "
                    f"with service {KEYCHAIN_SERVICE!r}")


class Cnda:
    """Minimal read-only XNAT REST client."""

    def __init__(self, server: str, alias: str, secret: str) -> None:
        self.server = server.rstrip("/")
        token = base64.b64encode(f"{alias}:{secret}".encode()).decode()
        self._auth = f"Basic {token}"

    def _open(self, path: str, params: dict[str, str] | None = None):
        url = self.server + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url, headers={"Authorization": self._auth})
        try:
            return urllib.request.urlopen(req, timeout=300), url
        except urllib.error.HTTPError as e:
            hint = " (alias token expired or wrong? tokens last 90 days)" if e.code == 401 else ""
            raise CndaError(f"HTTP {e.code} for {url}{hint}") from None

    def json(self, path: str, **params: str) -> list[dict]:
        resp, _ = self._open(path, {"format": "json", **params})
        with resp:
            return json.load(resp)["ResultSet"]["Result"]

    def download(self, path: str, dest: Path, **params: str) -> str:
        resp, url = self._open(path, params)
        with resp, open(dest, "wb") as f:
            shutil.copyfileobj(resp, f, length=1 << 20)
        return url

    # ---- queries ----
    def sessions(self, project: str, subject: str) -> list[dict]:
        return self.json(f"/data/projects/{project}/subjects/{subject}/experiments",
                         columns="ID,label,date,time,xsiType,insert_date")

    def scans(self, experiment: str) -> list[dict]:
        return self.json(f"/data/experiments/{experiment}/scans",
                         columns="ID,type,series_description,frames,xsiType,quality,startTime")

    def experiment_label(self, experiment: str) -> str:
        rows = self.json("/data/experiments", ID=experiment, columns="ID,label")
        return rows[0]["label"] if rows else experiment


def rearrange(zip_path: Path, out_root: Path) -> dict[str, int]:
    """Extract an XNAT scans zip into out_root/DICOMS/<scan>/DICOM/; return files per scan.

    XNAT zips hold <label>/scans/<scan>-<type>/resources/DICOM/files/<file>.
    """
    counts: dict[str, int] = {}
    with zipfile.ZipFile(zip_path) as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            parts = Path(info.filename).parts
            if "scans" not in parts:
                continue
            scan = parts[parts.index("scans") + 1].split("-", 1)[0]
            dest = out_root / "DICOMS" / scan / "DICOM" / Path(info.filename).name
            dest.parent.mkdir(parents=True, exist_ok=True)
            with z.open(info) as src, open(dest, "wb") as dst:
                shutil.copyfileobj(src, dst)
            counts[scan] = counts.get(scan, 0) + 1
    return counts


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def cmd_download(c: Cnda, experiment: str, scans: str, out: Path) -> dict:
    label = c.experiment_label(experiment)
    root = out / label
    root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=out) as tmp:
        zpath = Path(tmp) / "scans.zip"
        url = c.download(f"/data/experiments/{experiment}/scans/{scans}/resources/DICOM/files",
                         zpath, format="zip")
        digest = sha256(zpath)
        counts = rearrange(zpath, root)
    requested = [s.strip() for s in scans.split(",") if s.strip()]
    missing = [s for s in requested if counts.get(s, 0) == 0]
    sidecar = {
        "server": c.server, "experiment": experiment, "label": label,
        "scans_requested": requested, "files_per_scan": counts, "scans_missing": missing,
        "url": url, "zip_sha256": digest,
        "fetched": _dt.datetime.now().astimezone().isoformat(timespec="seconds"),
        "tool": "mlsiemens/bin/cnda_fetch_ct.py",
    }
    (root / "cnda_fetch.json").write_text(json.dumps(sidecar, indent=2) + "\n")
    if missing:
        raise CndaError(f"no DICOM files for scans {missing}; see {root / 'cnda_fetch.json'}")
    return sidecar


def _table(rows: list[dict], cols: list[str]) -> str:
    return "\n".join(" | ".join(str(r.get(k, "")) for k in cols) for r in rows)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--server", default=DEFAULT_SERVER)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sessions")
    s.add_argument("--project", required=True)
    s.add_argument("--subject", required=True)
    s = sub.add_parser("scans")
    s.add_argument("--experiment", required=True)
    s = sub.add_parser("download")
    s.add_argument("--experiment", required=True)
    s.add_argument("--scans", required=True, help="comma-separated scan IDs, e.g. 2,3")
    s.add_argument("--out", required=True, type=Path)
    a = p.parse_args(argv)
    try:
        c = Cnda(a.server, *credentials())
        if a.cmd == "sessions":
            print(_table(c.sessions(a.project, a.subject),
                         ["ID", "label", "date", "time", "xsiType"]))
        elif a.cmd == "scans":
            print(_table(c.scans(a.experiment),
                         ["ID", "type", "series_description", "frames", "startTime", "quality"]))
        else:
            print(json.dumps(cmd_download(c, a.experiment, a.scans, a.out), indent=2))
    except CndaError as e:
        print(f"cnda_fetch_ct: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
