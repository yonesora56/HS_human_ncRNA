#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "convert GTF to BED"
doc: |
  Convert GTF to BED using BEDOPS convert2bed.
  help: docker run --rm quay.io/biocontainers/bedops:2.4.42--hd6d6fdc_1 convert2bed --help-gtf
  More details: https://bedops.readthedocs.io/en/latest/

baseCommand: [convert2bed]

arguments:
  - --input=gtf
  - "--attribute-key=$(inputs.attribute_key)"
  - "--max-mem=$(inputs.max_mem)"

stdin:
  $(inputs.gtf_file.path)

stdout: $(inputs.output_bed_file_name)

inputs:
  - id: gtf_file
    type: File
    label: "GTF file"
    doc: "Input GTF file (e.g. GENCODE annotation GTF)"
    format: edam:format_2305
    default:
      class: File
      format: edam:format_2305
      location: ../Data/Database/GENCODE_v49/gencode.v49.chr_patch_hapl_scaff.annotation.gtf

  - id: attribute_key
    type: string
    label: "Attribute key for BED ID column"
    doc: |
      GTF attribute copied to the 4th BED column (ID field).
      Valid values: gene_id, gene_name, gene_type, transcript_id, transcript_name, exon_id, havana_gene, havana_transcript
    default: "transcript_id"

  - id: max_mem
    type: string
    label: "Memory for sort-bed"
    doc: |
      Memory reserved for sorting BED output (sort-bed).
      Examples: 8G, 8000M, 8000000000. Default of convert2bed is 2G.
    default: "128G"

  - id: output_bed_file_name
    type: string
    label: "Output BED file name"
    doc: "Output BED file name"
    default: "gencode.v49.annotation_transcript_id.bed"

outputs:
  - id: output_bed_file
    type: File
    label: "Output BED file"
    doc: "Output BED file converted from GTF"
    format: edam:format_3003
    outputBinding:
      glob: $(inputs.output_bed_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bedops:2.4.42--hd6d6fdc_1

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
