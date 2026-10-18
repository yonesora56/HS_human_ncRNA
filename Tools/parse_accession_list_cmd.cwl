#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "parse_accession_list_cmd"
doc: |
  Read a text file containing one accession per line and emit a string[] JSON
  via cwl.output.json. Unlike the ExpressionTool variant, this tool is NOT
  subject to the 64 KiB loadContents limit and therefore works for large lists.

requirements:
  InitialWorkDirRequirement:
    listing:
      - entryname: parse.py
        entry: |-
          # Read the accession list file and write cwl.output.json with the parsed string array.
          # Empty lines and lines starting with '#' are skipped.
          import json
          import sys

          accessions = []
          with open(sys.argv[1]) as f:
              for line in f:
                  t = line.strip()
                  if not t:
                      continue
                  if t.startswith("#"):
                      continue
                  accessions.append(t)

          with open("cwl.output.json", "w") as out:
              json.dump({"accessions": accessions}, out)

baseCommand: ["python3", "parse.py"]

arguments:
  - valueFrom: $(inputs.accession_list.path)

inputs:
  - id: accession_list
    type: File
    label: "accession_list"
    doc: "text file containing one accession number per line"

outputs:
  - id: accessions
    type: string[]
    label: "accessions"
    doc: "array of accession strings parsed from the input file"

hints:
  - class: DockerRequirement
    dockerPull: python:3.14.4-slim-trixie

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/
