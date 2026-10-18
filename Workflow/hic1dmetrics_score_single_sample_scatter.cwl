#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter HiC1Dmetrics one-sample score over chromosomes"
doc: |
  Run Tools/hic1dmetrics_process/hic1dmetrics_score_single_sample.cwl once per
  chromosome for one dumped dense matrix sample.

  Scatter matrix and chromosome together (scatterMethod: dotproduct). The two
  arrays must be the same length and the same chromosome order. score_script,
  resolution, metric, and parameter are shared across jobs.

  Default chromosomes are chr1-22 and chrX. chrY and chrM are omitted because
  h1d dump skips them. Default matrices are GSE105028 Hi-C Ctrl KR dumps at
  5000 bp.

  Each job writes:
    $(matrix.nameroot).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score_single_sample.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/onesample.html#calculate-1d-metrics-for-one-sample

  Example:
    cwltool --outdir ./out/h1d/GSE105028_hic/score_single/IS/ \
      ./Workflow/hic1dmetrics_score_single_sample_scatter.cwl

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: matrices
    type: File[]
    label: "contact matrices"
    doc: "Dumped dense matrices, one file per scattered chromosome"
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
    doc: "Chromosome names, one score job per name; same order as matrices"
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
    label: "hic1dmetrics one-sample score script"
    doc: "Python wrapper around h1d multiScore.obtainOneScore; shared across jobs"
    default:
      class: File
      location: ../scripts/hic1dmetrics_score_single_sample.py

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must match the dumped matrices; shared across jobs"
    default: 5000

  - id: metric
    type:
      type: enum
      symbols: [IS, CI, DI, SS, DLR, PC1, IES, IAS]
    label: "one-sample metric"
    doc: "h1d one-sample metric shared across chromosome jobs"
    default: IS

  - id: parameter
    type: string
    label: "metric parameter"
    doc: |
      Metric-specific parameter passed to --parameter. Window in bp for
      IS/CI/SS/IAS/IES (300000), DI (1000000), and DLR (3000000). For PC1,
      a gene-density file path (sign is arbitrary if not a real file).
    default: "300000"

steps:
  - id: score_one_sample
    run: ../Tools/hic1dmetrics_process/hic1dmetrics_score_single_sample.cwl
    scatter: [matrix, chromosome]
    scatterMethod: dotproduct
    in:
      score_script: score_script
      matrix: matrices
      chromosome: chromosomes
      resolution: resolution
      metric: metric
      parameter: parameter
    out: [bedgraph_file]

outputs:
  - id: bedgraph_files
    type: File[]
    label: "one-sample metric bedGraphs"
    doc: "One chromosome bedGraph per scattered matrix/chromosome pair"
    format: edam:format_3583
    outputSource: score_one_sample/bedgraph_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
