#!/bin/bash
# Download ChIP-Atlas peak-call BED files for sample_heat_id in a metadata TSV.
# Wiki: https://github.com/inutano/chip-atlas/wiki#peak-call-bed-download-url
#
# ChIP/ATAC/DNase URL pattern:
#   https://chip-atlas.dbcls.jp/data/[Genome]/eachData/bed[Threshold]/[SRX].[Threshold].bed
#   Threshold codes: 05 (Q<1e-05), 10 (Q<1e-10), 20 (Q<1e-20)
#
# Bisulfite-seq URL pattern (-a bs -r <region>):
#   hyper_mr -> .../eachData/bs/hypermr/Bed/[SRX].hypermr.bed
#   hypo_mr  -> .../eachData/bs/hmr/Bed/[SRX].hmr.bed
#   partial_mr -> .../eachData/bs/pmd/Bed/[SRX].pmd.bed
set -e
set -u
set -o pipefail

BASE_URL="https://chip-atlas.dbcls.jp/data"

USAGE="Usage: $0 [options] <metadata.tsv>

Download ChIP-Atlas peak-call BED files for each experiment ID (SRX) in
a tab-delimited metadata file.

Positional argument:
  <metadata.tsv>   TSV with at least sample_heat_id (or -c column) and genome_build

Options:
  -a <assay>       Assay type (default: chip)
                   chip  ChIP/ATAC/DNase MACS2 peaks (bed05/10/20)
                   bs    Bisulfite-seq MR BED (requires -r)
  -r <region>      BS-seq region type when -a bs (required for bs)
                   hyper_mr | hypo_mr | partial_mr
                   Aliases: hypermr, hmr, pmd, hyper, hypo, partial
  -g <genome>      Genome assembly (default: hg38)
                   hg38 | hg19 | mm10 | mm9 | rn6 | dm6 | dm3 | ce11 | ce10 | sacCer3
  -t <threshold>   MACS2 Q-value threshold for -a chip (default: 1e-10)
                   Accepts: 1e-5, 1e-05, 05, 5, 1e-10, 10, 1e-20, 20
  -o <dir>         Output directory (default: ./out/chip_atlas_bed)
  -c <id_col>      Column name for experiment ID (default: sample_heat_id)
  -G               Force -g for every row (ignore genome_build in the TSV)
  -s <sec>         Sleep seconds between downloads (default: 0)
  -h               Show this help and exit

Genome selection (without -G):
  Use genome_build from the TSV when it maps to a supported assembly;
  otherwise fall back to -g.

Logs (under -o):
  download_ok.tsv    SRX, genome, threshold, url, status
  download_fail.tsv  SRX, genome, threshold, url, reason

Examples:
  $0 Data/metadata/metadata_2605/chipseq_metadata_all_260525.tsv

  $0 -g hg19 -t 1e-5 \\
     Data/metadata/metadata_2605/chipseq_metadata_all_260525.tsv

  $0 -G -g hg38 -t 1e-10 -o ./out/chip_atlas_bed/hg38_q10 \\
     Data/metadata/metadata_2605/chipseq_metadata_all_260525.tsv

  $0 -a bs -r hyper_mr -G -g hg38 -c experiment_id \\
     -o ./out/ChIP-Atlas_BED/BS-seq_hyper_mr/ \\
     ./out/ChIP-Atlas_enrichment/up5p_lncRNA_ela_202605_v2/up5p_lncRNA_ela_bs_hyper_mr_enrichment_filter.tsv"

GENOME="hg38"
THRESHOLD="1e-10"
OUT_DIR="./out/chip_atlas_bed"
ID_COL="sample_heat_id"
GENOME_COL="genome_build"
ASSAY="chip"
BS_REGION=""
FORCE_GENOME=0
SLEEP_SEC=0
TSV=""

while getopts ":a:r:g:t:o:c:Gs:h" opt; do
  case "${opt}" in
    a) ASSAY="${OPTARG}" ;;
    r) BS_REGION="${OPTARG}" ;;
    g) GENOME="${OPTARG}" ;;
    t) THRESHOLD="${OPTARG}" ;;
    o) OUT_DIR="${OPTARG}" ;;
    c) ID_COL="${OPTARG}" ;;
    G) FORCE_GENOME=1 ;;
    s) SLEEP_SEC="${OPTARG}" ;;
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
TSV="$1"

if [ ! -f "${TSV}" ]; then
  echo "ERROR: metadata file not found: ${TSV}" >&2
  exit 2
