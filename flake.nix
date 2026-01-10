{
  description = "McCak NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-cachyos-kernel, aagl, home-manager, lix, lix-module, ... } @ inputs:
  let
    makeConfig = { name, username, hostFile, extraModules ? [] }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        lix-module.nixosModules.default
        aagl.nixosModules.default
        hostFile
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${username} = import ./users/${username}/home.nix;
        }
      ] ++ extraModules;
    };
  in
  {
    nix.settings = aagl.nixConfig;
    nixosConfigurations = {
      "nixos-test" = makeConfig { 
        name = "nixos-test"; 
        username = "cak"; 
        hostFile = ./hosts/nixos-test; 
      };
      "840-g6" = makeConfig { 
        name = "840-g6"; 
        username = "cak"; 
        hostFile = ./hosts/840-g6; 
      };
      "desktop" = makeConfig { 
        name = "desktop"; 
        username = "cak"; 
        hostFile = ./hosts/desktop; 
      };
      "delta" = makeConfig { 
        name = "delta"; 
        username = "cak"; 
        hostFile = ./hosts/delta; 
      };
    };
  };
}
