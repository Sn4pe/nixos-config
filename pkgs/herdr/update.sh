#!/usr/bin/env bash
# Pone default.nix en las últimas versiones de la app y de herdr-core (releases.herdr.dev).
# No compila ni aplica nada: revisa el diff (git diff pkgs/herdr) y luego rbd.
#   ./pkgs/herdr/update.sh           actualiza default.nix
#   ./pkgs/herdr/update.sh --check   solo dice qué tiene versión nueva ("app actual -> nueva"), sin tocar nada
set -euo pipefail

check_only=false
[[ "${1:-}" == "--check" ]] && check_only=true

pkg_file="$(dirname "$0")/default.nix"
changed=false

for part in app core; do
  read -r version sha256 < <(
    curl -fsSL "https://releases.herdr.dev/$part/latest.json" |
      jq -r '[.version, .targets["linux-x86_64"].sha256] | @tsv'
  )
  if [[ -z "${version:-}" || -z "${sha256:-}" || "$sha256" == null ]]; then
    echo "No encuentro $part para linux-x86_64 en latest.json" >&2
    exit 1
  fi

  current="$(PART="$part" perl -0ne 'print $1 if /^  $ENV{PART} = \{\n    version = "([^"]+)";/m' "$pkg_file")"
  [[ "$version" == "$current" ]] && continue
  changed=true
  if $check_only; then
    echo "$part $current -> $version"
    continue
  fi

  hash="$(nix hash convert --hash-algo sha256 --to sri "$sha256")"
  PART="$part" VERSION="$version" HASH="$hash" perl -0pi -e '
    s#^(  $ENV{PART} = \{\n    version = )"[^"]+";\n    hash = "[^"]+";#$1"$ENV{VERSION}";\n    hash = "$ENV{HASH}";#m
      or die "no encuentro $ENV{PART} en default.nix\n";
  ' "$pkg_file"
  echo "herdr $part: $current -> $version"
done

$changed || $check_only || echo "Ya está en la última versión"