fi

normalize_genome() {
  local raw="$1"
  local g
  g="$(printf '%s' "${raw}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "${g}" in
    hg38|hg19|mm10|mm9|rn6|dm6|dm3|ce11|ce10) printf '%s' "${g}" ;;
    saccer3) printf '%s' "sacCer3" ;;
    *) printf '' ;;
  esac
}

# Map user threshold to ChIP-Atlas directory suffix (05 | 10 | 20).
threshold_code() {
  local t
  t="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "${t}" in
    1e-5|1e-05|1.0e-5|1.0e-05|5|05|q1e-5|q1e-05) printf '05' ;;
    1e-10|1.0e-10|10|q1e-10)                    printf '10' ;;
    1e-20|1.0e-20|20|q1e-20)                    printf '20' ;;
    *)
      echo "ERROR: unsupported threshold '${1}' (use 1e-5, 1e-10, or 1e-20)" >&2
      return 1
      ;;
  esac
}

resolve_genome_arg() {
  local g
  g="$(normalize_genome "$1")"
  if [ -z "${g}" ]; then
    echo "ERROR: unsupported genome '${1}'" >&2
    return 1
  fi
  # ChIP-Atlas paths use sacCer3 (mixed case).
  if [ "${g}" = "saccer3" ]; then
    g="sacCer3"
  fi
  printf '%s' "${g}"
}

# Map -r to ChIP-Atlas path segment and file suffix (hypermr | hmr | pmd).
resolve_bs_region() {
  local raw="$1"
  local r
  r="$(printf '%s' "${raw}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]_-')"
  case "${r}" in
    hypermr|hypermethylatedregion) printf '%s\t%s' "hypermr" "hypermr" ;;
    hypomr|hmr|hypomethylatedregion) printf '%s\t%s' "hmr" "hmr" ;;
    partialmr|pmd|partialmethylatedregion) printf '%s\t%s' "pmd" "pmd" ;;
    *)
      echo "ERROR: unsupported BS-seq region '${1}' (use hyper_mr, hypo_mr, or partial_mr)" >&2
      return 1
      ;;
  esac
}

ASSAY="$(printf '%s' "${ASSAY}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
case "${ASSAY}" in
  chip|bs) ;;
  *)
    echo "ERROR: unsupported assay '${ASSAY}' (use chip or bs)" >&2
    exit 2
    ;;
esac

BED_TAG=""
BS_PATH_DIR=""
BS_FILE_SUFFIX=""

if [ "${ASSAY}" = "bs" ]; then
  if [ -z "${BS_REGION}" ]; then
    echo "ERROR: -a bs requires -r <region> (hyper_mr, hypo_mr, or partial_mr)" >&2
    exit 2
  fi
  mapfile -t BS_INFO < <(resolve_bs_region "${BS_REGION}")
  BS_PATH_DIR="${BS_INFO[0]%%$'\t'*}"
  BS_FILE_SUFFIX="${BS_INFO[0]#*$'\t'}"
  BED_TAG="${BS_FILE_SUFFIX}"
else
  if [ -n "${BS_REGION}" ]; then
    echo "WARN: -r is ignored unless -a bs" >&2
  fi
  BED_TAG="$(threshold_code "${THRESHOLD}")"
fi

FALLBACK_GENOME="$(resolve_genome_arg "${GENOME}")"

mkdir -p "${OUT_DIR}"
LOG_OK="${OUT_DIR}/download_ok.tsv"
LOG_FAIL="${OUT_DIR}/download_fail.tsv"

if [ ! -f "${LOG_OK}" ]; then
  printf 'sample_heat_id\tgenome\tthreshold\turl\tstatus\n' > "${LOG_OK}"
fi
if [ ! -f "${LOG_FAIL}" ]; then
  printf 'sample_heat_id\tgenome\tthreshold\turl\treason\n' > "${LOG_FAIL}"
fi

