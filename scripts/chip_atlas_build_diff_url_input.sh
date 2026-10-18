#!/bin/bash
# Convert an accession ID list into ChIP-Atlas Diff Analysis URL rows.
# Wiki URL format:
#   diffbind: bigWig<TAB>peak-bed<TAB>mapped_reads
#   dmr:      methyl.bw URL
set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/chip_atlas_diff_common.sh
source "${SCRIPT_DIR}/chip_atlas_diff_common.sh"

USAGE="Usage: $0 [options] <srx_list.txt>

Convert one accession ID list to Diff Analysis URL rows (stdout).

Options:
  -g <genome>      Genome assembly (default: hg38)
  -m <method>      diffbind | dmr (default: diffbind)
  -t <threshold>   diffbind threshold: 50 | 100 | 200 (default: 50)
  -o <file>        Write output to file instead of stdout
  -h               Show this help and exit

Example:
  $0 -g hg38 ./dataset_A/GSE101731_atacseq_hs_1h.txt \\
     > ./dataset_A/GSE101731_atacseq_hs_1h.url.txt"

GENOME="hg38"
METHOD="diffbind"
THRESHOLD="50"
OUT_FILE=""

while getopts ":g:m:t:o:h" opt; do
  case "${opt}" in
    g) GENOME="${OPTARG}" ;;
    m) METHOD="${OPTARG}" ;;
    t) THRESHOLD="${OPTARG}" ;;
    o) OUT_FILE="${OPTARG}" ;;
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
IN_FILE="$1"

case "${METHOD}" in
  diffbind|dmr) ;;
  *) echo "ERROR: method must be diffbind or dmr" >&2; exit 2 ;;
esac

if [ "${METHOD}" = "dmr" ]; then
  THRESHOLD="999"
fi

TMP_NORM="$(mktemp)"
TMP_OUT="$(mktemp)"
trap 'rm -f "${TMP_NORM}" "${TMP_OUT}"' EXIT

chip_atlas_diff_normalize_id_file "${IN_FILE}" "${TMP_NORM}"
chip_atlas_diff_convert_to_url_file "${TMP_NORM}" "${TMP_OUT}" "${GENOME}" "${METHOD}" "${THRESHOLD}"

if [ -n "${OUT_FILE}" ]; then
  mkdir -p "$(dirname "${OUT_FILE}")"
  cp "${TMP_OUT}" "${OUT_FILE}"
else
  cat "${TMP_OUT}"
fi
