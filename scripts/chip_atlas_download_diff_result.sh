#!/bin/bash
# Download ChIP-Atlas Diff Analysis result (ZIP) and optionally extract wabi_result/.
# Companion script to chip_atlas_diff_analysis.sh and chip_atlas_status_log.sh.
#
# Result URL (Diff Analysis wiki):
#   https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas/<requestId>?info=result&format=zip
#
# The ZIP contains:
#   wabi_result/wabi_result.bed
#   wabi_result/wabi_result.igv.bed
#   wabi_result/wabi_result.xml
#   wabi_result/wabi_result.log
#   wabi_result/README.md
#
# Note: Enrichment results use the same ?info=result&format=<fmt> pattern but
# support html/tsv/zip. Diff Analysis exposes only zip (no html/tsv).
set -e
set -u
set -o pipefail

BASE_URL="https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas"

USAGE="Usage: $0 [options] <requestId> [basename]

Download a ChIP-Atlas Diff Analysis result ZIP and extract wabi_result/.

Positional arguments:
  <requestId>     e.g. wabi_chipatlas_2026-0508-1553-59-310-164971
                  (a full result URL is also accepted; only the ID is used)
  [basename]      Output subdirectory name under -o
                  (default: <requestId>)

Options:
  -o <dir>        Output directory (default: ./out/ChIP-Atlas_diff)
  -n              Download ZIP only; do not extract
  -k              Keep the ZIP file after extraction (removed by default)
  -w              Wait mode: poll until the ZIP becomes available or a
                  terminal job state is reached
  -i <sec>        Poll interval in seconds for -w (default: 60)
  -h              Show this help and exit

Examples:
  $0 wabi_chipatlas_2026-0508-1553-59-310-164971 \\
     GSE101731_ATAC-seq_1hHS

  $0 -o ./out/ChIP-Atlas_diff/ATACseq/202605 \\
     -w wabi_chipatlas_2026-0528-1340-29-103-668794 \\
     GSE105028_fast_atacseq

  $0 -n -k wabi_chipatlas_2026-0508-1553-59-310-164971"

OUT_DIR="./out/ChIP-Atlas_diff"
EXTRACT=1
KEEP_ZIP=0
WAIT=0
INTERVAL=60

while getopts ":o:nkwi:h" opt; do
  case "${opt}" in
    o) OUT_DIR="${OPTARG}" ;;
    n) EXTRACT=0 ;;
    k) KEEP_ZIP=1 ;;
    w) WAIT=1 ;;
    i) INTERVAL="${OPTARG}" ;;
    h) echo "${USAGE}"; exit 0 ;;
    \?) echo "ERROR: unknown option -${OPTARG}" >&2; echo "${USAGE}" >&2; exit 2 ;;
    :)  echo "ERROR: option -${OPTARG} requires an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "${USAGE}" >&2
  exit 2
fi

REQ_RAW="$1"
BASENAME="${2:-}"

# Accept a pasted result URL; keep only the request ID segment.
REQ_ID="${REQ_RAW##*/}"
REQ_ID="${REQ_ID%%\?*}"

