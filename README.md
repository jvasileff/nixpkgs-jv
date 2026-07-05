# nixpkgs-jv

A flake of personal packages that aren't available in [nixpkgs](https://github.com/NixOS/nixpkgs),
structured the same way nixpkgs is.

## Layout

```sh
flake.nix            # flake outputs (packages, overlay, checks, ...)
pkgs/
  default.nix        # auto-discovers everything under by-name/
  by-name/
    <shard>/         # first two letters of the package name
      <pname>/
        package.nix  # callPackage-style package definition
```

## Adding a package

Create `pkgs/by-name/<shard>/<pname>/package.nix` (e.g. `pkgs/by-name/fo/foo/package.nix`),
where `<shard>` is the lowercased first two letters of `<pname>`. The file is a normal
`callPackage`-style expression, exactly like a nixpkgs `package.nix`. Discovery is
automatic — no other file needs to change. Remember that flakes only see git-tracked
files: `git add --intent-to-add` the new file so nix can see it without staging it.

To make the package updatable by `just update`, declare `passthru.updateScript`
(usually `nix-update-script { }`) or ship a custom `update.sh` next to it — see
[Updating](#updating).

## Usage

Build or run a package directly:

```sh
nix build .#hello-flake
nix run .#hello-flake
```

As a flake input:

```nix
{
  inputs.nixpkgs-jv.url = "github:jvasileff/nixpkgs-jv";
}
```

Then either use packages directly (`nixpkgs-jv.packages.${system}.hello-flake`) or
merge the whole set into nixpkgs via the overlay:

```nix
nixpkgs.overlays = [ nixpkgs-jv.overlays.default ];
```

This flake pins nixpkgs to `nixos-26.05` (the last release to support
x86_64-darwin). Consumers can rebase it onto their own nixpkgs — unstable, a
newer stable, etc. — with:

```nix
inputs.nixpkgs-jv.inputs.nixpkgs.follows = "nixpkgs";
```

(Overlay consumers get this for free: an overlay always builds against the
package set it's applied to.)

### Registry alias

For CLI convenience, add this flake to the local registry on your machines:

```sh
nix registry add nixpkgs-jv github:jvasileff/nixpkgs-jv
```

Packages can then be run from anywhere, just like `nixpkgs#hello`:

```sh
nix run nixpkgs-jv#ttn-lw-cli
```

## Updating

There are two independent update axes. Package versions are pinned by
`version` + hashes inside each `package.nix` and are updated by per-package
update commands (also wired as `passthru.updateScript`). The nixpkgs pin in
`flake.lock` (Go toolchain, stdenv, lib) is updated separately — `nix flake
update` never changes package versions.

```sh
just update                  # update every package to its latest upstream release
just update ttn-lw-cli       # update specific packages
just update-nixpkgs          # bump the nixpkgs pin (flake.lock)
```

`just update` needs no per-package configuration; it follows a convention:

* a package with a custom updater ships an `update.sh` next to its
  `package.nix`, and that script is run;
* otherwise, a package that declares `passthru.updateScript` is updated with
  [`nix-update`](https://github.com/Mic92/nix-update), which understands the
  standard fetchers and builders (version bump, `src` hash, `vendorHash`, ...);
* packages with neither are skipped.

After updating, verify with `just check`, which builds every package for the
current system, running each package's build-time checks (test suites,
`versionCheckHook`), and evaluation-checks the other platforms. Full build
coverage of all platforms needs a builder per platform — that's CI's job.
Note that `nix-update` refreshes `flake.lock` as a side effect of evaluating
the flake; the update recipe reverts that so nixpkgs bumps stay a deliberate,
separate step.

## Development

Common commands live in the `justfile` (run a bare `just` to list them):

```sh
just list            # list the packages this flake provides
just check           # build + test every package for the current system;
                     # eval-check all other platforms
just build <pkg>     # nix build .#<pkg>
just run <pkg> ...   # nix run .#<pkg> -- ...
just fmt             # format nix files (nixfmt)
nix develop          # shell with just, nix-update, nix-init, nixfmt
```
