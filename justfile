# Available targets: en, en-new, en-old, de, nl
targets := "en en-new en-old de nl"

default:
  @just --choose

build target:
  nix run .#{{target}}

build-all:
  #!/usr/bin/env bash
  for target in {{targets}}; do
    nix run .#$target
  done

watch target="en":
  ls data/*.json main.typ template/*.typ | entr just build {{target}}
