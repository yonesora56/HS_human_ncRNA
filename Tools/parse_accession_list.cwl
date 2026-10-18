#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: ExpressionTool
label: "parse_accession_list"
doc: "Read a text file containing one accession per line and return a string array. Empty lines and lines starting with '#' are skipped."

requirements:
  InlineJavascriptRequirement: {}

inputs:
  - id: accession_list
    type: File
    # loadContents makes the file body available as inputs.accession_list.contents
    # (up to 64 KiB as defined by the CWL v1.2 spec)
    loadContents: true
    label: "accession_list"
    doc: "text file containing one accession number per line"

outputs:
  - id: accessions
    type: string[]
    label: "accessions"
    doc: "array of accession strings parsed from the input file"

expression: |
  ${
    var lines = inputs.accession_list.contents.split(/\r?\n/);
    var out = [];
    for (var i = 0; i < lines.length; i++) {
      var t = lines[i].replace(/^\s+|\s+$/g, "");
      if (t.length === 0) continue;
      if (t.charAt(0) === '#') continue;
      out.push(t);
    }
    return { "accessions": out };
  }

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/
