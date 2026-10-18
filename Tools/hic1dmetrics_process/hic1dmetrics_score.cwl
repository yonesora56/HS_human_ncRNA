#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "score one Hi-C chromosome pair with HiC1Dmetrics"
doc: |
  Calculate one two-sample 1D metric from dumped dense matrices by calling
  scripts/hic1dmetrics_score.py (h1d multiScore.obtainTwoScore, datatype=matrix).
  One job handles one treat/control pair, one chromosome, and one metric so a
  workflow can scatter later. The score is treat minus control, as in h1d two.
  IFC is omitted because it requires raw .hic, not dumped matrices.

  The output file name is composed from parameter references only
  (no InlineJavascriptRequirement):
    $(treat_matrix.nameroot).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/twosample.html#calculate-1d-metrics-for-comparison-of-two-samples

baseCommand: [python3]

arguments:
  - $(inputs.score_script)
  - --treat-matrix
  - $(inputs.treat_matrix)
  - --control-matrix
  - $(inputs.control_matrix)
  - --chromosome
  - $(inputs.chromosome)
  - --resolution
  - $(inputs.resolution)
  - --metric
  - $(inputs.metric)
  - --parameter
  - $(inputs.parameter)
  - --output-bedgraph-file
  - $(inputs.treat_matrix.nameroot).$(inputs.metric).bedGraph

inputs:
  - id: score_script
    type: File
    label: "hic1dmetrics score script"
    doc: "Python wrapper around h1d multiScore.obtainTwoScore (datatype=matrix)"
    default:
      class: File
      location: ../../scripts/hic1dmetrics_score.py

  - id: treat_matrix
    type: File
    label: "treat contact matrix"
    doc: "Dumped treat (e.g. HS) dense matrix .matrix.gz for one chromosome"
    default:
      class: File
      location: ../../out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr21.5000.matrix.gz

  - id: control_matrix
    type: File
    label: "control contact matrix"
    doc: "Dumped control dense matrix .matrix.gz for the same chromosome"
    default:
      class: File
      location: ../../out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr21.5000.matrix.gz

  - id: chromosome
    type: string
    label: "chromosome"
    doc: "Chromosome name matching the dumped matrices, e.g. chr21"
    default: "chr21"

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must match both dumped matrices"
    default: 5000

  - id: metric
    type:
      type: enum
      symbols: [ISC, CIC, SSC, deltaDLR, CD, IESC, IASC, DRF]
    label: "two-sample metric"
    doc: "h1d two-sample metric. Change parameter when switching metric (see parameter doc)"
    default: ISC

  - id: parameter
    type: string
    label: "metric parameter"
    doc: |
      Metric-specific parameter passed to --parameter. Window in bp for
      ISC/CIC/SSC/IASC/IESC (300000) and deltaDLR (3000000); correlation
      method for CD (pearson); start,end for DRF (200000,5000000).
    default: "300000"

outputs:
  - id: bedgraph_file
    type: File
    label: "two-sample metric bedGraph"
    doc: "Four-column chromosome bedGraph (chr, start, end, score) with no header"
    format: edam:format_3583
    streamable: true
    outputBinding:
      glob: $(inputs.treat_matrix.nameroot).$(inputs.metric).bedGraph

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
