#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "gffcompare for GENCODE and FANTOM-CAT lncRNA transcripts"
doc: |
  gffcompare for GENCODE and FANTOM-CAT lncRNA transcripts
  More details: https://ccb.jhu.edu/software/stringtie/gffcompare.shtml
  help:
    docker run --rm quay.io/biocontainers/gffcompare:0.12.10--h9948957_0 gffcompare --help

baseCommand: [gffcompare]

arguments:
  - -r
  - $(inputs.reference_gtf_file)
  - -o
  - $(inputs.output_prefix)
  - -p
  - $(inputs.prefix)
  - -T # do not generate .tmap and .refmap files for each input file
  - -V
  - $(inputs.compare_gtf_file)


inputs:
  - id: reference_gtf_file
    type: File
    label: "Reference GTF file"
    doc: "Reference GTF file"
    default:
      class: File
      location: ../Data/GENCODE/gencode.v49.annotation.gtf

  - id: output_prefix
    type: string
    label: "Output prefix"
    doc: "Output prefix"
    default: "gencode_vs_fantomcat_permissive"

  - id: prefix
    type: string
    label: "Prefix"
    doc: "Prefix"
    default: "gencode_vs_fantomcat_permissive"

  - id: compare_gtf_file
    type: File
    label: "Compare GTF file"
    doc: "Compare GTF file. In this case, FANTOM-CAT lncRNA transcripts (lv2_permissive.hg38.gtf from Wallece-san)"
    default:
      class: File
      location: ../Data/FANTOM-CAT_from_wallece-san/lv2_permissive.hg38.gtf

outputs:
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"


hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/gffcompare:0.12.10--h9948957_0

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/