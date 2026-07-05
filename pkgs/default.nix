# Package set entry point, modelled on nixpkgs' pkgs/by-name layout:
# each package lives at pkgs/by-name/<shard>/<pname>/package.nix, where
# <shard> is the lowercased first two letters of <pname>.
#
# Packages are discovered automatically; adding a package.nix in the right
# place is all that's needed.
#
# Discovery deliberately uses only builtins, never pkgs.lib: this set is
# also an overlay (flake.nix passes pkgs = final), and an overlay's
# attribute *names* must be computable without forcing the fixpoint, or
# every consumer hits infinite recursion. Values (callPackage) may use
# pkgs freely — they are lazy.
{ pkgs }:
let
  byName = ./by-name;

  packagesInShard =
    shard:
    builtins.mapAttrs (name: _: pkgs.callPackage (byName + "/${shard}/${name}/package.nix") { }) (
      builtins.readDir (byName + "/${shard}")
    );
in
builtins.foldl' (acc: shard: acc // packagesInShard shard) { } (
  builtins.attrNames (builtins.readDir byName)
)
