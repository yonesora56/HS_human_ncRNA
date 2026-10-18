#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "score one Hi-C chromosome pair from raw .hic with HiC1Dmetrics"
doc: |
  Calculate one two-sample 1D metric from a pair of Juicer .hic files by
  calling scripts/hic1dmetrics_score_rawhic.py (h1d multiScore.obtainTwoScore,
  datatype=rawhic). One job handles one treat/control pair, one chromosome,
  and one metric so a workflow can scatter later. The score is treat minus
  control, as in h1d two.

  Choose the metric in the job YAML (metric / parameter). IFC requires raw
  .hic and is included here; dumped-matrix scoring omits it.

  Pass juicer_tools 2.20.00 for HIC v9. Non-IFC metrics dump KR matrices
  with that jar. Native h1d IFC still calls InteractionFreq.sh with juicer
  1.11.04 and a fixed FDR of 0.05, so --parameter is ignored for IFC.

  The output file name is composed from parameter references only
  (no InlineJavascriptRequirement):
    $(treat_hic.nameroot).$(chromosome).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score_rawhic.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/twosample.html#calculate-1d-metrics-for-comparison-of-two-samples

baseCommand: [python3]

arguments:
  - $(inputs.score_script)
  - --treat-hic
  - $(inputs.treat_hic)
  - --control-hic
  - $(inputs.control_hic)
  - --genome-table
  - $(inputs.genome_table)
  - --juicer-tools
  - $(inputs.juicer_tools)
  - --chromosome
  - $(inputs.chromosome)
  - --resolution
  - $(inputs.resolution)
  - --metric
  - $(inputs.metric)
  - --parameter
  - $(inputs.parameter)
  - --output-bedgraph-file
  - $(inputs.treat_hic.nameroot).$(inputs.chromosome).$(inputs.metric).bedGraph

inputs:
  - id: score_script
    type: File
    label: "hic1dmetrics rawhic score script"
    doc: "Python wrapper around h1d multiScore.obtainTwoScore (datatype=rawhic)"
    default:
      class: File
      location: ../../scripts/hic1dmetrics_score_rawhic.py

  - id: treat_hic
    type: File
    label: "treat Juicer hic file"
    doc: "Treat (e.g. HS) .hic file; IFC requires rawhic, not a dumped matrix"
    default:
      class: File
      location: ../../out/hic/GSE105028_hichip_convert_hic/CTCF_HS_merged_juicer_pre_output/CTCF_HS_merged.hic

  - id: control_hic
    type: File
    label: "control Juicer hic file"
    doc: "Control .hic file for the same genome build as treat_hic"
    default:
      class: File
      location: ../../out/hic/GSE105028_hichip_convert_hic/CTCF_Ctrl_merged_juicer_pre_output/CTCF_Ctrl_merged.hic

  - id: genome_table
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths for h1d --gt"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../../out/h1d/hg38_genome_table.txt

  - id: juicer_tools
    type: File
    label: "juicer_tools jar"
    doc: "juicer_tools jar used by KR dump for non-IFC metrics (2.20.00 for HIC v9)"
    default:
      class: File
      location: ../../out/h1d/juicer_tools.2.20.00.jar

  - id: chromosome
    type: string
    label: "chromosome"
    doc: "Chromosome name matching the genome table, e.g. chr21"
    default: "chr21"

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must exist in both .hic files"
    default: 5000

  - id: metric
    type:
      type: enum
      symbols: [ISC, CIC, SSC, deltaDLR, CD, IESC, IASC, DRF, IFC]
    label: "two-sample metric"
    doc: |
      h1d two-sample metric selected in the job YAML. Change parameter when
      switching metric (see parameter doc). IFC is only valid for rawhic.
    default: ISC

  - id: parameter
    type: string
    label: "metric parameter"
    doc: |
      Metric-specific parameter passed to --parameter. Window in bp for
      ISC/CIC/SSC/IASC/IESC (300000) and deltaDLR (3000000); correlation
      method for CD (pearson); start,end for DRF (200000,5000000); FDR for
      IFC in the h1d docs (0.05) but unused by this wrapper.
    default: "300000"

outputs:
  - id: bedgraph_file
    type: File
    label: "two-sample metric bedGraph"
    doc: "Four-column chromosome bedGraph (chr, start, end, score) with no header"
    format: edam:format_3583
    streamable: true
    outputBinding:
      glob: $(inputs.treat_hic.nameroot).$(inputs.chromosome).$(inputs.metric).bedGraph

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
