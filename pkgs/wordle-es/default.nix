# La palabra del día en la terminal, compilado desde el input `wordle-es` (solo código, sin flake)
{ rustPlatform, src }:

rustPlatform.buildRustPackage {
  pname = "wordle-es";
  version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  meta.mainProgram = "wordle-es";
}
