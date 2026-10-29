{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
    slack
    obsidian
    spotify
    google-chrome
    # Cliente de Ollama: en Preferencias, instancia remota http://127.0.0.1:11434.
    # shortcut: el paquete de nixpkgs no trae pandas y no arranca, quitar cuando lo arreglen
    (alpaca.overridePythonAttrs (o: {
      dependencies = o.dependencies ++ [ python3Packages.pandas ];
    }))
    # De kadachi: utilidades de escritorio
    pcmanfm-qt
    lxqt.lxqt-archiver
    p7zip
    unrar
    imv
    mpv
    pavucontrol
  ];

  services.syncthing.enable = true; # panel en http://localhost:8384
}
