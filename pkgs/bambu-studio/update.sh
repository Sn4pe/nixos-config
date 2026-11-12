#!/usr/bin/env bash
# Pone default.nix en la última release de Bambu Studio (la AppImage ubu24 de GitHub).
# No compila ni aplica nada: revisa el diff (git diff pkgs/bambu-studio) y luego rbd.
#   ./pkgs/bambu-studio/update.sh           actualiza default.nix
#   ./pkgs/bambu-studio/update.sh --check   solo dice si hay versión nueva ("actual -> nueva"), sin tocar nada
set -euo pipefail

check_only=false
[[ "${1:-}" == "--check" ]] && check_only=true

pkg_file="$(dirname "$0")/default.nix"

asset="$(gh release view -R bambulab/BambuStudio --json assets \
  -q '.assets[].name | select(test("^BambuStudio_ubu24-v.*\\.AppImage$"))')"
# BambuStudio_ubu24-v02.09.01.70-20261103183404.AppImage
if [[ ! "$asset" =~ ^BambuStudio_ubu24-v([0-9.]+)-([0-9]+)\.AppImage$ ]]; then
  echo "No encuentro la AppImage ubu24 en la última release" >&2
  exit 1
fi
version="${BASH_REMATCH[1]}"
build="${BASH_REMATCH[2]}"

current="$(perl -ne 'print $1 if /^  version = "([^"]+)";/' "$pkg_file")"
if [[ "$version" == "$current" ]]; then
  echo "Ya está en la última versión"
  exit 0
fi
if $check_only; then
  echo "bambu-studio $current -> $version"
  exit 0
fi

hash="$(nix store prefetch-file --json \
  "https://github.com/bambulab/BambuStudio/releases/download/v$version/$asset" | jq -r .hash)"
VERSION="$version" BUILD="$build" HASH="$hash" perl -pi -e '
  s#^(  version = )"[^"]+";#$1"$ENV{VERSION}";#;
  s#^(  build = )"[^"]+";#$1"$ENV{BUILD}";#;
  s#^(    hash = )"[^"]+";#$1"$ENV{HASH}";#;
' "$pkg_file"
echo "bambu-studio: $current -> $version"

# Los offsets de empty-drop.py son de una versión. #12052 parece el mismo fallo
issue="$(gh issue view 12052 -R bambulab/BambuStudio --json state -q .state 2>/dev/null || echo "?")"
echo
echo "Ojo: empty-drop.py es para $current y su build fallará con $version (bambulab/BambuStudio#12052: $issue)."
echo "  Si lo han arreglado, quita contents y empty-drop.py de default.nix. Si no, hay que rehacer los offsets."
