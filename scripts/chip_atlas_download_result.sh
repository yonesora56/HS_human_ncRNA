#!/bin/bash
# Download ChIP-Atlas Enrichment Analysis result files (HTML / TSV / ZIP).
# Companion script to chip_atlas_enrichment_analysis.sh and chip_atlas_status_log.sh.
#
# Base URL pattern (same as manual curl in cmd_history):
#   https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas/<requestId>?info=result&format=<fmt>
set -e
set -u
set -o pipefail

BASE_URL="https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas"

USAGE="Usage: $0 [options] <requestId> [basename]

Download ChIP-Atlas enrichment result files for a finished wabi job.

Positional arguments:
  <requestId>     e.g. wabi_chipatlas_2026-0519-1437-35-448-379093
                  (a full result URL is also accepted; only the ID is used)
  [basename]      Output file prefix without extension
                  (default: <requestId>)

Options:
  -o <dir>        Output directory (default: ./out/chipatlas)
  -f <formats>    Comma-separated: html,tsv,zip (default: html,tsv)
  -h              Show this help and exit

Examples:
  $0 -o ./out/ChIP-Atlas_enrichment/up5p_lncRNA_ela_202605_v2 \\
     wabi_chipatlas_2026-0519-1437-35-448-379093 \\
     up5p_lncRNA_ela_20260512_histone

  $0 wabi_chipatlas_2026-0519-1437-35-448-379093"

OUT_DIR="./out/chipatlas"
FORMATS="html,tsv"

while getopts ":o:f:h" opt; do
  case "${opt}" in
    o) OUT_DIR="${OPTARG}" ;;
    f) FORMATS="${OPTARG}" ;;
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

IFS=',' read -r -a FORMAT_LIST <<< "${FORMATS}"
for fmt in "${FORMAT_LIST[@]}"; do
  fmt="$(printf '%s' "${fmt}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "${fmt}" in
    html|tsv|zip) ;;
    *)
      echo "ERROR: unknown format '${fmt}' (use html, tsv, and/or zip)" >&2
      exit 2
      ;;
  esac
done

download_one() {
  local fmt="$1"
  local url="${BASE_URL}/${REQ_ID}?info=result&format=${fmt}"
  local out="${OUT_DIR}/${BASENAME}.${fmt}"
  echo "Downloading ${fmt} -> ${out}"
  curl -fsSL "${url}" -o "${out}"
}

{
  echo "--- ChIP-Atlas result download ---"
  echo "  requestId = ${REQ_ID}"
  echo "  basename  = ${BASENAME}"
  echo "  out_dir   = ${OUT_DIR}"
  echo "  formats   = ${FORMATS}"
  echo "--------------------------------"
} >&2

for fmt in "${FORMAT_LIST[@]}"; do
  fmt="$(printf '%s' "${fmt}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  download_one "${fmt}"
done

echo "Done." >&2
