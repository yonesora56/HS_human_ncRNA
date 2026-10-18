#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "CrossMap bed for FANTOM-CAT (hg19 to hg38)"
doc: |
  Lift BED12 transcript coordinates from hg19 to hg38 with CrossMap bed.
  BED12 exon blocks are converted together; if any exon fails, the whole
  transcript is written to the unmapped file.

  Do not enable --naive-bed-parsing. That option lifts only chrom/start/end
  and would drop exon structure needed for later bed2gtf and gffcompare.

  help:
    docker run --rm quay.io/biocontainers/crossmap:0.7.4--pyhdfd78af_0 CrossMap bed --help
  documentation:
    https://crossmap.readthedocs.io/en/latest/
  chain file:
    https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz

baseCommand: [CrossMap, bed]

arguments:
  - --chromid
  - $(inputs.chromosome_id)
  - --unmap-file
  - $(inputs.unmap_bed_file_name)
  - $(inputs.chain_file)
  - $(inputs.input_bed_file)
  - $(inputs.output_bed_file_name)

inputs:
  - id: chain_file
    type: File
    label: "UCSC chain file"
    doc: "Pairwise alignment chain from source to target assembly (hg19ToHg38.over.chain.gz). download from https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz"
    default:
      class: File
      location: ../../Data/Database/UCSC/hg19ToHg38.over.chain.gz

  - id: input_bed_file
    type: File
    label: "Input BED file (hg19)"
    doc: "BED12 file to lift over (e.g. FANTOM_CAT.lv4_stringent.bed)"
    format: edam:format_3003
    default:
      class: File
      format: edam:format_3003
      location: ../../Data/Database/FANTOM/FANTOM-CAT/FANTOM_CAT.lv4_stringent.bed

  - id: chromosome_id
    type:
      type: enum
      symbols:
        - a
        - s
        - l
        - n
    label: "Output chromosome ID style"
    doc: |
      CrossMap --chromid. a = as-is, l = chr prefix, s = no chr prefix,
      n = no change. Use a when both FANTOM-CAT and GENCODE use chr1-style names.
    default: a

  - id: output_bed_file_name
    type: string
    label: "Mapped BED file name"
    doc: "Output BED file name for successfully lifted intervals"
    default: "FANTOM_CAT.lv4_stringent.hg38.bed"

  - id: unmap_bed_file_name
    type: string
    label: "Unmapped BED file name"
    doc: "Output BED file name for intervals that could not be lifted uniquely"
    default: "FANTOM_CAT.lv4_stringent.hg38.unmap.bed"

outputs:
  - id: output_bed_file
    type: File
    label: "Mapped BED file (hg38)"
    doc: "BED12 intervals successfully lifted to hg38"
    format: edam:format_3003
    streamable: true
    outputBinding:
      glob: $(inputs.output_bed_file_name)

  - id: unmap_bed_file
    type: File
    label: "Unmapped BED file"
    doc: "Intervals that failed or could not be uniquely converted"
    format: edam:format_3003
    streamable: true
    outputBinding:
      glob: $(inputs.unmap_bed_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/crossmap:0.7.4--pyhdfd78af_0

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
