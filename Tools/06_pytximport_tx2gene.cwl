#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "create transcript-to-gene mapping file"
doc: "create transcript-to-gene mapping file using pytximport create map command"

baseCommand: [pytximport, create-map]

arguments:
  - --input_file
  - $(inputs.annotation_gtf_file)
  - --output_file
  - $(inputs.tx2gene_file_name)
  - --source_field
  - $(inputs.source_field)
  - --target_field
  - $(inputs.target_field)
#   - --keep_biotype # this option is deprecated in pytximport 0.12.0

inputs:
  - id: annotation_gtf_file
    type: File
    label: "annotation gtf file"
    doc: "annotation gtf file"
    format: edam:format_2305 # GFF format (including GTF, GFF3, etc.)
    default:
      class: File
      format: edam:format_2305
      location: ../Data/Database/GENCODE_v49/gencode.v49.chr_patch_hapl_scaff.annotation.gtf

  - id: tx2gene_file_name
    type: string
    label: "tx2gene file name"
    doc: "tx2gene file name"
    default: "gencode_v49_tx2gene_chr_patch_hapl_scaff_v260721.tsv"

  - id: source_field
    type: string
    label: "source field"
    doc: "source field"
    default: "transcript_id"

  - id: target_field
    type: string
    label: "target field"
    doc: "target field"
    default: "gene_id"

outputs:
  - id: tx2gene_file
    type: File
    label: "tx2gene file"
    doc: "tx2gene file"
    outputBinding:
      glob: $(inputs.tx2gene_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/pytximport:0.13.0--pyhdfd78af_0

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/