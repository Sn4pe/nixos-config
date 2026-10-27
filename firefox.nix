# Basado en kadachi (kasane/web-browsers/firefox), recortado: sin telemetría,
# pestañas verticales, uBlock Origin y Bitwarden instalados por política
{
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;
      ExtensionSettings =
        let
          addon = id: {
            name = id;
            value = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
            };
          };
        in
        builtins.listToAttrs [
          (addon "uBlock0@raymondhill.net")
          (addon "{446900e4-71c2-419f-a6a7-df9c091e268b}") # Bitwarden
        ];
    };
    profiles.default = {
      isDefault = true;
      settings = {
        "browser.aboutConfig.showWarning" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.ml.chat.menu" = false;
        "middlemouse.paste" = false;
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
      };
    };
  };

  stylix.targets.firefox.profileNames = [ "default" ];
}
