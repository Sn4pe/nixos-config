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
      # Cambia esto si al instalar eliges otro usuario u otro hostname
      user = "dfadon";
      hostName = "pc";
    in
    {
      devShells.x86_64-linux = import ./shells.nix { pkgs = nixpkgs.legacyPackages.x86_64-linux; };

      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit user hostName; };
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
          stylix.nixosModules.stylix
          ./theme.nix
          # ./nvidia.nix  # descomenta si el PC tiene gráfica NVIDIA
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "bak";
              extraSpecialArgs = { inherit user; };
              users.${user} = ./home.nix;
            };
          }
        ];
      };
    };
}
