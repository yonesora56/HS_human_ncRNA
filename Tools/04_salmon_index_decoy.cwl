#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "salmon index for FANTOM-CAT lncRNA transcripts fasta file and decoy fasta file "
doc: |
  Creates a salmon index for FANTOM-CAT lncRNA transcripts fasta file and decoy fasta file.
  see documentation: https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/
  see documentation: https://salmon.readthedocs.io/en/latest/salmon.html

  step1: create a merged fasta file with lncRNA transcripts and decoy genome fasta file
    cat ./fantom_cat_data/lncRNA_transcripts_stringent_lv4_full.fasta ./fantom_cat_data/hg19.fa > lncRNA_transcripts_stringent_lv4_full_decoy.fasta

  step2: create a decoy ID list file
    grep "^>chr" ./fantom_cat_data/hg19.fa | sed 's/>//' | sort -V > decoys_hg19.txt



baseCommand: [salmon, index]

arguments:
  - --transcripts
  - $(inputs.transcripts_file)
  - --index
  - $(inputs.index_name)
  - --kmerLen
  - $(inputs.kmer_length)
  # - --keepDuplicates
  - --threads
  - $(inputs.threads)
  - --decoys
  - $(inputs.decoy_file)

inputs:
  - id: transcripts_file
    type: File
    label: "FANTOM-CAT lncRNA transcripts fasta file"
    doc: "FANTOM-CAT lncRNA transcripts fasta file (e.g. lncRNA_transcripts_stringent_lv4_full_decoy.fasta)"
    format: edam:format_1929 # FASTA format
    default:
      class: File
      format: edam:format_1929 # FASTA format
      location: ../fantom_cat_data/lncRNA_transcripts_stringent_lv4_full_decoy.fasta

  - id: index_name
    type: string
    label: "Index name"
    default: "index_fantomcat_stringent_lv4_full_decoy"

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

  - id: decoy_file
    type: File
    label: "Decoy ID list file"
    doc: "A text file containing the names of the decoy sequences (from the --transcripts FASTA), one name per line (e.g. decoys_hg19.txt)."
    default:
      class: File
      location: ../fantom_cat_data/decoys_hg19.txt

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