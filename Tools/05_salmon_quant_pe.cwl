#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "Quantification of transcript abundance using Salmon v1.10.3 (Paired-end reads)"
doc: |
  Quantifies transcript abundance using Salmon v1.10.3 for a given FANTOM-CAT transcripts fasta file and a set of paired-end RNA-seq reads.
  modified from https://github.com/pitagora-network/pitagora-cwl/blob/master/tools/salmon/quant/paired_end/salmon_quant_pe.cwl


requirements:
  InlineJavascriptRequirement: {}

baseCommand: [salmon, quant]

arguments:
  - --index
  - $(inputs.salmon_index)
  - --libType
  - $(inputs.library_type)
  - --mates1
  - $(inputs.paired_end_trimmed_read1)
  - --mates2
  - $(inputs.paired_end_trimmed_read2)
  - --output
  - $(inputs.paired_end_trimmed_read1.nameroot.replace('_trim.fq', ''))
  - --seqBias
  - --gcBias # In single-end processing, it is experimentally
  - --posBias
  - --threads
  - $(inputs.threads)
  # - --validateMappings # in this version, it is deprecated
  - --numBootstraps
  - $(inputs.num_bootstraps)
  # -  --writeOrphanLinks
  - --writeUnmappedNames


inputs:
  - id: salmon_index
    type: Directory
    label: "Salmon index (FANTOM-CAT stringent transcripts)"
    doc: "Salmon index (FANTOM-CAT stringent transcripts) including hg19 decoy sequences"
    default:
      class: Directory
      location: ../index_fantomcat_stringent_lv4_full_decoy

  - id: library_type
    type: string
    label: "Library type"
    doc: "Library type (default: A; Automatically)"
    default: "A"

  - id: paired_end_trimmed_read1
    type: File
    label: "Paired-end trimmed reads (R1)"
    doc: "Paired-end trimmed reads (R1)"
    format: edam:format_1930 # FASTQ format
    default:
      class: File
      format: edam:format_1930 # FASTQ format
      location: ../HS_human_trimming_fastq/paired-end/SRR29089688_1_trim.fq.gz

  - id: paired_end_trimmed_read2
    type: File
    label: "Paired-end trimmed reads (R2)"
    doc: "Paired-end trimmed reads (R2)"
    format: edam:format_1930 # FASTQ format
    default:
      class: File
      format: edam:format_1930 # FASTQ format
      location: ../HS_human_trimming_fastq/paired-end/SRR29089688_2_trim.fq.gz

  - id: threads
    type: int
    label: "Threads"
    doc: "Number of threads to use during quantification"
    default: 16

  - id: num_bootstraps
    type: int
    label: "Number of bootstraps"
    doc: "Number of bootstraps (default: 0)"
    default: 0

outputs:
  - id: salmon_quant_output
    type: Directory
    label: "Salmon quantification output"
    doc: "Salmon quantification output"
    outputBinding:
      glob: $(inputs.paired_end_trimmed_read1.nameroot.replace('_trim.fq', ''))

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/salmon:1.10.3--h45fbf2d_4

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/