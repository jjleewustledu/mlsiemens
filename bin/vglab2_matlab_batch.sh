#!/usr/bin/bash
# Runs one mlsiemens unit test (or MATLAB statement) unattended on vglab2, for orchestration
# from the MacBook over ssh; vglab2 runs no Claude.  Writes, under $LOGDIR:
#   <tag>.log   MATLAB output, with the mlsiemens commit and tool paths
#   <tag>.done  "EXIT=<code>" when finished (0 = all selected tests passed)
#
# Usage (from the MacBook):
#   ssh vglab2.neuroimage.wustl.edu \
#     'nohup ~/MATLAB-Drive/mlsiemens/bin/vglab2_matlab_batch.sh <tag> <TestClass/procedure> [VAR=value ...] \
#        >/dev/null 2>&1 </dev/null &'
#   e.g. stage_108284 Test_JSReconBuilder_Win/test_BMCBuilder_build_crosscal_manifest SUBS=108284
# then poll for $LOGDIR/<tag>.done.
set -u
tag="$1"; test="$2"; shift 2
for kv in "$@"; do export "$kv"; done

LOGDIR="${LOGDIR:-/vgpool02/data2/jjlee/bmcbuilder/logs}"
mkdir -p "$LOGDIR"
log="$LOGDIR/$tag.log"; done_f="$LOGDIR/$tag.done"
rm -f "$done_f"

cd /vgpool02/data2/jjlee/bmcbuilder
. /data/nil-bluearc/vlassenko/jjlee/miniconda3/etc/profile.d/conda.sh
conda activate siemens_matlab_r2024a
export PATH="$HOME/.local/bin:$PATH"   # dcm2niix_20230411
export PROJECT_FOLDER="${PROJECT_FOLDER:-CCIR_01211}"

repo="$HOME/MATLAB-Drive/mlsiemens"
cls="${test%%/*}"; proc="${test#*/}"
{
    echo "START $(date -Is) tag=$tag test=$test mlsiemens=$(git -C "$repo" rev-parse --short HEAD)" \
         "dirty=$(git -C "$repo" status --porcelain --untracked-files=no | wc -l) conda=$CONDA_DEFAULT_ENV" \
         "dcm2niix=$(command -v dcm2niix_20230411) env:$*"
    /usr/local/pkg/MATLAB/R2024a/bin/matlab -batch \
        "addpath(fullfile('$repo','test')); r = runtests('mlsiemens_unittest.$cls', ProcedureName='$proc'); disp(table(r)); exit(double(isempty(r) || any([r.Failed] | [r.Incomplete])))"
    rc=$?
    echo "END $(date -Is) EXIT=$rc"
} > "$log" 2>&1
echo "EXIT=$rc" > "$done_f"
