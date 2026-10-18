#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "score one Hi-C chromosome with HiC1Dmetrics"
doc: |
  Calculate one one-sample 1D metric from a dumped dense matrix by calling
  scripts/hic1dmetrics_score_single_sample.py (h1d multiScore.obtainOneScore,
  datatype=matrix). One job handles one sample, one chromosome, and one metric
  so a workflow can scatter later. IF is omitted because it requires raw .hic,
  not dumped matrices.

  --tad-file is not exposed here (no JavaScript optional flags). IAS/IES use
  the built-in TAD caller.

  The output file name is composed from parameter references only
  (no InlineJavascriptRequirement):
    $(matrix.nameroot).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score_single_sample.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/onesample.html#calculate-1d-metrics-for-one-sample

baseCommand: [python3]

arguments:
  - $(inputs.score_script)
  - --matrix
  - $(inputs.matrix)
  - --chromosome
  - $(inputs.chromosome)
  - --resolution
  - $(inputs.resolution)
  - --metric
  - $(inputs.metric)
  - --parameter
  - $(inputs.parameter)
  - --output-bedgraph-file
  - $(inputs.matrix.nameroot).$(inputs.metric).bedGraph

inputs:
  - id: score_script
    type: File
    label: "hic1dmetrics one-sample score script"
    doc: "Python wrapper around h1d multiScore.obtainOneScore (datatype=matrix)"
    default:
      class: File
      location: ../../scripts/hic1dmetrics_score_single_sample.py

  - id: matrix
    type: File
    label: "contact matrix"
    doc: "Dumped dense matrix .matrix.gz for one sample and one chromosome"
    default:
      class: File
      location: ../../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr21.5000.matrix.gz

  - id: chromosome
    type: string
    label: "chromosome"
    doc: "Chromosome name matching the dumped matrix, e.g. chr21"
    default: "chr21"

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must match the dumped matrix"
    default: 5000

  - id: metric
    type:
      type: enum
      symbols: [IS, CI, DI, SS, DLR, PC1, IES, IAS]
    label: "one-sample metric"
    doc: "h1d one-sample metric. Change parameter when switching metric (see parameter doc)"
    default: IS

  - id: parameter
    type: string
    label: "metric parameter"
    doc: |
      Metric-specific parameter passed to --parameter. Window in bp for
      IS/CI/SS/IAS/IES (300000), DI (1000000), and DLR (3000000). For PC1,
      a gene-density file path (sign is arbitrary if not a real file).
    default: "300000"

outputs:
  - id: bedgraph_file
    type: File
    label: "one-sample metric bedGraph"
    doc: "Four-column chromosome bedGraph (chr, start, end, score) with no header"
    format: edam:format_3583
    streamable: true
    outputBinding:
      glob: $(inputs.matrix.nameroot).$(inputs.metric).bedGraph

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
