#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter HiC1Dmetrics two-sample score over chromosomes"
doc: |
  Run Tools/hic1dmetrics_process/hic1dmetrics_score.cwl once per chromosome
  for one treat/control pair of dumped dense matrices.

  Scatter treat_matrix, control_matrix, and chromosome together
  (scatterMethod: dotproduct). The three arrays must be the same length and
  the same chromosome order. score_script, resolution, metric, and parameter
  are shared across jobs.

  Default chromosomes are chr1-22 and chrX. chrY and chrM are omitted because
  h1d dump skips them. Default matrices are GSE105028 Hi-C HS vs Ctrl KR dumps
  at 5000 bp.

  Each job writes:
    $(treat_matrix.nameroot).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/twosample.html#calculate-1d-metrics-for-comparison-of-two-samples

  Example:
    cwltool --outdir ./out/h1d/GSE105028_hic/score/ISC/ \
      ./Workflow/hic1dmetrics_score_scatter.cwl

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: treat_matrices
    type: File[]
    label: "treat contact matrices"
    doc: "Dumped treat (e.g. HS) dense matrices, one file per scattered chromosome"
    default:
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr1.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr2.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr3.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr4.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr5.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr6.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr7.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr8.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr9.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr10.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr11.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr12.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr13.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr14.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr15.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr16.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr17.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr18.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr19.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr20.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr21.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr22.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chrX.5000.matrix.gz

  - id: control_matrices
    type: File[]
    label: "control contact matrices"
    doc: "Dumped control dense matrices, same chromosome order as treat_matrices"
    default:
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr1.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr2.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr3.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr4.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr5.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr6.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr7.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr8.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr9.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr10.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr11.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr12.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr13.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr14.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr15.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr16.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr17.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr18.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr19.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr20.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr21.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr22.5000.matrix.gz
      - class: File
        location: ../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chrX.5000.matrix.gz

  - id: chromosomes
    type: string[]
    label: "chromosomes"
    doc: "Chromosome names, one score job per name; same order as the matrix arrays"
    default:
      - chr1
      - chr2
      - chr3
      - chr4
      - chr5
      - chr6
      - chr7
      - chr8
      - chr9
      - chr10
      - chr11
      - chr12
      - chr13
      - chr14
      - chr15
      - chr16
      - chr17
      - chr18
      - chr19
      - chr20
      - chr21
      - chr22
      - chrX

  - id: score_script
    type: File
    label: "hic1dmetrics score script"
    doc: "Python wrapper around h1d multiScore.obtainTwoScore; shared across jobs"
    default:
      class: File
      location: ../scripts/hic1dmetrics_score.py

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must match the dumped matrices; shared across jobs"
    default: 5000

  - id: metric
    type:
      type: enum
      symbols: [ISC, CIC, SSC, deltaDLR, CD, IESC, IASC, DRF]
    label: "two-sample metric"
    doc: "h1d two-sample metric shared across chromosome jobs"
    default: ISC

  - id: parameter
    type: string
    label: "metric parameter"
    doc: |
      Metric-specific parameter passed to --parameter. Window in bp for
      ISC/CIC/SSC/IASC/IESC (300000) and deltaDLR (3000000); correlation
      method for CD (pearson); start,end for DRF (200000,5000000).
    default: "300000"

steps:
  - id: score_two_sample
    run: ../Tools/hic1dmetrics_process/hic1dmetrics_score.cwl
    scatter: [treat_matrix, control_matrix, chromosome]
    scatterMethod: dotproduct
    in:
      score_script: score_script
      treat_matrix: treat_matrices
      control_matrix: control_matrices
      chromosome: chromosomes
      resolution: resolution
      metric: metric
      parameter: parameter
    out: [bedgraph_file]

outputs:
  - id: bedgraph_files
    type: File[]
    label: "two-sample metric bedGraphs"
    doc: "One chromosome bedGraph per scattered treat/control/chromosome triple"
    format: edam:format_3583
    outputSource: score_two_sample/bedgraph_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
