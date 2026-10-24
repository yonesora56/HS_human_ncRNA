#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "enrichment analysis with elim (goatools)"
doc: |
  "
  uv pip install --system goatools==1.6.6
  Enrichment analysis using goatools version 1.6.6, algorithm elim.
  GitHub: https://github.com/tanghaibao/goatools
  help: find_enrichment.py --help
  elim scores one-sided enrichment and the TSV keeps rows by p_uncorrected.
  about elim algorithm: DOI: 10.1093/bioinformatics/btl140
  "

requirements:
  InitialWorkDirRequirement:
    listing:
      - entryname: $(inputs.output_file_name)
        # Header-only table. goatools overwrites this when any term is significant.
        # writable is required: the default literal file is mode 0400, which this
        # workspace cannot open for writing on the next run.
        writable: true
        entry: "# GO\tNS\tenrichment\tname\tratio_in_study\tratio_in_pop\tfold_enrichment\tp_uncorrected\tdepth\tstudy_count\tp_fdr_bh\tstudy_items\n"

baseCommand: [find_enrichment.py]

arguments:
  - $(inputs.target_genelist.path)
  - $(inputs.background_genelist.path)
  - $(inputs.annotation_file.path)
  - --alpha=$(inputs.alpha)
  - --pval=$(inputs.pvalue)
  - --method=$(inputs.method)
  - --algorithm=$(inputs.algorithm)
  - --elim_cutoff=$(inputs.elim_cutoff)
  - --pval_field=$(inputs.pval_field)
  - --obo=$(inputs.obo_file.path)
  - --obsolete=$(inputs.obsolete_go)
  - --outfile=$(inputs.output_file_name)

inputs:
  - id: target_genelist
    type: File
    label: "Gene list"
    doc: "Your interest transcript list"
    default:
      class: File
      location: ../out/enrichment_analysis/query/up5p_transcript_list.txt

  - id: background_genelist
    type: File
    label: "All transcript list"
    doc: "All transcript list including your interest transcript list"
    default:
      class: File
      location: ../out/enrichment_analysis/background/background_quantified_transcript_list.txt


  - id: annotation_file
    type: File
    label: "Transcript-Ontology association file"
    doc: "Transcript-Ontology association file. format example: https://github.com/moshi4/goatools-demo/tree/main/data"
    default:
      class: File
      location: ../out/enrichment_analysis/transcript_go_association/transcript_go_association.txt

  - id: alpha
    type: float
    label: "Alpha"
    doc: "Alpha"
    default: 0.01

  - id: pvalue
    type: float
    label: "P-value"
    doc: "P-value"
    default: 0.01

  - id: method
    type: string
    label: "Method"
    doc: "Method"
    default: "fdr_bh"

  - id: algorithm
    type:
      type: enum
      symbols:
        - classic
        - elim
    label: "GO term scoring algorithm"
    doc: |
      elim removes genes of a significant child from its ancestors before
      scoring the parent. Goatools then uses a one-sided greater Fisher test.
    default: elim

  - id: elim_cutoff
    type: float
    label: "Elim cutoff"
    doc: |
      A term at or below this uncorrected p-value has its genes removed from
      its ancestors. Ignored unless algorithm is elim.
    default: 0.01

  - id: pval_field
    type: string
    label: "P-value field"
    doc: |
      Column compared with pvalue when writing the TSV. uncorrected matches
      the elim p-values. fdr_bh on top of elim is over-conservative.
    default: "uncorrected"

  - id: obo_file
    type: File
    label: "OBO file"
    doc: "ontology OBO file for replacing latest ontology file"
    default:
      class: File
      location: ../Data/Database/GO/go_release_20260805.obo

  - id: obsolete_go
    type: string
    label: "Obsolete GO"
    doc: "Strategy for handling obsolete GO terms {keep,replace,skip}"
    default: "replace"


  - id: output_file_name
    type: string
    label: "Output file name"
    doc: "Output file name"
    default: "enrichment_analysis_up5p_transcript_list_elim.tsv"

  - id: stdout_file_name
    type: string
    label: "Standard output file name"
    doc: "Standard output file name"
    default: "find_enrichment_stdout_up5p_transcript_list_elim.txt"

stdout: $(inputs.stdout_file_name)

outputs:
  - id: enrichment_result
    type: File
    label: "Enrichment result"
    doc: "Enrichment result"
    outputBinding:
      glob: $(inputs.output_file_name)

  - id: stdout
    type: File
    label: "Standard output"
    doc: "Standard output"
    outputBinding:
      glob: $(inputs.stdout_file_name)


# hints:
#   - class: DockerRequirement
#     dockerPull: 

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/