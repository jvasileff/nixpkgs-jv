# Personal Nix package set

A flake of personal packages that aren't available in [nixpkgs](https://github.com/NixOS/nixpkgs),
structured the same way nixpkgs is.

## Layout

```
flake.nix                                  # flake outputs (packages, overlay, checks, ...)
pkgs/
  default.nix                              # auto-discovers everything under by-name/
  by-name/
    <shard>/                               # first two letters of the package name
      <pname>/
        package.nix                        # callPackage-style package definition
```

## Adding a package

Create `pkgs/by-name/<shard>/<pname>/package.nix` (e.g. `pkgs/by-name/fo/foo/package.nix`),
where `<shard>` is the lowercased first two letters of `<pname>`. The file is a normal
`callPackage`-style expression, exactly like a nixpkgs `package.nix`. Discovery is
automatic — no other file needs to change. Remember to `git add` the new file so the
flake can see it.

## Usage

Build or run a package directly:

```sh
nix build .#hello-flake
nix run .#hello-flake
```

As a flake input:

```nix
{
  inputs.my-packages.url = "github:<you>/<this-repo>";
}
```

Then either use packages directly (`my-packages.packages.${system}.hello-flake`) or
merge the whole set into nixpkgs via the overlay:

```nix
nixpkgs.overlays = [ my-packages.overlays.default ];
```

## Development

```sh
nix flake check      # builds every package
nix fmt              # format nix files (nixfmt)
nix develop          # shell with nixfmt, nix-init, etc.
```
