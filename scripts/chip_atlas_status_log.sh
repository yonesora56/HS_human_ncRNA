#!/bin/bash
# Poll a ChIP-Atlas wabi job status and append timestamped snapshots to a log.
# Companion script to chip_atlas_enrichment_analysis.sh.
#
# Modes:
#   - One-shot (default): query status once, append to log, print to stdout.
#   - Polling   (-p):     loop until a terminal state is observed.
#
# Terminal states (see header note #4 of chip_atlas_enrichment_analysis.sh):
#   - 'finished'  : job completed; result TSV is downloadable.
#   - 'not-found' : job missing on server (timeout / purged / never queued).
#
# The log file uses an append-only block format:
#   === [2026-05-12T09:39:40+0900] requestId=wabi_chipatlas_... status=running ===
#   <raw wabi response body>
#   <blank line>
# This format keeps every snapshot independently parseable while remaining
# easy to skim by eye.
set -e
set -u
set -o pipefail

USAGE="Usage: $0 [options] <requestId>

Poll a ChIP-Atlas wabi job status and append a timestamped snapshot to a log.

Positional argument:
  <requestId>     e.g. wabi_chipatlas_2026-0512-0938-30-241-312565

Options:
  -p              Polling mode: loop until a terminal state ('finished'
                  or 'not-found') is observed. Without -p, queries once.
  -i <sec>        Polling interval in seconds (default: 300, i.e. 5 min).
                  Only effective with -p.
  -o <path>       Log file path
                  (default: ./out/chipatlas/<requestId>.statuslog.txt)
  -h              Show this help and exit

Examples:
  # One-shot status snapshot (also appended to default log)
  $0 wabi_chipatlas_2026-0512-0938-30-241-312565

  # Poll every 10 min until the job terminates
  $0 -p -i 600 wabi_chipatlas_2026-0512-0938-30-241-312565

  # Poll with a custom log file path
  $0 -p -o ./logs/myjob.log wabi_chipatlas_2026-0512-0938-30-241-312565"

POLL=0
INTERVAL=300
LOG_FILE=""

while getopts ":pi:o:h" opt; do
  case "${opt}" in
    p) POLL=1 ;;
    i) INTERVAL="${OPTARG}" ;;
    o) LOG_FILE="${OPTARG}" ;;
    h) echo "${USAGE}"; exit 0 ;;
    \?) echo "ERROR: unknown option -${OPTARG}" >&2; echo "${USAGE}" >&2; exit 2 ;;
    :)  echo "ERROR: option -${OPTARG} requires an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 1 ]; then
  echo "${USAGE}" >&2
  exit 2
fi
REQ_ID="$1"

# Resolve default log file path under ./out/chipatlas/ if -o was not given.
if [ -z "${LOG_FILE}" ]; then
  LOG_FILE="./out/chipatlas/${REQ_ID}.statuslog.txt"
fi
mkdir -p "$(dirname "${LOG_FILE}")"

ENDPOINT="https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas/${REQ_ID}"

# write_block: emit one log block (header + raw body + trailing blank line).
write_block() {
  local ts="$1" status="$2" body="$3"
  printf '=== [%s] requestId=%s status=%s ===\n%s\n\n' \
    "${ts}" "${REQ_ID}" "${status:-?}" "${body}"
}

# query_once: fetch the current status, append the block to the log file,
# and emit human-facing output. Sets the global RESULT_STATUS.
RESULT_STATUS=""
query_once() {
  local ts response status_line status_value
  ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  if ! response="$(curl -s --max-time 30 "${ENDPOINT}")"; then
    response="(curl error: failed to fetch ${ENDPOINT})"
    status_value="curl-error"
  else
    # Strip CR from possible CRLF line endings before parsing.
    status_line="$(printf '%s\n' "${response}" | tr -d '\r' | grep -E '^status:' || true)"
    status_value="$(printf '%s' "${status_line}" | sed -E 's/^status:[[:space:]]*//;s/[[:space:]]+$//')"
  fi
  RESULT_STATUS="${status_value}"

  write_block "${ts}" "${status_value}" "${response}" >> "${LOG_FILE}"

  if [ "${POLL}" -eq 0 ]; then
    # One-shot: print the full block to stdout for direct viewing.
    write_block "${ts}" "${status_value}" "${response}"
  else
    # Polling: keep stdout quiet, surface a one-line summary on stderr.
    printf '[%s] status=%s\n' "${ts}" "${status_value:-?}" >&2
  fi
}

# One-shot mode: single query, then exit.
if [ "${POLL}" -eq 0 ]; then
  query_once
  exit 0
fi

# Polling mode: loop until a terminal state is reached.
{
  printf '[%s] polling start  endpoint=%s\n' \
    "$(date +'%Y-%m-%dT%H:%M:%S%z')" "${ENDPOINT}"
  printf '[%s] polling start  interval=%ds  log=%s\n' \
    "$(date +'%Y-%m-%dT%H:%M:%S%z')" "${INTERVAL}" "${LOG_FILE}"
} >&2

while true; do
  query_once
  case "${RESULT_STATUS}" in
    finished|not-found)
      printf '[%s] terminal state reached: %s\n' \
        "$(date +'%Y-%m-%dT%H:%M:%S%z')" "${RESULT_STATUS}" >&2
      exit 0
      ;;
  esac
  sleep "${INTERVAL}"
done