# Resolve column numbers from the header (1-based for awk).
mapfile -t COL_INFO < <(awk -F'\t' -v id_col="${ID_COL}" -v gb_col="${GENOME_COL}" '
  NR == 1 {
    id_idx = gb_idx = 0
    for (i = 1; i <= NF; i++) {
      if ($i == id_col) id_idx = i
      if ($i == gb_col) gb_idx = i
    }
    if (id_idx == 0) {
      print "ERROR: column not found: " id_col > "/dev/stderr"
      exit 2
    }
    if (gb_idx == 0) {
      print "WARN: column not found: " gb_col " (will use -g for all rows)" > "/dev/stderr"
    }
    print id_idx "\t" gb_idx
    exit
  }
' "${TSV}")

ID_IDX="${COL_INFO[0]%%$'\t'*}"
GB_IDX="${COL_INFO[0]#*$'\t'}"

{
  echo "--- ChIP-Atlas BED download ---"
  echo "  metadata   = ${TSV}"
  echo "  out_dir    = ${OUT_DIR}"
  echo "  assay      = ${ASSAY}"
  if [ "${ASSAY}" = "bs" ]; then
    echo "  bs_region  = ${BS_REGION} (bs/${BS_PATH_DIR}/Bed/*.${BS_FILE_SUFFIX}.bed)"
  else
    echo "  threshold  = ${THRESHOLD} (bed${BED_TAG})"
  fi
  echo "  genome     = ${FALLBACK_GENOME} (fallback; use -G to force for all rows)"
  echo "  id_column  = ${ID_COL} (col ${ID_IDX})"
  echo "  force_genome = ${FORCE_GENOME}"
  echo "-------------------------------"
} >&2

OK_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

while IFS=$'\t' read -r srx gb_raw _rest; do
  [ -z "${srx}" ] && continue

  if [ "${FORCE_GENOME}" -eq 1 ] || [ -z "${GB_IDX}" ] || [ "${GB_IDX}" = "0" ]; then
    genome="${FALLBACK_GENOME}"
  else
    genome="$(normalize_genome "${gb_raw}")"
    if [ -z "${genome}" ]; then
      genome="${FALLBACK_GENOME}"
    fi
  fi

  if [ "${ASSAY}" = "bs" ]; then
    url="${BASE_URL}/${genome}/eachData/bs/${BS_PATH_DIR}/Bed/${srx}.${BS_FILE_SUFFIX}.bed"
    out="${OUT_DIR}/${srx}.${genome}.${BS_FILE_SUFFIX}.bed"
  else
    url="${BASE_URL}/${genome}/eachData/bed${BED_TAG}/${srx}.${BED_TAG}.bed"
    out="${OUT_DIR}/${srx}.${genome}.${BED_TAG}.bed"
  fi

  if [ -s "${out}" ]; then
    printf '%s\t%s\t%s\t%s\tskipped_exists\n' \
      "${srx}" "${genome}" "${BED_TAG}" "${url}" >> "${LOG_OK}"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo "[skip] ${srx} (exists)" >&2
    continue
  fi

  http_code=""
  if http_code="$(curl -fsS -w '%{http_code}' -o "${out}" "${url}" 2>/dev/null)"; then
    if [ "${http_code}" = "200" ] && [ -s "${out}" ]; then
      printf '%s\t%s\t%s\t%s\tok\n' \
        "${srx}" "${genome}" "${BED_TAG}" "${url}" >> "${LOG_OK}"
      OK_COUNT=$((OK_COUNT + 1))
      echo "[ok]   ${srx} -> ${out}" >&2
    else
      rm -f "${out}"
      printf '%s\t%s\t%s\t%s\thttp_${http_code}_empty\n' \
        "${srx}" "${genome}" "${BED_TAG}" "${url}" >> "${LOG_FAIL}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      echo "[fail] ${srx} (HTTP ${http_code})" >&2
    fi
  else
    rm -f "${out}"
    printf '%s\t%s\t%s\t%s\tcurl_error\n' \
      "${srx}" "${genome}" "${BED_TAG}" "${url}" >> "${LOG_FAIL}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "[fail] ${srx} (curl error)" >&2
  fi

  if [ "${SLEEP_SEC}" != "0" ]; then
    sleep "${SLEEP_SEC}"
  fi
done < <(awk -F'\t' -v id_idx="${ID_IDX}" -v gb_idx="${GB_IDX}" '
  NR > 1 {
    srx = $id_idx
    gb = (gb_idx > 0 ? $gb_idx : "")
    print srx "\t" gb
  }
' "${TSV}")

{
  echo "Done."
  echo "  downloaded : ${OK_COUNT}"
  echo "  skipped    : ${SKIP_COUNT}"
  echo "  failed     : ${FAIL_COUNT}"
  echo "  ok log     : ${LOG_OK}"
  echo "  fail log   : ${LOG_FAIL}"
} >&2

if [ "${FAIL_COUNT}" -gt 0 ]; then
  exit 1
fi
