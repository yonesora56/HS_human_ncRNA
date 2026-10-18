#!/bin/bash
# Submit a ChIP-Atlas Diff Analysis job (typeA=srx, typeB=srx)
# Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically
#
# IMPORTANT (server-side quirks confirmed empirically / in-repo logs):
#   1. bedAFile / bedBFile accept plain-text ID lists (one experimental ID per line),
#      or URL rows (bigWig<TAB>bed<TAB>reads for diffbind; methyl.bw URL for dmr).
#   2. The 'sbatchOptions' parameter is effectively REQUIRED. Without it,
#      submit returns a requestId but the job is never dispatched
#      ("status: not-found" persists indefinitely).
#   3. cellClass must be the fixed literal 'empty' (Diff Analysis has no cell filter).
#   4. Status terminal state is 'finished' (not 'done').
#   5. antigenClass selects the detection method:
#        diffbind  -> DPR (Differential Peak Region) detection
#        dmr       -> DMR (Differential Methylated Region) detection
#      For dmr the web UI uses threshold=999 (not 50). This script auto-overrides -t.
#   6. The default SLURM wall-time of 180 min may be insufficient for large ID lists.
#      Override sbatchOptions via -S, e.g. -S '-p epyc -t 1440'.
#   7. If status=finished but result zip returns HTTP 404, the analysis failed on the
#      server. Inspect the log with chip_atlas_download_diff_result.sh (prints log on 404).
#   8. Preflight (-P, default on) checks that each SRX/GSM has ChIP-Atlas bigWig/BED files
#      for the selected genome. Example: GSE105028 control SRX3316067 is absent (HTTP 404).
#   9. Use -u to convert accession ID lists into ChIP-Atlas URL rows before submit
#      (fallback when plain ID lookup fails on the server).
set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/chip_atlas_diff_common.sh
source "${SCRIPT_DIR}/chip_atlas_diff_common.sh"

USAGE="Usage: $0 [options] <dataA> <dataB> <antigenClass> <title>

Submit a ChIP-Atlas Diff Analysis job (typeA=srx, typeB=srx).

Positional arguments:
  <dataA>          Dataset A list file (one SRX/GSM/DRX/ERX ID or URL row per line)
  <dataB>          Dataset B list file
  <antigenClass>   diffbind (DPR) | dmr (DMR)
  <title>          Job title (also used to derive default DESC_A/DESC_B)

Options:
  -t <threshold>   diffbind: 50 | 100 | 200 (default: 50). dmr: auto 999.
  -g <genome>      Genome: hg38 | hg19 | mm10 | mm9 | rn6 | dm6 | ... (default: hg38)
  -a <descA>       descriptionA (default: basename of <dataA> without extension)
  -b <descB>       descriptionB (default: basename of <dataB> without extension)
  -S <sbatchOpts>  SLURM sbatch options (default: '-p epyc -t 180')
  -P               Run preflight checks (default)
  -x               Skip preflight checks
  -u               Convert accession ID lists to ChIP-Atlas URL rows before submit
  -h               Show this help and exit

Examples:
  $0 ./config/chipatlas_diff_analysis_atac/dataset_A/GSE101731_atacseq_hs_1h.txt \\
     ./config/chipatlas_diff_analysis_atac/dataset_B/GSE101731_atacseq_ctrl.txt \\
     diffbind GSE101731_HS_ATACseq_1h

  $0 -u -g hg38 ./dataA_srx.txt ./dataB_srx.txt diffbind hs_vs_ctrl_url

  $0 -x ./dataA.txt ./dataB.txt dmr bs_dmr_job"

THRESHOLD="50"
GENOME="hg38"
DESC_A=""
DESC_B=""
SBATCH_OPTIONS="-p epyc -t 180"
PREFLIGHT=1
URL_INPUT=0

while getopts ":t:g:a:b:S:Pxuh" opt; do
  case "${opt}" in
    t) THRESHOLD="${OPTARG}" ;;
    g) GENOME="${OPTARG}" ;;
    a) DESC_A="${OPTARG}" ;;
    b) DESC_B="${OPTARG}" ;;
    S) SBATCH_OPTIONS="${OPTARG}" ;;
    P) PREFLIGHT=1 ;;
    x) PREFLIGHT=0 ;;
    u) URL_INPUT=1 ;;
    h) echo "${USAGE}"; exit 0 ;;
    \?) echo "ERROR: unknown option -${OPTARG}" >&2; echo "${USAGE}" >&2; exit 2 ;;
    :)  echo "ERROR: option -${OPTARG} requires an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 4 ]; then
  echo "${USAGE}" >&2
  exit 2
fi
DATA_A="$1"
DATA_B="$2"
ANTIGEN_CLASS="$3"
TITLE="$4"

case "${ANTIGEN_CLASS}" in
  diffbind|dmr) ;;
  *)
    echo "ERROR: antigenClass must be 'diffbind' or 'dmr', got: ${ANTIGEN_CLASS}" >&2
    exit 2
    ;;
esac

if [ "${ANTIGEN_CLASS}" = "dmr" ]; then
  THRESHOLD="999"
fi

for f in "${DATA_A}" "${DATA_B}"; do
  if [ ! -f "${f}" ]; then
    echo "ERROR: ID list file not found: ${f}" >&2
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

