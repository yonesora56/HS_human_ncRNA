#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter HiC1Dmetrics two-sample rawhic score over chromosomes"
doc: |
  Run Tools/hic1dmetrics_process/hic1dmetrics_score_rawhic.cwl once per
  chromosome for one treat/control pair of Juicer .hic files.

  Scatter over chromosomes. treat_hic, control_hic, genome_table,
  juicer_tools, score_script, resolution, metric, and parameter are shared
  across jobs. Choose the metric in the job YAML (metric / parameter). IFC
  requires raw .hic and is included here; dumped-matrix scoring omits it.

  Pass juicer_tools 2.20.00 for HIC v9. Non-IFC metrics dump KR matrices
  with that jar. Native h1d IFC still calls InteractionFreq.sh with juicer
  1.11.04 and a fixed FDR of 0.05, so --parameter is ignored for IFC.

  Default chromosomes are chr1-22 and chrX. chrY and chrM are omitted because
  h1d dump skips them. For HiChIP CTCF, omit chromosomes whose sparse KR dump
  is empty (see the job YAML). Default .hic files are GSE105028 HiChIP CTCF
  HS vs Ctrl (merged).

  Each job writes:
    $(treat_hic.nameroot).$(chromosome).$(metric).bedGraph

  help:
    python3 scripts/hic1dmetrics_score_rawhic.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/twosample.html#calculate-1d-metrics-for-comparison-of-two-samples

  Example:
    cwltool --outdir ./out/h1d/GSE105028_hichip/score_rawhic/IFC/ \
      ./Workflow/hic1dmetrics_score_rawhic_scatter.cwl \
      ./config/hic1dmetrics/GSE105028_hichip/score/GSE105028_hichip_ctcf_score_rawhic.yml

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: treat_hic
    type: File
    label: "treat Juicer hic file"
    doc: "Treat (e.g. HS) .hic file; shared across chromosome jobs"
    default:
      class: File
      location: ../out/hic/GSE105028_hichip_convert_hic/CTCF_HS_merged_juicer_pre_output/CTCF_HS_merged.hic

  - id: control_hic
    type: File
    label: "control Juicer hic file"
    doc: "Control .hic file for the same genome build as treat_hic; shared across jobs"
    default:
      class: File
      location: ../out/hic/GSE105028_hichip_convert_hic/CTCF_Ctrl_merged_juicer_pre_output/CTCF_Ctrl_merged.hic

  - id: genome_table
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths for h1d --gt; shared across jobs"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../out/h1d/hg38_genome_table.txt

  - id: juicer_tools
    type: File
    label: "juicer_tools jar"
    doc: "juicer_tools jar used by KR dump for non-IFC metrics (2.20.00 for HIC v9)"
    default:
      class: File
      location: ../out/h1d/juicer_tools.2.20.00.jar

  - id: score_script
    type: File
    label: "hic1dmetrics rawhic score script"
    doc: "Python wrapper around h1d multiScore.obtainTwoScore (datatype=rawhic)"
    default:
      class: File
      location: ../scripts/hic1dmetrics_score_rawhic.py

  - id: chromosomes
    type: string[]
    label: "chromosomes"
    doc: "Chromosome names matching the genome table, one score job per name"
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

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must exist in both .hic files; shared across jobs"
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

steps:
  - id: score_two_sample_rawhic
    run: ../Tools/hic1dmetrics_process/hic1dmetrics_score_rawhic.cwl
    scatter: [chromosome]
    scatterMethod: dotproduct
    in:
      score_script: score_script
      treat_hic: treat_hic
      control_hic: control_hic
      genome_table: genome_table
      juicer_tools: juicer_tools
      chromosome: chromosomes
      resolution: resolution
      metric: metric
      parameter: parameter
    out: [bedgraph_file]

outputs:
  - id: bedgraph_files
    type: File[]
    label: "two-sample metric bedGraphs"
    doc: "One chromosome bedGraph per scattered chromosome"
    format: edam:format_3583
    outputSource: score_two_sample_rawhic/bedgraph_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
