#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "Quantification of transcript abundance using Salmon v1.10.3 (Single-end reads)"
doc: |
  Quantifies transcript abundance using Salmon v1.10.3 for a given GENCODE transcripts fasta file and a set of single-end RNA-seq reads.
  modified from https://github.com/pitagora-network/pitagora-cwl/blob/master/tools/salmon/quant/single_end/salmon_quant_se.cwl


requirements:
  InlineJavascriptRequirement: {}

baseCommand: [salmon, quant]

arguments:
  - --index
  - $(inputs.salmon_index)
  - --libType
  - $(inputs.library_type)
  - --unmatedReads
  - $(inputs.single_end_trimmed_read)
  - --output
  - $(inputs.single_end_trimmed_read.nameroot.replace('_trim.fq', ''))
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
  # - --gencode


inputs:
  - id: salmon_index
    type: Directory
    label: "Salmon index (GENCODE v49 transcripts)"
    doc: "Salmon index (GENCODE v49 transcripts) including GRCh38.p14 decoy sequences"
    default:
      class: Directory
      location: ../index/index_gencode_v49_decoy

  - id: library_type
    type: string
    label: "Library type"
    doc: "Library type (default: A; Automatically)"
    default: "A"

  - id: single_end_trimmed_read
    type: File
    label: "Single-end trimmed reads"
    doc: "Single-end trimmed reads"
    format: edam:format_1930 # FASTQ format
    default:
      class: File
      format: edam:format_1930 # FASTQ format
      location: ../HS_human_trimming_fastq/single-end/SRR27681984_trim.fq.gz

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
      glob: $(inputs.single_end_trimmed_read.nameroot.replace('_trim.fq', ''))

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/salmon:1.10.3--h45fbf2d_4

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/