#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "salmon index for FANTOM-CAT lncRNA transcripts fasta file "
doc: "Creates a salmon index for FANTOM-CAT lncRNA transcripts fasta file."

baseCommand: [salmon, index]

arguments:
  - --transcripts
  - $(inputs.transcripts_file)
  - --index
  - $(inputs.index_name)
  - --kmerLen
  - $(inputs.kmer_length)
  - --threads
  - $(inputs.threads)
  # - --keepDuplicates

inputs:
  - id: transcripts_file
    type: File
    label: "FANTOM-CAT lncRNA transcripts fasta file"
    doc: "FANTOM-CAT lncRNA transcripts fasta file (e.g. lncRNA_transcripts_stringent_lv4_full.fasta)"
    format: edam:format_1929 # FASTA format
    default:
      class: File
      format: edam:format_1929 # FASTA format
      location: ../fantom_cat_data/lncRNA_transcripts_stringent_lv4_full.fasta

  - id: index_name
    type: string
    label: "Index name"
    default: "index_fantomcat_stringent_lv4_full"

  - id: kmer_length
    type: int
    label: "Kmer length"
    doc: "The size of k-mers that should be used for the quasi-index."
    default: 31

  - id: threads
    type: int
    label: "Threads"
    doc: "Number of threads to use during indexing."
    default: 16

outputs:
  - id: salmon_index_directory
    type: Directory
    label: "Salmon index directory"
    doc: "Salmon index directory (e.g. index_fantomcat_stringent_lv4_full)"
    outputBinding:
      glob: $(inputs.index_name)

# stdout: $(inputs.index_name)_stdout_run_salmon_index.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/salmon:1.10.3--h45fbf2d_4

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/