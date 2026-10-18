#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter HiC1Dmetrics dump over chromosomes"
doc: |
  Run Tools/hic1dmetrics_process/hic1dmetrics_dump.cwl once per chromosome
  for a single Juicer .hic sample.

  Scatter over chromosomes. hic_file, genome_table, juicer_tools, dump_script,
  resolution, and normalize are shared across jobs.

  Default chromosomes are chr1-22 and chrX. chrY and chrM are omitted because
  h1d dump skips them.

  Each job writes:
    $(hic_file.nameroot).$(normalize).$(chromosome).$(resolution).matrix.gz

  help:
    python3 scripts/hic1dmetrics_dump.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/basic.html#make-contact-matrix

  Example:
    cwltool --outdir ./out/h1d/dump/ \
      ./Workflow/hic1dmetrics_dump_scatter.cwl

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: hic_file
    type: File
    label: "Juicer hic file"
    doc: "Input .hic file for one sample; shared across chromosome jobs"
    default:
      class: File
      location: ../out/hic/GSE105028_hic_convert_hic/HiC_Ctrl_merged_juicer_pre_output/HiC_Ctrl_merged.hic

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
    doc: "juicer_tools jar used by dump (2.20.00 for HIC v9); shared across jobs"
    default:
      class: File
      location: ../out/hic/juicer_tools.2.20.00.jar

  - id: dump_script
    type: File
    label: "hic1dmetrics dump script"
    doc: "Python wrapper around h1d makeMatrixIntra.sh; shared across jobs"
    default:
      class: File
      location: ../scripts/hic1dmetrics_dump.py

  - id: chromosomes
    type: string[]
    label: "chromosomes"
    doc: "Chromosome names matching the genome table, one dump job per name"
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
    doc: "Bin size in bp; shared across chromosome jobs"
    default: 5000

  - id: normalize
    type:
      type: enum
      symbols: [NONE, VC, VC_SQRT, KR]
    label: "Juicer normalization"
    doc: "Normalization method passed to juicer_tools dump; shared across jobs"
    default: KR

steps:
  - id: dump_contact_matrix
    run: ../Tools/hic1dmetrics_process/hic1dmetrics_dump.cwl
    scatter: [chromosome]
    scatterMethod: dotproduct
    in:
      dump_script: dump_script
      hic_file: hic_file
      genome_table: genome_table
      juicer_tools: juicer_tools
      chromosome: chromosomes
      resolution: resolution
      normalize: normalize
    out: [contact_matrix_file]

outputs:
  - id: contact_matrix_files
    type: File[]
    label: "dense contact matrices"
    doc: "One gzipped intra-chromosomal dense matrix per scattered chromosome"
    outputSource: dump_contact_matrix/contact_matrix_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
