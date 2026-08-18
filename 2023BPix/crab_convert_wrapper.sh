#!/bin/bash
set -euo pipefail

echo "=== Args received (argc=$#) ==="
i=1
for a in "$@"; do
  echo "arg[$i] = <$a>"
  i=$((i+1))
done
echo "==============================="

# First arg is the jobID (bare number)
JOBID=$1
shift || true

SCRIPT=""
EVENTS=""
NAMES=""
STAGEOUT_DIR=""
SUBMISSION_TAG=""

# Parse remaining key=value arguments
for a in "$@"; do
  case "$a" in
    script=*)       SCRIPT="${a#*=}" ;;
    events=*)       EVENTS="${a#*=}" ;;
    names=*)        NAMES="${a#*=}" ;;
    stageout_dir=*) STAGEOUT_DIR="${a#*=}" ;;
    submission_tag=*) SUBMISSION_TAG="${a#*=}" ;;
    *) echo "WARNING: unknown arg '$a' (expected script=, events=, names=, submission_tag=, stageout_dir=)" ;;
  esac
done

# To be able to see cms crashed jobs
echo "=== Producing FrameworkJobReport.xml (required by CRAB wrapper) ==="
cmsRun -j FrameworkJobReport.xml PSet.py || true
test -s FrameworkJobReport.xml || { echo "FrameworkJobReport.xml missing/empty"; exit 90; }

# Validate
[[ -n "$SCRIPT" ]] || { echo "ERROR: missing script=..."; exit 2; }
[[ -n "$EVENTS" ]] || { echo "ERROR: missing events=..."; exit 2; }
[[ -n "$NAMES"  ]] || { echo "ERROR: missing names=..."; exit 2; }
[[ -n "$STAGEOUT_DIR" ]] || { echo "ERROR: missing stageout_dir=..."; exit 2; }
[[ -n "$SUBMISSION_TAG" ]] || { echo "ERROR: missing submission_tag=..."; exit 2; }
[[ "$STAGEOUT_DIR" != /* && "$STAGEOUT_DIR" != *".."* ]] || {
  echo "ERROR: stageout_dir must be a safe relative path"
  exit 2
}
[[ "$SUBMISSION_TAG" =~ ^[A-Za-z0-9_-]+$ ]] || {
  echo "ERROR: invalid submission tag: $SUBMISSION_TAG"
  exit 2
}

# Ensure files exist
[[ -f "$SCRIPT" ]] || { echo "ERROR: $SCRIPT not found"; ls -lah; exit 3; }
[[ -f "$NAMES"  ]] || { echo "ERROR: $NAMES not found";  ls -lah; exit 3; }

source "$NAMES"
[[ -n "${NANOAOD_NAME:-}" ]] || { echo "ERROR: NANOAOD_NAME is missing from $NAMES"; exit 4; }

echo "Running: ./$SCRIPT $JOBID $EVENTS $NAMES"
bash "./$SCRIPT" "$JOBID" "$EVENTS" "$NAMES"

echo "Changing filename"
JOBNUM=$((JOBID + 1))
PRODUCED_ROOT="${NANOAOD_NAME}__job-${JOBNUM}.root"
OUTROOT="${NANOAOD_NAME}__job.root"
[[ -f "$PRODUCED_ROOT" ]] || {
  echo "ERROR: expected NanoAOD output $PRODUCED_ROOT was not found"
  ls -lah *.root 2>/dev/null || true
  exit 20
}
mv -- "$PRODUCED_ROOT" "$OUTROOT"

echo "=== Checking Events tree entries in $OUTROOT ==="
NEV="$(root -l -b -q -e "TFile f(\"$OUTROOT\"); auto t=(TTree*)f.Get(\"Events\"); if(!t){std::cout<<0; gSystem->Exit(0);} std::cout<<t->GetEntries(); gSystem->Exit(0);" \
  2>/dev/null | tail -n 1 | tr -d '[:space:]')"
[[ "$NEV" =~ ^[0-9]+$ ]] || NEV=0
echo "Events = $NEV"

STATUS=0
if [[ "$NEV" -eq 0 ]]; then
  echo "ERROR: Events tree has 0 entries"
  STATUS=21
fi

if [[ "$STATUS" -eq 0 ]]; then
  EOS_HOST="root://eosproject.cern.ch"
  EOS_BASE="/eos/project/h/htozg-dy-privatemc"
  REMOTE_PATH="${EOS_BASE}/${STAGEOUT_DIR}"
  REMOTE_FILE="${EOS_HOST}/${REMOTE_PATH}/${NANOAOD_NAME}__job-${JOBNUM}__${SUBMISSION_TAG}.root"

  echo "Creating remote directory: $REMOTE_PATH"
  if ! xrdfs "$EOS_HOST" mkdir -p "$REMOTE_PATH"; then
    echo "ERROR: failed to create remote directory"
    exit 90
  fi

  echo "Copying $OUTROOT to $REMOTE_FILE"
  if ! xrdcp --force --posc "$OUTROOT" "$REMOTE_FILE"; then
    echo "ERROR: manual NanoAOD stageout failed"
    exit 90
  fi

  echo "Manual NanoAOD stageout completed"
fi

exit "$STATUS"
