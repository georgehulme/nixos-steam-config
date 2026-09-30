# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, disko, home-manager, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";

    userDirs = builtins.readDir ./users;
    users = builtins.attrNames (nixpkgs.lib.filterAttrs (name: type: type == "directory") userDirs);

    mkUserConfig = username:
      let
        userConfig = ./users/${username}/configuration.nix;
	userHome = ./users/${username}/home.nix;
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./disko-config.nix
          ./configuration.nix
          (if builtins.pathExists userConfig then userConfig else {})
	
	  home-manager.nixosModules.home-manager
	  {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ inputs.nixvim.homeModules.nixvim ];
            home-manager.users.${username} =
	      if builtins.pathExists userHome then import userHome else {};
          }
        ];
      };
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs users 
      (username: mkUserConfig username);
  };
}
