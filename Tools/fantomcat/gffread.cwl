#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "gffread for FANTOM-CAT lncRNA transcripts fasta file"
doc: |
  gffread process for creating reference FANTOM-CAT lncRNA transcripts fasta file from GTF file.
  Examples of execution commands can also be found in the following papers.
  DOI: 10.26508/lsa.202201518
  1. Download the GTF file from the FANTOM-CAT website
  command: curl -O https://fantom.gsc.riken.jp/5/suppl/Hon_et_al_2016/data/assembly/lv4_stringent/FANTOM_CAT.lv4_stringent.gtf.gz
  2. Unzip the file
  command: pigz -d FANTOM_CAT.lv4_stringent.gtf.gz
  3. Download the genome fasta file from UCSC genome browser
  command: curl -O https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz 
  4. Unzip the genome fasta file
  command: pigz -d hg19.fa.gz
  5. Run gffread
  command: gffread FANTOM_CAT.lv4_stringent.gtf -g hg19.fa -w lncRNA_transcripts_stringent_lv4_full.fasta

baseCommand: [gffread]
arguments:
  - $(inputs.gtf_file)
  - -g
  - $(inputs.genome_fasta_file)
  - -w
  - $(inputs.output_fasta_file_name)


inputs:
  - id: gtf_file
    type: File
    label: "FANTOM-CAT lncRNA transcripts GTF file"
    doc: "FANTOM-CAT lncRNA transcripts GTF file (e.g. FANTOM_CAT.lv4_stringent.gtf)"
    format: edam:format_2305 # GFF format (including GTF, GFF3, etc.)
    default:
      class: File
      format: edam:format_2305 # GFF format (including GTF, GFF3, etc.)
      location: ../fantom_cat_data/FANTOM_CAT.lv4_stringent.gtf


  - id: genome_fasta_file
    type: File
    label: "Genome fasta file"
    doc: "Genome fasta file (e.g. hg19.fa)"
    format: edam:format_1929 # FASTA format
    default:
      class: File
      format: edam:format_1929 # FASTA format
      location: ../fantom_cat_data/hg19.fa


  - id: output_fasta_file_name
    type: string
    label: "Output fasta file name"
    doc: "Output fasta file name (e.g. lncRNA_transcripts_stringent_lv4_full.fasta)"
    default: "lncRNA_transcripts_stringent_lv4_full.fasta"


outputs:
  - id: output_fasta_file
    type: File
    label: "Output fasta file"
    doc: "Output fasta file (e.g. lncRNA_transcripts_stringent_lv4_full.fasta)"
    outputBinding:
      glob: $(inputs.output_fasta_file_name)



hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/gffread:0.12.7--h077b44d_6

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/






