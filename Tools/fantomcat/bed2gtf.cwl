#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "bed2gtf for FANTOM-CAT BED12 (hg38)"
doc: |
  Convert BED12 transcripts to GTF with bed2gtf 2.0.0.
  This image uses --input for the BED file and --isoforms (-I) for
  the transcript-to-gene table. Isoforms are transcript_id (column 1)
  then gene_id (column 2), matching fantomcat_lv4_stringent_hg19_tx2gene.tsv.

  The CrossMap hg38 BED cannot be passed in as-is:
    - column 4 must be transcript_id only (not gene_id|transcript_id)
    - column 5 (score) must be an integer 0-1000, not a TIEScore float
    - column 9 (itemRgb) must be R,G,B; "." is rejected
  Run Tools/fantomcat/prepare_bed12_for_bed2gtf.cwl first.

  help:
    docker run --rm quay.io/biocontainers/bed2gtf:2.0.0--hd612981_0 bed2gtf --help
  documentation:
    https://github.com/alejandrogzi/bed2gtf

baseCommand: [bed2gtf]

arguments:
  - --input
  - $(inputs.input_bed_file)
  - --output
  - $(inputs.output_gtf_file_name)
  - --isoforms
  - $(inputs.isoforms_file)
  - --type
  - $(inputs.bed_type)
  - --threads
  - $(inputs.threads)

inputs:
  - id: input_bed_file
    type: File
    label: "Input BED12 file (hg38)"
    doc: "BED12 whose name column is transcript_id, with integer score and R,G,B itemRgb"
    format: edam:format_3003
    default:
      class: File
      format: edam:format_3003
      location: ../../Data/Database/FANTOM/FANTOM-CAT/FANTOM_CAT.lv4_stringent.hg38.txid.bed

  - id: isoforms_file
    type: File
    label: "Transcript-to-gene TSV"
    doc: "Two-column TSV, transcript_id then gene_id. Header row is ignored for lookup."
    default:
      class: File
      location: ../../Data/Database/FANTOM/FANTOM-CAT/fantomcat_lv4_stringent_hg19_tx2gene.tsv

  - id: bed_type
    type:
      type: enum
      symbols:
        - "3"
        - "4"
        - "5"
        - "6"
        - "8"
        - "9"
        - "12"
    label: "BED layout"
    doc: "bed2gtf --type. Use 12 to keep exon blocks for gffcompare."
    default: "12"

  - id: threads
    type: int
    label: "Worker threads"
    doc: "bed2gtf --threads. Container default is 16."
    default: 16

  - id: output_gtf_file_name
    type: string
    label: "Output GTF file name"
    doc: "Output GTF file name for gffcompare"
    default: "FANTOM_CAT.lv4_stringent.hg38.gtf"

outputs:
  - id: output_gtf_file
    type: File
    label: "Output GTF file (hg38)"
    doc: "GTF with gene, transcript, and exon records reconstructed from BED12"
    format: edam:format_2305
    streamable: true
    outputBinding:
      glob: $(inputs.output_gtf_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bed2gtf:2.0.0--hd612981_0

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
