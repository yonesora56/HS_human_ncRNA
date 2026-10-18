#!/bin/bash
# Submit a ChIP-Atlas Enrichment Analysis job (typeA=bed, typeB=bed)
# Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Enrichment-Analysis-programmatically
#
# IMPORTANT (server-side quirks confirmed empirically):
#   1. Pass raw BED files to --data-urlencode. Do NOT pre-convert tabs/newlines
#      to '_' (the Wiki note "all whitespaces must be converted to '_'" only
#      applies to free-text fields, not to BED field/record separators).
#   2. The 'sbatchOptions' parameter is effectively REQUIRED. Without it,
#      submit returns a requestId but the job is never dispatched
#      ("status: not-found" persists indefinitely).
#   3. cellClass="All cell types" is accepted as a valid wildcard.
#   4. Status terminal state is 'finished' (not 'done').
#   5. For antigenClass=Bisulfite-Seq, the server-side threshold dropdown
#      collapses to a single "NA" option whose internal value is 999.
#      Passing 50/100/200/500 (the values documented in the Wiki) results
#      in the job never being dispatched. This script auto-overrides
#      THRESHOLD to 999 when antigenClass=Bisulfite-Seq.
#   6. The default SLURM wall-time of 180 min is often insufficient for
#      heavy combinations (e.g. BS-Seq x cellClass="All cell types" x
#      megabyte-scale Dataset B). When the limit is hit, status flips
#      from 'running' to 'not-found' and the result file is purged.
#      Override sbatchOptions via -S, e.g. -S '-p epyc -t 1440'.
set -e
set -u
set -o pipefail

USAGE="Usage: $0 [options] <bedA> <bedB> <antigenClass> <title>

Submit a ChIP-Atlas Enrichment Analysis job (typeA=bed, typeB=bed).

Positional arguments:
  <bedA>           Dataset A BED file path
  <bedB>           Dataset B BED file path
  <antigenClass>   Histone | TFs and others | RNA polymerase
                   | ATAC-Seq | DNase-seq | Bisulfite-Seq | Input control
  <title>          Job title (also used to derive default DESC_A/DESC_B)

Options:
  -c <cellClass>   Cell type class (default: 'All cell types')
  -t <threshold>   MACS2 q-value threshold: 50 | 100 | 200 | 500 (default: 100)
  -g <genome>      Genome: hg38 | hg19 | mm10 | mm9 | ... (default: hg38)
  -a <descA>       descriptionA (default: basename of <bedA> without .bed)
  -b <descB>       descriptionB (default: basename of <bedB> without .bed)
  -S <sbatchOpts>  SLURM sbatch options (default: '-p epyc -t 180').
                   Use a longer -t for heavy jobs, e.g. '-p epyc -t 1440'
                   for BS-Seq + 'All cell types' + MB-scale Dataset B.
  -h               Show this help and exit

Examples:
  $0 ./out/fantabio/BED/fantabio_up5p_lncRNA_pla.bed \\
     ./out/fantabio/BED/human-CREv1.2.0.hg38.cre-peaks_pla.bed \\
     'RNA polymerase' \\
     up5p_lncRNA_cre_pla_rpb

  $0 -c Blood -t 50 ./bedA.bed ./bedB.bed Histone hist_blood_job

  $0 -S '-p epyc -t 1440' ./bedA.bed ./bedB.bed Bisulfite-Seq bs_24h_job"

# Default option values
CELL_CLASS="All cell types"
THRESHOLD="100"
GENOME="hg38"
DESC_A=""
DESC_B=""
# Default SLURM options (epyc partition, 180 min wall-time).
# Override via -S for heavy jobs (see header note #6).
SBATCH_OPTIONS="-p epyc -t 180"

# Parse flag options
while getopts ":c:t:g:a:b:S:h" opt; do
  case "${opt}" in
    c) CELL_CLASS="${OPTARG}" ;;
    t) THRESHOLD="${OPTARG}" ;;
    g) GENOME="${OPTARG}" ;;
    a) DESC_A="${OPTARG}" ;;
    b) DESC_B="${OPTARG}" ;;
    S) SBATCH_OPTIONS="${OPTARG}" ;;
    h) echo "${USAGE}"; exit 0 ;;
    \?) echo "ERROR: unknown option -${OPTARG}" >&2; echo "${USAGE}" >&2; exit 2 ;;
    :)  echo "ERROR: option -${OPTARG} requires an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

# Positional arguments
if [ "$#" -ne 4 ]; then
  echo "${USAGE}" >&2
  exit 2
fi
BED_A="$1"
BED_B="$2"
ANTIGEN_CLASS="$3"
TITLE="$4"

# Bisulfite-Seq has no MACS2 q-value threshold on the server side;
# the web form forces threshold to "NA" (internal value 999).
# Override the user-specified -t value only for this antigen class.
if [ "${ANTIGEN_CLASS}" = "Bisulfite-Seq" ]; then
  THRESHOLD="999"
fi

# Validate BED file existence
for f in "${BED_A}" "${BED_B}"; do
  if [ ! -f "${f}" ]; then
    echo "ERROR: BED file not found: ${f}" >&2
    exit 1
  fi
done

# Derive default DESC_A / DESC_B from BED basenames if not specified
if [ -z "${DESC_A}" ]; then
  DESC_A="$(basename "${BED_A}" .bed)"
fi
if [ -z "${DESC_B}" ]; then
  DESC_B="$(basename "${BED_B}" .bed)"
fi

# Show the resolved parameters (to stderr so stdout stays curl-only)
# |A| / |B| line counts and file sizes are logged as a rough cost proxy
# so the operator can pick an appropriate -t value (see header note #6).
{
  echo "--- ChIP-Atlas Enrichment Analysis submit ---"
  echo "  BED_A         = ${BED_A}"
  echo "  BED_B         = ${BED_B}"
  echo "  |A|           = $(wc -l < "${BED_A}") regions ($(du -h "${BED_A}" | cut -f1))"
  echo "  |B|           = $(wc -l < "${BED_B}") regions ($(du -h "${BED_B}" | cut -f1))"
  echo "  GENOME        = ${GENOME}"
  echo "  ANTIGEN_CLASS = ${ANTIGEN_CLASS}"
  echo "  CELL_CLASS    = ${CELL_CLASS}"
  echo "  THRESHOLD     = ${THRESHOLD}"
  echo "  TITLE         = ${TITLE}"
  echo "  DESC_A        = ${DESC_A}"
  echo "  DESC_B        = ${DESC_B}"
  echo "  SBATCH_OPT    = ${SBATCH_OPTIONS}"
  echo "---------------------------------------------"
} >&2

# Submit the job (the response body containing requestId goes to stdout)
curl -X POST \
  -d "format=text" \
  -d "result=www" \
  -d "genome=${GENOME}" \
  -d "antigenClass=${ANTIGEN_CLASS}" \
  -d "cellClass=${CELL_CLASS}" \
  -d "threshold=${THRESHOLD}" \
  -d "typeA=bed" \
  --data-urlencode "bedAFile@${BED_A}" \
  -d "typeB=bed" \
  --data-urlencode "bedBFile@${BED_B}" \
  -d "permTime=1" \
  -d "title=${TITLE}" \
  -d "descriptionA=${DESC_A}" \
  -d "descriptionB=${DESC_B}" \
  -d "sbatchOptions=${SBATCH_OPTIONS}" \
  https://dtn1.ddbj.nig.ac.jp/wabi/chipatlas/
