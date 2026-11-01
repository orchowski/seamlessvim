#!/usr/bin/env bash
#
# Builds and runs the seamlessvim test image(s).
#
#   test/docker/run.sh arch      # Arch only
#   test/docker/run.sh debian    # Debian only
#   test/docker/run.sh both      # both (default)
#
# Named volumes cache lazy.nvim plugins, mason packages and coursier across runs.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"

case "${1:-both}" in
  arch) DISTROS=(arch) ;;
  debian) DISTROS=(debian) ;;
  both) DISTROS=(arch debian) ;;
  *)
    echo "usage: $0 [arch|debian|both]" >&2
    exit 1
    ;;
esac

declare -A BASES=([arch]="archlinux:base-devel" [debian]="debian:trixie")

rc=0
for d in "${DISTROS[@]}"; do
  img="seamlessvim-test:$d"
  echo "===================================================================="
  echo "== $d  (base: ${BASES[$d]})"
  echo "===================================================================="

  docker build -f "$HERE/Dockerfile" --build-arg "BASE_IMAGE=${BASES[$d]}" -t "$img" "$HERE"

  docker run --rm \
    -e SEAMLESSVIM_SOURCE=/src \
    -e SEAMLESSVIM_ASSUME_YES=1 \
    -v "$REPO:/src:ro" \
    -v "seamlessvim-data-$d:/home/dev/.local/share/nvim" \
    -v "seamlessvim-cache-$d:/home/dev/.cache/nvim" \
    -v "seamlessvim-coursier-$d:/home/dev/.local/share/coursier" \
    "$img" bash /src/test/docker/inside.sh || rc=1
done

exit "$rc"
