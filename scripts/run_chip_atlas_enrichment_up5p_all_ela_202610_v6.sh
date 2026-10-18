#!/usr/bin/env bash
# Submit the seven ChIP-Atlas enrichment jobs for up5p all-ELA CREs.
# Query BED (bed_a): out/fantabio/BEDfile/up5p/fantabio_up5p_all_ela_v261001.bed
#
# Run from the repository root:
#   bash ./scripts/run_chip_atlas_enrichment_up5p_all_ela_202610_v6.sh

set -euo pipefail

OUTDIR="./out/ChIP-Atlas_enrichment/up5p_all_ela_202610_v6_gncd_linked"
WORKFLOW="./Workflow/chip_atlas_enrichment_job.cwl"
CONFIG_DIR="./config/chipatlas_enrichment/up5p_all_ela_single"
CACHEDIR="./tmp"

mkdir -p "${OUTDIR}"

configs=(
  "1_up5p_all_ela_single_histone.yml"   # Histone
  "2_up5p_all_ela_single_atac.yml"      # ATAC-Seq
  "3_up5p_all_ela_single_tf.yml"        # TFs and others
  "4_up5p_all_ela_single_pol.yml"       # RNA polymerase
  "5_up5p_all_ela_single_dnase.yml"     # DNase-seq
  "6_up5p_all_ela_single_bs.yml"        # Bisulfite-Seq
  "7_up5p_all_ela_single_ip.yml"        # Input control
)

for config in "${configs[@]}"; do
  echo "=== ${config} ==="
  cwltool \
    --cachedir "${CACHEDIR}" \
    --outdir "${OUTDIR}" \
    "${WORKFLOW}" \
    "${CONFIG_DIR}/${config}"
done
