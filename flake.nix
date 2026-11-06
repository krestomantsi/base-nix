{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # The main pin above is from Oct 2024. The framework host needs a recent
    # kernel + Mesa for Strix Halo (gfx1151), so it gets its own input. Nix
    # resolves this automatically on first eval -- no `nix flake update`
    # needed, and the other hosts keep their old pin.
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-latest, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
    
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [ 
            ./configuration.nix
          ];
        };
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [ 
            ./hosts/laptop/configuration.nix
          ];
        };
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [ 
            ./hosts/desktop/configuration.nix
          ];
        };
      nixosConfigurations.framework = nixpkgs-latest.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [ 
            ./hosts/framework/configuration.nix
          ];
        };

    };
}
