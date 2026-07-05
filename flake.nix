{
  description = "John's personal Nix package set";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Every package under ./pkgs, filtered to those available on each system.
      packages = forAllSystems (
        pkgs:
        lib.filterAttrs (_: pkg: lib.meta.availableOn pkgs.stdenv.hostPlatform pkg) (
          import ./pkgs { inherit pkgs; }
        )
      );

      # Merge this package set into nixpkgs:
      #   nixpkgs.overlays = [ my-packages.overlays.default ];
      overlays.default = final: _prev: import ./pkgs { pkgs = final; };

      # `nix flake check` builds every package.
      checks = forAllSystems (pkgs: self.packages.${pkgs.stdenv.hostPlatform.system});

      # nixfmt-tree = treefmt preconfigured with nixfmt, so `nix fmt`
      # can format the whole tree.
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nixfmt
            pkgs.nix-init
          ];
        };
      });
    };
}
