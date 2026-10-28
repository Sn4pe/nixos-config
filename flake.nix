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
    # Repo privado con lo que no debe ir a este repo público (inventario OCS de AIR).
    # Como kadachi con kadachi-secrets; se descarga con la sesión de `gh`
    secrets = {
      url = "git+https://github.com/sn4pe/nixos-secrets";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      stylix,
      ...
    }@inputs:
    let
      # Cambia esto si al instalar eliges otro usuario
      user = "dfadon";

      # Cada máquina = módulos comunes + su carpeta en hosts/<hostName>
      mkHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs user hostName; };
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
      nixosConfigurations.AIR231 = mkHost "AIR231";

      devShells.x86_64-linux = import ./shells { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
    };
}
