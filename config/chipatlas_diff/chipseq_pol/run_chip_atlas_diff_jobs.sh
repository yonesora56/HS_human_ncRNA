#!/usr/bin/env bash
# Run ChIP-Atlas Diff Analysis for chipseq_pol pair1–27 (one job at a time).
#
# Usage (from repository root):
#   bash config/chipatlas_diff/chipseq_pol/run_chip_atlas_diff_jobs.sh
#
# Each pair writes to:
#   ./out/ChIP-Atlas_diff/ChIPseq_polII/result/<config_yaml_stem>/
#
# Failed pair stems are appended to:
#   ./out/ChIP-Atlas_diff/ChIPseq_polII/result/failed_pairs.txt
#
# See notebooks/00_metadata/12_8_metadata_chipseq.ipynb
# Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically

set -uo pipefail

RESULT_ROOT="./out/ChIP-Atlas_diff/ChIPseq_polII/result"
FAILED_LOG="./out/ChIP-Atlas_diff/ChIPseq_polII/result/failed_pairs.txt"
mkdir -p "${RESULT_ROOT}"
: > "${FAILED_LOG}"

# Run one pair; on failure, record stem and continue.
run_pair() {
  local stem="$1"
  local cfg="$2"
  local outdir="${RESULT_ROOT}/${stem}"
  echo "=== START ${stem} $(date -Iseconds) ==="
  mkdir -p "${outdir}"
  if cwltool --cachedir ./tmp/ --outdir "${outdir}" \
    ./Workflow/chip_atlas_diff_job.cwl \
    "${cfg}"; then
    echo "=== OK ${stem} $(date -Iseconds) ==="
  else
    echo "${stem}" >> "${FAILED_LOG}"
    echo "=== FAIL ${stem} $(date -Iseconds) ===" >&2
  fi
}

# --- pair1: pair1_GSE140053_pol2_hs_43C_30min_sictrl ---
run_pair "pair1_GSE140053_pol2_hs_43C_30min_sictrl" "./config/chipatlas_diff/chipseq_pol/job/pair1_GSE140053_pol2_hs_43C_30min_sictrl.yml"

# --- pair2: pair2_GSE140053_pol2_hs_43C_30min_siUBC9 ---
run_pair "pair2_GSE140053_pol2_hs_43C_30min_siUBC9" "./config/chipatlas_diff/chipseq_pol/job/pair2_GSE140053_pol2_hs_43C_30min_siUBC9.yml"

# --- pair3: pair3_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff1aid_dld ---
run_pair "pair3_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff1aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair3_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff1aid_dld.yml"

# --- pair4: pair4_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff4aid_dld ---
run_pair "pair4_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff4aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair4_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_aff4aid_dld.yml"

# --- pair5: pair5_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd2aid_dld ---
run_pair "pair5_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd2aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair5_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd2aid_dld.yml"

# --- pair6: pair6_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd3aid_dld ---
run_pair "pair6_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd3aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair6_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd3aid_dld.yml"

# --- pair7: pair7_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd4aid_dld ---
run_pair "pair7_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd4aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair7_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_brd4aid_dld.yml"

# --- pair8: pair8_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_doubleaid_dld ---
run_pair "pair8_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_doubleaid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair8_GSE145525_pol2_hs_42C_60min_2haux_pol2cst_doubleaid_dld.yml"

# --- pair9: pair9_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff1aid_dld ---
run_pair "pair9_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff1aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair9_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff1aid_dld.yml"

# --- pair10: pair10_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff4aid_dld ---
run_pair "pair10_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff4aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair10_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_aff4aid_dld.yml"

# --- pair11: pair11_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd2aid_dld ---
run_pair "pair11_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd2aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair11_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd2aid_dld.yml"

# --- pair12: pair12_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd3aid_dld ---
run_pair "pair12_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd3aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair12_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd3aid_dld.yml"

# --- pair13: pair13_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd4aid_dld ---
run_pair "pair13_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd4aid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair13_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_brd4aid_dld.yml"

# --- pair14: pair14_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_doubleaid_dld ---
run_pair "pair14_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_doubleaid_dld" "./config/chipatlas_diff/chipseq_pol/job/pair14_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_doubleaid_dld.yml"

# --- pair15: pair15_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_wt_dld ---
run_pair "pair15_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_wt_dld" "./config/chipatlas_diff/chipseq_pol/job/pair15_GSE145525_pol2_hs_42C_60min_2hh2o_pol2cst_wt_dld.yml"

