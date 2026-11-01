"""Offline tests of cnda_fetch_ct.py against a local fake XNAT server (no CNDA access).

Run:  conda run -n dynesty2026-feature-mlsiemens python -m pytest ~/MATLAB-Drive/mlsiemens/bin -q
"""
from __future__ import annotations

import base64
import io
import json
import sys
import threading
import zipfile
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))
import cnda_fetch_ct as cf  # noqa: E402

ALIAS, SECRET = "alias-x", "s3cr:et%"
GOOD = "Basic " + base64.b64encode(f"{ALIAS}:{SECRET}".encode()).decode()


def _zip() -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        for scan, n in (("2", 3), ("3", 2)):
            for i in range(n):
                z.writestr(f"108250_PHANTOM/scans/{scan}-CT/resources/DICOM/files/{scan}.{i}.dcm",
                           b"DICM")
    return buf.getvalue()


ZIP = _zip()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):  # quiet
        pass

    def _send(self, code: int, body: bytes, ctype: str = "application/json") -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        if self.headers.get("Authorization") != GOOD:
            return self._send(401, b"")
        path, _, query = self.path.partition("?")
        rs = lambda rows: json.dumps({"ResultSet": {"Result": rows}}).encode()  # noqa: E731
        if path == "/data/projects/CCIR_00970/subjects/108250/experiments":
            return self._send(200, rs([{"ID": "CNDA_E1", "label": "108250_PHANTOM",
                                        "date": "2022-12-07", "time": "12:03:24",
                                        "xsiType": "xnat:petSessionData"}]))
        if path == "/data/experiments/CNDA_E1/scans":
            return self._send(200, rs([{"ID": "2", "type": "AC CT Brain"},
                                       {"ID": "3", "type": "CT Brain"}]))
        if path == "/data/experiments" and "ID=CNDA_E1" in query:
            return self._send(200, rs([{"ID": "CNDA_E1", "label": "108250_PHANTOM"}]))
        if path.startswith("/data/experiments/CNDA_E1/scans/") and "format=zip" in query:
            want = path.split("/scans/")[1].split("/")[0].split(",")
            if "9" in want:
                return self._send(200, _zip_only([]), "application/zip")
            return self._send(200, ZIP, "application/zip")
        return self._send(404, b"")


def _zip_only(scans) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w"):
        pass
    return buf.getvalue()


@pytest.fixture()
def server():
    httpd = HTTPServer(("127.0.0.1", 0), Handler)
    t = threading.Thread(target=httpd.serve_forever, daemon=True)
    t.start()
    yield f"http://127.0.0.1:{httpd.server_port}"
    httpd.shutdown()


def test_credentials_from_env(monkeypatch):
    monkeypatch.setenv("CNDA_ALIAS", ALIAS)
    monkeypatch.setenv("CNDA_SECRET", SECRET)
    assert cf.credentials() == (ALIAS, SECRET)


def test_sessions_and_scans(server):
    c = cf.Cnda(server, ALIAS, SECRET)
    assert c.sessions("CCIR_00970", "108250")[0]["label"] == "108250_PHANTOM"
    assert [r["ID"] for r in c.scans("CNDA_E1")] == ["2", "3"]


def test_bad_token_is_a_clean_error_without_secret(server):
    c = cf.Cnda(server, ALIAS, "BADSECRET-zz9")
    with pytest.raises(cf.CndaError) as e:
        c.scans("CNDA_E1")
    assert "401" in str(e.value) and "BADSECRET-zz9" not in str(e.value)


def test_download_layout_and_sidecar(server, tmp_path):
    c = cf.Cnda(server, ALIAS, SECRET)
    side = cf.cmd_download(c, "CNDA_E1", "2,3", tmp_path)
    root = tmp_path / "108250_PHANTOM"
    assert len(list((root / "DICOMS" / "2" / "DICOM").glob("*.dcm"))) == 3
    assert len(list((root / "DICOMS" / "3" / "DICOM").glob("*.dcm"))) == 2
    assert side["files_per_scan"] == {"2": 3, "3": 2} and side["scans_missing"] == []
    j = json.loads((root / "cnda_fetch.json").read_text())
    assert j["zip_sha256"] == side["zip_sha256"] and SECRET not in json.dumps(j)
    assert not list(tmp_path.glob("tmp*"))  # temporary zip removed


def test_download_missing_scan_fails_loudly(server, tmp_path):
    c = cf.Cnda(server, ALIAS, SECRET)
    with pytest.raises(cf.CndaError, match="no DICOM files"):
        cf.cmd_download(c, "CNDA_E1", "9", tmp_path)
    assert json.loads((tmp_path / "108250_PHANTOM" / "cnda_fetch.json").read_text())[
        "scans_missing"] == ["9"]


def test_cli_exit_code_without_credentials(monkeypatch, capsys):
    monkeypatch.delenv("CNDA_ALIAS", raising=False)
    monkeypatch.delenv("CNDA_SECRET", raising=False)
    monkeypatch.setattr(cf.sys, "platform", "linux")  # skip the Keychain
    assert cf.main(["scans", "--experiment", "X"]) == 2
    assert "no credentials" in capsys.readouterr().err
