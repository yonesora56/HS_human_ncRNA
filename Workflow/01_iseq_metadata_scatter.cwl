#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "iseq_metadata_scatter"
doc: "Parse an accession list file and run `iseq --metadata` for each accession in parallel via scatter."

requirements:
  ScatterFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  NetworkAccess:
    networkAccess: true

inputs:
  - id: accession_list
    type: File
    label: "accession_list"
    doc: "text file containing one accession number per line"
    default:
      class: File
      location: ../out/fantabio/ChIP-atlas_enrichment_result_lncRNA_ela_202604/up5p_lncRNA_ela_atacseq_enrichment_list_bioproject.txt

steps:
  # Step 1: parse the accession list file into a string array (File -> string[])
  # Use the CommandLineTool variant to avoid the 64 KiB loadContents limit that
  # applies to the ExpressionTool variant (parse_accession_list.cwl).
  - id: parse_list
    run: ../Tools/parse_accession_list_cmd.cwl
    in:
      accession_list: accession_list
    out: [accessions]

  # Step 2: run iseq --metadata for each accession in parallel
  - id: retrieve_metadata
    run: ../Tools/01_iseq_zatsu_metadata.cwl
    scatter: [accession]
    scatterMethod: dotproduct
    in:
      accession: parse_list/accessions
    out: [all-for-debugging]

outputs:
  # Output is a nested array because each scatter instance itself emits an array
  - id: metadata_files
    type:
      type: array
      items:
        type: array
        items: [File, Directory]
    label: "metadata_files"
    doc: "metadata files (and directories) collected per accession"
    outputSource: retrieve_metadata/all-for-debugging


$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/