# --- pair16: pair16_GSE66448_pol2_hs_43C_30min_vcap ---
run_pair "pair16_GSE66448_pol2_hs_43C_30min_vcap" "./config/chipatlas_diff/chipseq_pol/job/pair16_GSE66448_pol2_hs_43C_30min_vcap.yml"

# --- pair17: pair17_GSE66448_pol2_hs_43C_30min_vcap_re ---
run_pair "pair17_GSE66448_pol2_hs_43C_30min_vcap_re" "./config/chipatlas_diff/chipseq_pol/job/pair17_GSE66448_pol2_hs_43C_30min_vcap_re.yml"

# --- pair18: pair18_GSE66448_pol2_hs_43C_30min_vcap_siube2i ---
run_pair "pair18_GSE66448_pol2_hs_43C_30min_vcap_siube2i" "./config/chipatlas_diff/chipseq_pol/job/pair18_GSE66448_pol2_hs_43C_30min_vcap_siube2i.yml"

# --- pair19: pair19_GSE112379_pol2_hs_43C_90min_hek_rpb1_chx ---
run_pair "pair19_GSE112379_pol2_hs_43C_90min_hek_rpb1_chx" "./config/chipatlas_diff/chipseq_pol/job/pair19_GSE112379_pol2_hs_43C_90min_hek_rpb1_chx.yml"

# --- pair20: pair20_GSE112379_pol2_hs_43C_90min_hek_rpb1_scramble ---
run_pair "pair20_GSE112379_pol2_hs_43C_90min_hek_rpb1_scramble" "./config/chipatlas_diff/chipseq_pol/job/pair20_GSE112379_pol2_hs_43C_90min_hek_rpb1_scramble.yml"

# --- pair21: pair21_GSE112379_pol2_hs_43C_90min_hek_rpb1_sinelfe ---
run_pair "pair21_GSE112379_pol2_hs_43C_90min_hek_rpb1_sinelfe" "./config/chipatlas_diff/chipseq_pol/job/pair21_GSE112379_pol2_hs_43C_90min_hek_rpb1_sinelfe.yml"

# --- pair22: pair22_GSE112379_pol2_hs_43C_90min_hek_rpb1_ub-e1 ---
run_pair "pair22_GSE112379_pol2_hs_43C_90min_hek_rpb1_ub-e1" "./config/chipatlas_diff/chipseq_pol/job/pair22_GSE112379_pol2_hs_43C_90min_hek_rpb1_ub-e1.yml"

# --- pair23: pair23_GSE112379_pol2_hs_43C_90min_hek_rpb1_vehicle ---
run_pair "pair23_GSE112379_pol2_hs_43C_90min_hek_rpb1_vehicle" "./config/chipatlas_diff/chipseq_pol/job/pair23_GSE112379_pol2_hs_43C_90min_hek_rpb1_vehicle.yml"

# --- pair24: pair24_GSE112379_pol2_hs_43C_30min_k562_rpb1 ---
run_pair "pair24_GSE112379_pol2_hs_43C_30min_k562_rpb1" "./config/chipatlas_diff/chipseq_pol/job/pair24_GSE112379_pol2_hs_43C_30min_k562_rpb1.yml"

# --- pair25: pair25_GSE209667_pol2_hs_42C_60min_mcf7 ---
run_pair "pair25_GSE209667_pol2_hs_42C_60min_mcf7" "./config/chipatlas_diff/chipseq_pol/job/pair25_GSE209667_pol2_hs_42C_60min_mcf7.yml"

# --- pair26: pair26_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shfubp3 ---
run_pair "pair26_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shfubp3" "./config/chipatlas_diff/chipseq_pol/job/pair26_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shfubp3.yml"

# --- pair27: pair27_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shscr ---
run_pair "pair27_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shscr" "./config/chipatlas_diff/chipseq_pol/job/pair27_GSE259305_pol2_hs_42C_120min_ser2p_dld1_shscr.yml"

echo
if [[ -s "${FAILED_LOG}" ]]; then
  echo "Finished with failures. Failed pairs written to: ${FAILED_LOG}"
  echo "---- failed pairs ----"
  cat "${FAILED_LOG}"
  exit 1
else
  echo "All chipseq_pol Diff Analysis jobs finished successfully."
  rm -f "${FAILED_LOG}"
fi
