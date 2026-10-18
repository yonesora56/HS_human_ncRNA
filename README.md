[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=python3.13&color=blue&logo=docker)](https://github.com/yonesora56/HS_human_ncRNA/tree/main/.devcontainer)
[![Last commit](https://img.shields.io/github/last-commit/yonesora56/HS_human_ncRNA)](https://github.com/yonesora56/HS_human_ncRNA/commits/main)
[![Repo size](https://img.shields.io/github/repo-size/yonesora56/HS_human_ncRNA)](https://github.com/yonesora56/HS_human_ncRNA)
[![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![R](https://img.shields.io/badge/R-4.5.0-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?logo=jupyter&logoColor=white)](https://jupyter.org/)
[![CWL](https://img.shields.io/badge/CWL-v1.2-%23B5314C?logo=commonworkflowlanguage&logoColor=white)](https://www.commonwl.org/)

&nbsp;

# HS human ncRNA Code Repository

## Included Files

- `notebooks/`, `scripts/`, `Tools/`, `Workflow/`, `config/`
- `Data/document`, `Data/curation`, `Data/GEOfinder`, `Data/qrcode`, `Data/README.md`
- `Data/metadata/`, except `metadata_geofetch` and `metadata_atacseq`
- `out/figshare`, `out/metascape`, `out/transcript_survey`, `out/GENCODE_FANTOMCAT_comparison`, `out/simona`, `out/test`
- `.devcontainer/` (Development Container)



## Data kept outside the repository

The following directories stay on the local machine and are excluded from Git. GitHub's per-file limit is 100 MB, so these contents cannot be uploaded as they are.

Input data (`Data/`, about 86 GB in total):

- `Data/proteomics/` about 33 GB
- `Data/Database/` about 31 GB (GENCODE, FANTOM, and others)
- `Data/HNscore/` about 19 GB
- `Data/quantification/` about 3.2 GB
- `Data/metadata/metadata_geofetch/` about 1.3 GB
- `Data/metadata/metadata_atacseq/` about 306 MB

Analysis outputs (`out/`, about 267 GB in total):

- `out/salmon_gencode_result/` about 167 GB
- `out/ENCODE_rE2G/` about 64 GB
- `out/fantabio/` about 17 GB
- `out/transcript_classification/` about 14 GB
- `out/proseq_test/` about 4.2 GB
- `out/HiC/` about 2.7 GB
- `out/ChIP-Atlas_diff/` about 1.2 GB
- `out/fastp_result/` about 323 MB
- `out/ChIP-Atlas_enrichment/` about 135 MB

Archives and indexes are also excluded from Git.

- `Archive/` about 70 GB
- `index/` about 4.2 GB

After cloning, place the large contents above at the same paths before rerunning notebooks and workflows. The excluded paths are listed in [.gitignore](.gitignore).
