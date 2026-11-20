{ config, inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    policies = config.programs.firefox.policies;
    profiles.default = {
      isDefault = true;
      extraConfig = builtins.readFile "${inputs.betterfox}/zen/user.js";
      search = {
        force = true;
        default = "kagi";
        engines.kagi = {
          name = "Kagi";
          urls = [ { template = "https://kagi.com/search?q={searchTerms}"; } ];
          definedAliases = [ "@k" ];
        };
      };
    };
  };

  stylix.targets.zen-browser.profileNames = [ "default" ];
}
