{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      stylix,
      ...
    }:
    let
      # Cambia esto si al instalar eliges otro usuario
      user = "dfadon";

      # Cada máquina = módulos comunes + su carpeta en hosts/<hostName>
      mkHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit user hostName; };
          modules = [
            ./hosts/${hostName}
            ./modules/system
            stylix.nixosModules.stylix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit user; };
                users.${user} = ./modules/home;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.pc = mkHost "pc";

      devShells.x86_64-linux = import ./shells { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
    };
}
