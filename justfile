default:
  @just --choose

# Build English resume
build-en:
    nix run .#build-en

# Build German resume
build-de:
    nix run .#build-de

# Build Dutch resume
build-nl:
    nix run .#build-nl

# Build all language versions
build-all:
    nix run .#build-en
    nix run .#build-de
    nix run .#build-nl

# Watch for changes (English)
watch:
    nix run .#watch
