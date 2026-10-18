#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter HiC1Dmetrics one-sample IF over chromosomes"
doc: |
  Run Tools/hic1dmetrics_process/hic1dmetrics_score_single_sample_if.cwl once
  per chromosome for one Juicer .hic sample.

  Scatter over chromosomes. hic_file, genome_table, juicer_tools, score_script,
  resolution, and fdr_threshold are shared across jobs.

  IF cannot use dumped matrices. Pass juicer_tools 2.20.00 for HIC v9.

  Default chromosomes are chr1-22 and chrX. chrY and chrM are omitted because
  h1d dump skips them. The default .hic is GSE105028 HiChIP CTCF HS (merged).

  Each job writes:
    $(hic_file.nameroot).$(chromosome).IF.bedGraph
    $(hic_file.nameroot).$(chromosome).IF.significances.txt
    $(hic_file.nameroot).$(chromosome).IF.fithic_pass1.txt
    $(hic_file.nameroot).$(chromosome).IF.log

  help:
    python3 scripts/hic1dmetrics_score_single_sample_if.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/onesample.html#calculate-1d-metrics-one-sample

  Example:
    cwltool --outdir ./out/h1d/GSE105028_hichip/score_single/HS/IF/ \
      ./Workflow/hic1dmetrics_score_single_sample_if_scatter.cwl

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: hic_file
    type: File
    label: "Juicer hic file"
    doc: "Input .hic file for one sample; shared across chromosome jobs"
    default:
      class: File
      location: ../out/hic/GSE105028_hichip_convert_hic/CTCF_HS_merged_juicer_pre_output/CTCF_HS_merged.hic

  - id: genome_table
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths for Fit-Hi-C fragment bins; shared across jobs"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../out/h1d/hg38_genome_table.txt

  - id: juicer_tools
    type: File
    label: "juicer_tools jar"
    doc: "juicer_tools jar used by dump (2.20.00 for HIC v9); shared across jobs"
    default:
      class: File
      location: ../out/h1d/juicer_tools.2.20.00.jar

  - id: score_script
    type: File
    label: "hic1dmetrics IF score script"
    doc: "Python wrapper around juicer dump + Fit-Hi-C; shared across jobs"
    default:
      class: File
      location: ../scripts/hic1dmetrics_score_single_sample_if.py

  - id: chromosomes
    type: string[]
    label: "chromosomes"
    doc: "Chromosome names matching the genome table, one IF job per name"
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
    doc: "Bin size in bp; must exist in the .hic file; shared across jobs"
    default: 5000

  - id: fdr_threshold
    type: float
    label: "Fit-Hi-C FDR threshold"
    doc: "q-value cutoff for significant interactions; shared across jobs"
    default: 0.05

steps:
  - id: score_one_sample_if
    run: ../Tools/hic1dmetrics_process/hic1dmetrics_score_single_sample_if.cwl
    scatter: [chromosome]
    scatterMethod: dotproduct
    in:
      score_script: score_script
      hic_file: hic_file
      genome_table: genome_table
      juicer_tools: juicer_tools
      chromosome: chromosomes
      resolution: resolution
      fdr_threshold: fdr_threshold
    out:
      - bedgraph_file
      - significances_file
      - fithic_pass1_file
      - fithic_log_file

outputs:
  - id: bedgraph_files
    type: File[]
    label: "IF bedGraphs"
    doc: "One chromosome IF bedGraph per scattered chromosome"
    format: edam:format_3583
    outputSource: score_one_sample_if/bedgraph_file

  - id: significances_files
    type: File[]
    label: "Fit-Hi-C significances tables"
    doc: "One uncompressed significances TSV per scattered chromosome"
    format: iana:text/tab-separated-values
    outputSource: score_one_sample_if/significances_file

  - id: fithic_pass1_files
    type: File[]
    label: "Fit-Hi-C pass-1 tables"
    doc: "One uncompressed fithic_pass1 TSV per scattered chromosome"
    format: iana:text/tab-separated-values
    outputSource: score_one_sample_if/fithic_pass1_file

  - id: fithic_log_files
    type: File[]
    label: "Fit-Hi-C stdout logs"
    doc: "One IF script / Fit-Hi-C stdout log per scattered chromosome"
    format: iana:text/plain
    outputSource: score_one_sample_if/fithic_log_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
