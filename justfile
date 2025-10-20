default:
  @just --choose

build-en:
  nix run .#en

build-old:
  nix run .#en-old

# Build German resume
build-de:
  nix run .#de

# Build Dutch resume
build-nl:
  nix run .#nl

# Build all language versions
build-all:
  nix run .#en
  nix run .#en-old
  nix run .#de
  nix run .#nl

watch target="build-en":
  ls data/*.json main.typ template/*.typ | entr just {{target}}