NORM_A="${TMP_DIR}/dataA.norm.txt"
NORM_B="${TMP_DIR}/dataB.norm.txt"
chip_atlas_diff_normalize_id_file "${DATA_A}" "${NORM_A}"
chip_atlas_diff_normalize_id_file "${DATA_B}" "${NORM_B}"

SUBMIT_A="${NORM_A}"
SUBMIT_B="${NORM_B}"

if [ "${URL_INPUT}" -eq 1 ]; then
  SUBMIT_A="${TMP_DIR}/dataA.url.txt"
  SUBMIT_B="${TMP_DIR}/dataB.url.txt"
  chip_atlas_diff_convert_to_url_file "${NORM_A}" "${SUBMIT_A}" "${GENOME}" "${ANTIGEN_CLASS}" "${THRESHOLD}"
  chip_atlas_diff_convert_to_url_file "${NORM_B}" "${SUBMIT_B}" "${GENOME}" "${ANTIGEN_CLASS}" "${THRESHOLD}"
fi

count_ids() {
  local f="$1"
  grep -cve '^[[:space:]]*$' -e '^[[:space:]]*#' "${f}" || true
}

warn_unusual_lines() {
  local label="$1" f="$2"
  local bad=""
  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line//$'\r'/}"
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    kind="$(chip_atlas_diff_line_kind "${line}")"
    if [ "${kind}" = "bad" ]; then
      bad="${bad}${line}"$'\n'
      if [ "$(printf '%s' "${bad}" | grep -c .)" -ge 5 ]; then
        break
      fi
    fi
  done < "${f}"
  if [ -n "${bad}" ]; then
    echo "WARNING: ${label} contains lines that are neither accession IDs nor URL rows:" >&2
    printf '%s' "${bad}" | sed '/^$/d' | sed 's/^/  /' >&2
  fi
}

COUNT_A="$(count_ids "${SUBMIT_A}")"
COUNT_B="$(count_ids "${SUBMIT_B}")"
if [ "${COUNT_A}" -eq 0 ] || [ "${COUNT_B}" -eq 0 ]; then
  echo "ERROR: empty dataset after normalization/conversion" >&2
  exit 1
fi
warn_unusual_lines "dataA" "${SUBMIT_A}"
warn_unusual_lines "dataB" "${SUBMIT_B}"

if [ "${PREFLIGHT}" -eq 1 ]; then
  echo "--- Preflight: ChIP-Atlas asset checks ---" >&2
  PREFLIGHT_FAIL=0
  chip_atlas_diff_preflight_file "dataA" "${SUBMIT_A}" "${GENOME}" "${ANTIGEN_CLASS}" "${THRESHOLD}"
  chip_atlas_diff_preflight_file "dataB" "${SUBMIT_B}" "${GENOME}" "${ANTIGEN_CLASS}" "${THRESHOLD}"
  if [ "${PREFLIGHT_FAIL}" -ne 0 ]; then
    echo "ERROR: preflight failed; fix missing IDs/assets or retry with -x to force submit" >&2
    exit 1
  fi
  echo "Preflight OK." >&2
fi

if [ -z "${DESC_A}" ]; then
  DESC_A="$(basename "${DATA_A}")"
  DESC_A="${DESC_A%.*}"
fi
if [ -z "${DESC_B}" ]; then
  DESC_B="$(basename "${DATA_B}")"
  DESC_B="${DESC_B%.*}"
fi

{
  echo "--- ChIP-Atlas Diff Analysis submit ---"
  echo "  DATA_A        = ${DATA_A}"
  echo "  DATA_B        = ${DATA_B}"
  if [ "${URL_INPUT}" -eq 1 ]; then
    echo "  INPUT_MODE    = url (converted from accession IDs)"
  else
    echo "  INPUT_MODE    = accession / URL rows as-is"
  fi
  echo "  |A|           = ${COUNT_A} lines ($(du -h "${SUBMIT_A}" | cut -f1))"
  echo "  |B|           = ${COUNT_B} lines ($(du -h "${SUBMIT_B}" | cut -f1))"
  echo "  GENOME        = ${GENOME}"
  echo "  ANTIGEN_CLASS = ${ANTIGEN_CLASS}"
  echo "  CELL_CLASS    = empty"
  echo "  THRESHOLD     = ${THRESHOLD}"
  echo "  TITLE         = ${TITLE}"
  echo "  DESC_A        = ${DESC_A}"
  echo "  DESC_B        = ${DESC_B}"
  echo "  SBATCH_OPT    = ${SBATCH_OPTIONS}"
  echo "  PREFLIGHT     = $([ "${PREFLIGHT}" -eq 1 ] && echo on || echo off)"
  echo "---------------------------------------"
} >&2

curl -sS -X POST \
  -d "address=" \
  -d "format=text" \
  -d "result=www" \
  -d "genome=${GENOME}" \
  -d "antigenClass=${ANTIGEN_CLASS}" \
  -d "cellClass=empty" \
  -d "threshold=${THRESHOLD}" \
  -d "typeA=srx" \
  --data-urlencode "bedAFile@${SUBMIT_A}" \
  -d "typeB=srx" \
  --data-urlencode "bedBFile@${SUBMIT_B}" \
  -d "permTime=1" \
  -d "title=${TITLE}" \
  -d "descriptionA=${DESC_A}" \
  -d "descriptionB=${DESC_B}" \
  -d "sbatchOptions=${SBATCH_OPTIONS}" \
  https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas/
