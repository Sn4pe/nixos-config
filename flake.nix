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
    hyprglance = {
      url = "github:Sn4pe/hyprglance";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # shortcut: nixpkgs fijado porque el nuevo exporta AWS_LC_SYS_USE_SYSTEM=1 y accioshot no trae aws-lc,
    # quitar cuando accioshot lo añada a buildInputs
    nixpkgs-accioshot.url = "github:nixos/nixpkgs/31ecbaca1bdefa45dffc409f0250bd8039ea0010";
    accioshot = {
      url = "github:Sn4pe/accioshot/v0.2.0";
      inputs.nixpkgs.follows = "nixpkgs-accioshot";
    };
    # Local: github.com/Sn4pe/halo es privado y así no hacen falta credenciales al evaluar
    halo = {
      url = "git+file:///home/dfadon/Projects/halo";
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
                extraSpecialArgs = { inherit user inputs; };
                sharedModules = [ inputs.hyprglance.homeManagerModules.default ];
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