if ! [[ "${REQ_ID}" =~ ^wabi_chipatlas_[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{2}-[0-9]+-[0-9]+$ ]]; then
  echo "ERROR: invalid requestId: ${REQ_ID}" >&2
  echo "       expected: wabi_chipatlas_YYYY-MMDD-HHMM-SS-NNN-NNNNNN" >&2
  exit 2
fi

if [ -z "${BASENAME}" ]; then
  BASENAME="${REQ_ID}"
fi

mkdir -p "${OUT_DIR}"

RESULT_URL="${BASE_URL}/${REQ_ID}?info=result&format=zip"
STATUS_URL="${BASE_URL}/${REQ_ID}"
DEST_DIR="${OUT_DIR}/${BASENAME}"
ZIP_PATH="${DEST_DIR}/${BASENAME}.zip"

# fetch_status: query the job status endpoint; sets RESULT_STATUS.
RESULT_STATUS=""
fetch_status() {
  local response status_line
  if ! response="$(curl -s --max-time 30 "${STATUS_URL}")"; then
    RESULT_STATUS="curl-error"
    return 1
  fi
  status_line="$(printf '%s\n' "${response}" | tr -d '\r' | grep -E '^status:' || true)"
  RESULT_STATUS="$(printf '%s' "${status_line}" | sed -E 's/^status:[[:space:]]*//;s/[[:space:]]+$//')"
}

# probe_zip: HEAD-like probe via GET with Range; returns HTTP code in PROBE_HTTP.
PROBE_HTTP=""
probe_zip() {
  PROBE_HTTP="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "${RESULT_URL}")"
}

# fetch_log: download wabi_result.log text (available even when zip is missing).
fetch_log() {
  curl -s --max-time 30 "${BASE_URL}/${REQ_ID}?info=result&format=log"
}

# show_failure_diagnostics: on zip 404, print server log hints to stderr.
show_failure_diagnostics() {
  local log http_code
  log="$(fetch_log)"
  if printf '%s' "${log}" | grep -q '"Message"'; then
    echo "NOTE: analysis log not ready yet (job may still be running)" >&2
    return 0
  fi
  echo "--- wabi_result.log (${REQ_ID}) ---" >&2
  printf '%s\n' "${log}" >&2
  mkdir -p "${DEST_DIR}"
  printf '%s\n' "${log}" > "${DEST_DIR}/wabi_result.log"
  echo "--- saved -> ${DEST_DIR}/wabi_result.log ---" >&2
  if printf '%s' "${log}" | grep -q '\[ERROR\]'; then
    echo "HINT: status=finished but zip=404 usually means the analysis failed on the server." >&2
    echo "      Re-check SRX IDs / genome, or retry via https://chip-atlas.org/diff_analysis" >&2
  fi
}

# download_zip: fetch the ZIP; exit non-zero on HTTP error or JSON error body.
download_zip() {
  local http_code body
  mkdir -p "${DEST_DIR}"
  echo "Downloading zip -> ${ZIP_PATH}" >&2
  http_code="$(curl -s -w '%{http_code}' --max-time 120 "${RESULT_URL}" -o "${ZIP_PATH}")"
  if [ "${http_code}" != "200" ]; then
    body="$(head -c 500 "${ZIP_PATH}" 2>/dev/null || true)"
    rm -f "${ZIP_PATH}"
    echo "ERROR: download failed (HTTP ${http_code})" >&2
    if printf '%s' "${body}" | grep -q '"Message"'; then
      echo "${body}" >&2
    fi
    echo "       URL: ${RESULT_URL}" >&2
    show_failure_diagnostics
    return 1
  fi
  if [ ! -s "${ZIP_PATH}" ]; then
    rm -f "${ZIP_PATH}"
    echo "ERROR: downloaded ZIP is empty" >&2
    echo "       URL: ${RESULT_URL}" >&2
    return 1
  fi
}

extract_zip() {
  echo "Extracting -> ${DEST_DIR}/" >&2
  unzip -q -o "${ZIP_PATH}" -d "${DEST_DIR}"
  if [ "${KEEP_ZIP}" -eq 0 ]; then
    rm -f "${ZIP_PATH}"
  fi
}

{
  echo "--- ChIP-Atlas Diff result download ---"
  echo "  requestId = ${REQ_ID}"
  echo "  basename  = ${BASENAME}"
  echo "  out_dir   = ${OUT_DIR}"
  echo "  dest_dir  = ${DEST_DIR}"
  echo "  url       = ${RESULT_URL}"
  echo "  extract   = $([ "${EXTRACT}" -eq 1 ] && echo yes || echo no)"
  echo "  wait      = $([ "${WAIT}" -eq 1 ] && echo yes || echo no)"
  echo "---------------------------------------"
} >&2

if [ "${WAIT}" -eq 1 ]; then
  while true; do
    fetch_status || true
    probe_zip
    case "${RESULT_STATUS}" in
      finished)
        if [ "${PROBE_HTTP}" = "200" ]; then
          break
        fi
        # status=finished with zip=404 usually means the analysis failed on the server.
        log_on_finished=""
        log_on_finished="$(fetch_log 2>/dev/null || true)"
        if printf '%s' "${log_on_finished}" | grep -q '\[ERROR\]'; then
          echo "ERROR: job finished but analysis failed on the server (zip=HTTP:${PROBE_HTTP})" >&2
          show_failure_diagnostics
          exit 1
        fi
        printf '[%s] status=%s zip=HTTP:%s (waiting...)\n' \
          "$(date +'%Y-%m-%dT%H:%M:%S%z')" "${RESULT_STATUS:-?}" "${PROBE_HTTP}" >&2
        ;;
      not-found)
        echo "ERROR: job reached terminal state 'not-found'; result unavailable" >&2
        exit 1
        ;;
      *)
        printf '[%s] status=%s zip=HTTP:%s (waiting...)\n' \
          "$(date +'%Y-%m-%dT%H:%M:%S%z')" "${RESULT_STATUS:-?}" "${PROBE_HTTP}" >&2
        ;;
    esac
    sleep "${INTERVAL}"
  done
fi

download_zip
if [ "${EXTRACT}" -eq 1 ]; then
  extract_zip
fi

echo "Done." >&2
if [ "${EXTRACT}" -eq 1 ]; then
  echo "  wabi_result/ -> ${DEST_DIR}/wabi_result/" >&2
fi
