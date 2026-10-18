#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "salmon index for GENCODE (v49) transcripts fasta file and decoy fasta file "
doc: |
  "Creates a salmon index for GENCODE v49 transcripts fasta file and decoy fasta file.
  see documentation: https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/
  see documentation: https://salmon.readthedocs.io/en/latest/salmon.html

  step1: create a merged fasta file with lncRNA transcripts and decoy genome fasta file
    grep "^>" <(gunzip -c GRCh38.p14.genome.fa.gz) | cut -d " " -f 1 > decoys.txt
  
  step2:
    sed -i.bak -e 's/>//g' decoys.txt

  step3: 
    cat ./gencode.v49.transcripts.fa.gz ./GRCh38.p14.genome.fa.gz > gencode.v49.transcripts.decoy.fa.gz"

baseCommand: [salmon, index]

arguments:
  - --transcripts
  - $(inputs.gencode_transcripts_file)
  - --index
  - $(inputs.index_name)
  - --kmerLen
  - $(inputs.kmer_length)
  # - --keepDuplicates
  - --threads
  - $(inputs.threads)
  - --decoys
  - $(inputs.decoy_file)
  - --gencode

inputs:
  - id: gencode_transcripts_file
    type: File
    label: "GENCODE v49 transcripts fasta file"
    doc: "GENCODE v49 transcripts fasta file (e.g. gencode.v49.transcripts.fa.gz)"
    format: edam:format_1929 # FASTA format
    default:
      class: File
      format: edam:format_1929 # FASTA format
      location: ../Data/GENCODE_v49/gencode.v49.transcripts.decoy.fa.gz

  - id: index_name
    type: string
    label: "Index name"
    default: "index_gencode_v49_decoy"

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
    doc: "A text file containing the names of the decoy sequences (from the --transcripts FASTA), one name per line (e.g. decoys.txt)."
    default:
      class: File
      location: ../Data/GENCODE_v49/decoys.txt

outputs:
  - id: salmon_index_directory
    type: Directory
    label: "Salmon index directory"
    doc: "Salmon index directory (e.g. index_gencode_v49_decoy)"
    outputBinding:
      glob: $(inputs.index_name)

# stdout: $(inputs.index_name)_stdout_run_salmon_index.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/salmon:1.10.3--h45fbf2d_4

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/