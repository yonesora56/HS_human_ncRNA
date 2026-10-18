#!/bin/bash
# End-to-end ChIP-Atlas Diff Analysis: submit, poll status, download ZIP result.
set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USAGE="Usage: $0 [options] <dataA> <dataB> <antigenClass> <title> [result_basename]

Run submit -> status poll -> result download for Diff Analysis.

Positional arguments:
  <dataA> .. <title>   Passed to chip_atlas_diff_analysis.sh
  [result_basename]    Output folder name (default: <title>)

Options:
  (submit)     -t -g -a -b -S -P -x -u  forwarded to chip_atlas_diff_analysis.sh
  -o <dir>     Result root directory (default: ./out/ChIP-Atlas_diff)
  -i <sec>     Poll interval seconds (default: 300)
  -h           Show this help and exit

Example:
  $0 -g hg38 -S '-p epyc -t 360' \\
     ./config/chipatlas_diff_analysis_atac/dataset_A/GSE101731_atacseq_hs_1h.txt \\
     ./config/chipatlas_diff_analysis_atac/dataset_B/GSE101731_atacseq_ctrl.txt \\
     diffbind GSE101731_HS_ATACseq_1h GSE101731_1hHS"

OUT_DIR="./out/ChIP-Atlas_diff"
INTERVAL=300
SUBMIT_OPTS=()
POSITIONAL=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) OUT_DIR="$2"; shift 2 ;;
    -i) INTERVAL="$2"; shift 2 ;;
    -h) echo "${USAGE}"; exit 0 ;;
    -t|-g|-a|-b|-S)
      SUBMIT_OPTS+=("$1" "$2")
      shift 2
      ;;
    -P|-x|-u)
      SUBMIT_OPTS+=("$1")
      shift
      ;;
    --)
      shift
      POSITIONAL+=("$@")
      break
      ;;
    -*)
      echo "ERROR: unknown option $1" >&2
      echo "${USAGE}" >&2
      exit 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ "${#POSITIONAL[@]}" -lt 4 ] || [ "${#POSITIONAL[@]}" -gt 5 ]; then
  echo "${USAGE}" >&2
  exit 2
fi

DATA_A="${POSITIONAL[0]}"
DATA_B="${POSITIONAL[1]}"
ANTIGEN_CLASS="${POSITIONAL[2]}"
TITLE="${POSITIONAL[3]}"
BASENAME="${POSITIONAL[4]:-${TITLE}}"

SUBMIT_LOG="${OUT_DIR}/log/${BASENAME}_submit.log"
STATUS_LOG="${OUT_DIR}/log/${BASENAME}_status.log"
SUBMIT_RESP="${OUT_DIR}/log/${BASENAME}_submit_response.txt"
mkdir -p "${OUT_DIR}/log"

echo "=== submit $(date -Iseconds) ===" >> "${SUBMIT_LOG}"
"${SCRIPT_DIR}/chip_atlas_diff_analysis.sh" "${SUBMIT_OPTS[@]}" \
  "${DATA_A}" "${DATA_B}" "${ANTIGEN_CLASS}" "${TITLE}" \
  2>> "${SUBMIT_LOG}" | tee "${SUBMIT_RESP}"

REQ_ID="$(grep -E '^requestId:' "${SUBMIT_RESP}" | awk '{print $2}' || true)"
if [ -z "${REQ_ID}" ]; then
  echo "ERROR: requestId not found in submit response" >&2
  exit 1
fi
echo "requestId: ${REQ_ID}" >&2

"${SCRIPT_DIR}/chip_atlas_status_log.sh" -p -i "${INTERVAL}" -o "${STATUS_LOG}" "${REQ_ID}"

"${SCRIPT_DIR}/chip_atlas_download_diff_result.sh" -w -i "${INTERVAL}" \
  -o "${OUT_DIR}" "${REQ_ID}" "${BASENAME}"

echo "Done. Results -> ${OUT_DIR}/${BASENAME}/wabi_result/" >&2
