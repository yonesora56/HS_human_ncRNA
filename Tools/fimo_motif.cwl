#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "Scan FASTA sequences for motif occurrences with FIMO"
doc: |
  Find individual motif occurrences with MEME Suite FIMO.

  Intended inputs:
    motifs:    Data/Database/JASPAR/HSF1_human_MA0486_versions.meme
    sequences: Data/Database/fantabio/human-CREv1.2.1.hg38.cre-peaks.fa

  The motif file contains two HSF1 matrices (MA0486.1 and MA0486.2).
  --motif is not set, so FIMO scans every matrix in the file. Scanning a
  single matrix id belongs in a separate tool.

  The sequence FASTA is the bed2fasta.cwl product for the FANTOM CRE peaks.
  Headers are BED column 4 (FCHS_*). Sequences are the forward genomic strand.
  The motif file sets strands to "+ -", so FIMO scores both strands.
  --norc is not set.

  Fixed flags (no runtime branching):
    --bfile --motif--
           Use the background letter frequencies stored in the motif file
           (A/C/G/T 0.25). FIMO would otherwise use its NRDB DNA background.
    --o    Write the result directory and refuse to overwrite an existing one.

  --text is not used, so q-values are computed and fimo.tsv, fimo.gff,
  fimo.html, cisml.xml, and fimo.xml are all written into the output directory.

  help:
    docker run --rm quay.io/biocontainers/meme:5.5.9--pl5321he99cc7f_1 fimo
  documentation:
    https://meme-suite.org/meme/doc/fimo.html

baseCommand: [fimo]

arguments:
  - --o
  - $(inputs.output_directory_name)
  - --bfile
  - --motif--
  - --thresh
  - $(inputs.p_value_threshold)
  - --max-stored-scores
  - $(inputs.max_stored_scores)
  - $(inputs.motif_file)
  - $(inputs.sequences_fasta)

inputs:
  - id: motif_file
    type: File
    label: "MEME motif file"
    doc: |
      MEME-formatted motifs. The default file holds JASPAR HSF1 matrices
      MA0486.1 (width 15) and MA0486.2 (width 13).
      URL: https://jaspar.elixir.no/matrix/MA0486.1/
    format: edam:format_1360
    default:
      class: File
      format: edam:format_1360
      location: ../Data/Database/JASPAR/HSF1_human_MA0486_versions.meme

  - id: sequences_fasta
    type: File
    label: "sequences FASTA"
    doc: |
      FASTA sequences to scan. The default file is the cis-element sequence
      extracted from human-CREv1.2.1.hg38.cre-peaks.bed by bed2fasta.cwl.
    format: edam:format_1929
    default:
      class: File
      format: edam:format_1929
      location: ../Data/Database/fantabio/human-CREv1.2.1.hg38.cre-peaks.fa

  - id: output_directory_name
    type: string
    label: "FIMO output directory name"
    doc: |
      Directory created by --o. FIMO fails if this directory already exists.
    default: HSF1_MA0486_cre_peaks_fimo

  - id: p_value_threshold
    type: float
    label: "p-value threshold"
    doc: |
      Report motif occurrences with a p-value lower than this value.
      FIMO's own default is 1e-4. Thresholding on q-values belongs in a
      separate tool that passes --qv-thresh.
    default: 1.0e-4

  - id: max_stored_scores
    type: int
    label: "maximum stored motif scores"
    doc: |
      Upper bound passed to --max-stored-scores. FIMO's own default is
      100000. Once that bound is reached, FIMO drops the least significant
      half of the hits and the q-values become approximate. The default
      here is higher because the CRE FASTA has about 5.1e5 sequences and
      the motif file contains two matrices.
    default: 1000000



outputs:
  - id: fimo_directory
    type: Directory
    label: "FIMO output directory"
    doc: |
      Directory with fimo.tsv, fimo.gff, fimo.html, best_site.narrowPeak,
      cisml.xml, and fimo.xml.
    outputBinding:
      glob: $(inputs.output_directory_name)

  - id: fimo_tsv
    type: File
    label: "FIMO hits table"
    doc: |
      Tab-separated motif occurrences, including q-values.
      Columns are motif_id, motif_alt_id, sequence_name, start, stop,
      strand, score, p-value, q-value, and matched_sequence.
    format: iana:text/tab-separated-values
    streamable: true
    outputBinding:
      glob: $(inputs.output_directory_name)/fimo.tsv

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/meme:5.5.9--pl5321he99cc7f_1

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
