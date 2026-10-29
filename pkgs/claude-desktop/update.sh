#!/usr/bin/env bash
# Pone default.nix en la última versión del repo apt oficial de Claude Desktop.
# No compila ni aplica nada: revisa el diff (git diff pkgs/claude-desktop) y luego rbd.
#   ./pkgs/claude-desktop/update.sh           actualiza default.nix
#   ./pkgs/claude-desktop/update.sh --check   solo dice si hay versión nueva ("actual -> nueva"), sin tocar nada
set -euo pipefail

check_only=false
[[ "${1:-}" == "--check" ]] && check_only=true

repo="https://downloads.claude.ai/claude-desktop/apt/stable"
pkg_file="$(dirname "$0")/default.nix"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$repo/dists/stable/InRelease" > "$tmp/InRelease"
curl -fsSL "$repo/dists/stable/main/binary-amd64/Packages" > "$tmp/Packages"

# El índice Packages tiene que ser el que declara InRelease
expected="$(awk '/^SHA256:/ { f = 1; next } /^[^ ]/ { f = 0 } f && $3 == "main/binary-amd64/Packages" { print $1 }' "$tmp/InRelease")"
actual="$(sha256sum "$tmp/Packages" | cut -d' ' -f1)"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
  echo "Packages no coincide con InRelease (esperado: ${expected:-nada}, recibido: $actual)" >&2
  exit 1
fi

# Última versión de claude-desktop y su SHA256
read -r version sha256 < <(
  awk 'BEGIN { RS = ""; FS = "\n" }
    /(^|\n)Package: claude-desktop(\n|$)/ {
      v = ""; h = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^Version: /) v = substr($i, 10)
        if ($i ~ /^SHA256: /) h = substr($i, 9)
      }
      if (v != "" && h != "") print v, h
    }' "$tmp/Packages" | sort -V | tail -n1
)
if [[ -z "${version:-}" || -z "${sha256:-}" ]]; then
  echo "No encuentro claude-desktop en el índice" >&2
  exit 1
fi

current="$(sed -n 's/^  version = "\([^"]*\)";/\1/p' "$pkg_file")"
if [[ "$version" == "$current" ]]; then
  $check_only || echo "Ya está en la última versión ($current)"
  exit 0
fi
if $check_only; then
  echo "$current -> $version"
  exit 0
fi

hash="$(nix hash convert --hash-algo sha256 --to sri "$sha256")"
VERSION="$version" HASH="$hash" perl -0pi -e '
  s{^  version = "[^"]+";}{  version = "$ENV{VERSION}";}m or die "no encuentro version\n";
  s{debArch = "amd64";\n      hash = "[^"]+";}{debArch = "amd64";\n      hash = "$ENV{HASH}";} or die "no encuentro hash\n";
' "$pkg_file"

echo "claude-desktop: $current -> $version"
