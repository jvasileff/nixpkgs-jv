# Package set entry point, modelled on nixpkgs' pkgs/by-name layout:
# each package lives at pkgs/by-name/<shard>/<pname>/package.nix, where
# <shard> is the lowercased first two letters of <pname>.
#
# Packages are discovered automatically; adding a package.nix in the right
# place is all that's needed.
{ pkgs }:
let
  inherit (pkgs) lib;

  byName = ./by-name;

  packagesInShard =
    shard:
    lib.mapAttrs (name: _: pkgs.callPackage (byName + "/${shard}/${name}/package.nix") { }) (
      builtins.readDir (byName + "/${shard}")
    );
in
lib.mergeAttrsList (map packagesInShard (builtins.attrNames (builtins.readDir byName)))
