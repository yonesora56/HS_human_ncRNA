#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "score one Hi-C chromosome IF with Fit-Hi-C"
doc: |
  Calculate one-sample Interaction Frequency (IF) from a Juicer .hic file by
  calling scripts/hic1dmetrics_score_single_sample_if.py (juicer dump observed
  KR, Fit-Hi-C, FDR coverage, h1d log1p normalization). One job handles one
  sample and one chromosome so a workflow can scatter later.

  IF cannot use dumped matrices. Pass juicer_tools 2.20.00 for HIC v9.

  The output file names are composed from parameter references only
  (no InlineJavascriptRequirement):
    $(hic_file.nameroot).$(chromosome).IF.bedGraph
    $(hic_file.nameroot).$(chromosome).IF.significances.txt
    $(hic_file.nameroot).$(chromosome).IF.fithic_pass1.txt
    $(hic_file.nameroot).$(chromosome).IF.log

  Fit-Hi-C writes its progress to stdout; this tool redirects stdout to the
  .IF.log file. The significances table (FitHiC.spline_pass1.significances.txt)
  and the pass-1 table (FitHiC.fithic_pass1.res{resolution}.txt) are copied
  out of the temporary working directory.

  help:
    python3 scripts/hic1dmetrics_score_single_sample_if.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/onesample.html#calculate-1d-metrics-one-sample

baseCommand: [python3]

arguments:
  - $(inputs.score_script)
  - --hic-file
  - $(inputs.hic_file)
  - --genome-table
  - $(inputs.genome_table)
  - --juicer-tools
  - $(inputs.juicer_tools)
  - --chromosome
  - $(inputs.chromosome)
  - --resolution
  - $(inputs.resolution)
  - --fdr-threshold
  - $(inputs.fdr_threshold)
  - --output-bedgraph-file
  - $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.bedGraph
  - --output-significances-file
  - $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.significances.txt
  - --output-fithic-pass1-file
  - $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.fithic_pass1.txt

stdout: $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.log

inputs:
  - id: score_script
    type: File
    label: "hic1dmetrics IF score script"
    doc: "Python wrapper around juicer dump + Fit-Hi-C for one-sample IF"
    default:
      class: File
      location: ../../scripts/hic1dmetrics_score_single_sample_if.py

  - id: hic_file
    type: File
    label: "Juicer hic file"
    doc: "Input .hic file for one sample (IF requires rawhic, not a dumped matrix)"
    default:
      class: File
      location: ../../out/hic/GSE105028_hichip_convert_hic/CTCF_HS_merged_juicer_pre_output/CTCF_HS_merged.hic

  - id: genome_table
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths for Fit-Hi-C fragment bins"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../../out/h1d/hg38_genome_table.txt

  - id: juicer_tools
    type: File
    label: "juicer_tools jar"
    doc: "juicer_tools jar used by dump (2.20.00 for HIC v9)"
    default:
      class: File
      location: ../../out/h1d/juicer_tools.2.20.00.jar

  - id: chromosome
    type: string
    label: "chromosome"
    doc: "Chromosome name matching the genome table, e.g. chr21"
    default: "chr21"

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp; must exist in the .hic file"
    default: 5000

  - id: fdr_threshold
    type: float
    label: "Fit-Hi-C FDR threshold"
    doc: "q-value cutoff for significant interactions (h1d InteractionFreq.sh uses 0.05)"
    default: 0.05

outputs:
  - id: bedgraph_file
    type: File
    label: "IF bedGraph"
    doc: "Four-column chromosome bedGraph (chr, start, end, normalized IF) with no header"
    format: edam:format_3583
    streamable: true
    outputBinding:
      glob: $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.bedGraph

  - id: significances_file
    type: File
    label: "Fit-Hi-C significances table"
    doc: |
      Uncompressed copy of FitHiC.spline_pass1.significances.txt (locus pairs
      with p-values and q-values).
    format: iana:text/tab-separated-values
    streamable: true
    outputBinding:
      glob: $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.significances.txt

  - id: fithic_pass1_file
    type: File
    label: "Fit-Hi-C pass-1 table"
    doc: |
      Uncompressed copy of FitHiC.fithic_pass1.res{resolution}.txt (binned
      contacts used for the first spline pass).
    format: iana:text/tab-separated-values
    streamable: true
    outputBinding:
      glob: $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.fithic_pass1.txt

  - id: fithic_log_file
    type: File
    label: "Fit-Hi-C stdout log"
    doc: "Standard output from the IF script, including Fit-Hi-C progress"
    format: iana:text/plain
    streamable: true
    outputBinding:
      glob: $(inputs.hic_file.nameroot).$(inputs.chromosome).IF.log

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
