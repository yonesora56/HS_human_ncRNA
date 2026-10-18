#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "bedtools intersect GTF on the opposite strand (-S -wo)"
doc: |
  Find overlaps between two GTF files on the opposite strand.

  bedtools intersect accepts GTF when the filename ends in .gtf. It reads
  the interval from columns 1, 4, and 5, and the strand from column 7.
  -S keeps a B record only when it overlaps A on the other strand.
  -wo writes every column of A, every column of B, and the overlap width
  in bp as the last column. Reported coordinates stay 1-based, because
  bedtools prints the original GTF records. bedtools does not allow
  -wa/-wb together with -wo.

  For a GENCODE antisense survey, pass transcript-feature rows (column 3
  is "transcript") as both -a and -b. Each row is one transcript span.

  This tool does not pass -sorted. bedtools intersect still runs when the
  inputs are unsorted.

  Output columns:
    [all columns from query GTF (-a)]
    [all columns from database GTF (-b)]
    [overlap_bp]

  bedtools writes the intersect table to stdout. Warnings, including the
  Docker platform message, go to stderr and are captured as a log.

  help:
    docker run --rm quay.io/biocontainers/bedtools:2.31.1--h13024bc_3 bedtools intersect --help
  documentation:
    https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html

baseCommand: [bedtools, intersect]

arguments:
  - -a
  - $(inputs.query_gtf_file)
  - -b
  - $(inputs.query_gtf_file)
  - -S
  - -wo

stdout: $(inputs.query_gtf_file.nameroot)_opposite_strand_intersecting_$(inputs.query_gtf_file.nameroot).tsv
stderr: $(inputs.query_gtf_file.nameroot)_stderr.log

inputs:
  - id: query_gtf_file
    type: File
    label: "query GTF file"
    doc: |
      Transcript GTF used as both -a and -b. The filename must end in .gtf
      so bedtools reads column 7 as the strand. Column 3 should be transcript.
    format: edam:format_2305
    default:
      class: File
      format: edam:format_2305
      location: ../Data/Database/GENCODE_v49/gencode.v49.chr_patch_hapl_scaff.annotation_transcript_id_only.gtf

outputs:
  - id: intersect_output_file
    type: File
    label: "opposite-strand intersect table"
    doc: |
      A and B GTF records that overlap on opposite strands.
      The last column is overlap width in bp (-wo).
      Each pair is written twice, once in each direction.
    format: iana:text/tab-separated-values
    streamable: true
    outputBinding:
      glob: $(inputs.query_gtf_file.nameroot)_opposite_strand_intersecting_$(inputs.query_gtf_file.nameroot).tsv

  - id: stderr_log
    type: File
    label: "stderr log"
    doc: "stderr captured by cwltool, including bedtools warnings and the Docker platform warning."
    outputBinding:
      glob: $(inputs.query_gtf_file.nameroot)_stderr.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bedtools:2.31.1--h13024bc_3

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
