# nixpkgs-jv

Personal Nix package flake for software not available in nixpkgs, structured
like nixpkgs itself. Goal: packages stay upstreamable — nixpkgs-style
`callPackage` files, `finalAttrs` pattern, `meta` with `mainProgram` and
`platforms`, build-time checks (`versionCheckHook`) where applicable.

## Layout and conventions

- A package lives at `pkgs/by-name/<shard>/<pname>/package.nix` (`<shard>` =
  first two letters of `<pname>`); `pkgs/default.nix` auto-discovers them.
  Adding a package means adding that one file — nothing else to wire up.
- Nix only sees git-tracked files: new files must be added to the index
  (`git add --intent-to-add` suffices) before `nix build` can find them.
- Update mechanics live with each package: a custom updater is an executable
  `update.sh` beside its `package.nix` (see `ttn-lw-cli-bin`); packages using
  standard fetchers instead declare `passthru.updateScript =
  nix-update-script { }` and are handled by nix-update. `just update` runs
  whichever exists, skipping packages with neither.
- Binary repackages are separate `<name>-bin` packages with
  `meta.sourceProvenance = [ lib.sourceTypes.binaryNativeCode ]`.

## Key facts

- nixpkgs is pinned to `nixos-26.05` deliberately — the last release
  supporting x86_64-darwin, which is a supported platform here. Don't change
  the branch; bump the pin only via `just update-nixpkgs`. Consumers who want
  a different base use `inputs.nixpkgs-jv.inputs.nixpkgs.follows`.
- `flake.nix` imports nixpkgs directly (not `legacyPackages`) to pass
  `config.allowDeprecatedx86_64Darwin = true`, silencing the 26.05
  deprecation warning.
- Systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin. The
  `packages` output filters per system by `meta.platforms`.
- `nix flake check --all-systems` builds and tests current-system packages
  only; other systems get evaluation checks. Full build coverage of all
  platforms requires per-platform builders (CI).
- nix-update rewrites `flake.lock` as an eval side effect; `just update`
  reverts that so nixpkgs bumps stay deliberate.

## Commands

Everything routine is in the justfile: `just list`, `just update [name...]`,
`just update-nixpkgs`, `just build <pkg>`, `just run <pkg> [args...]`,
`just check`, `just fmt`. Before finishing work: `nix fmt`, `just check`, and
actually run any package you touched (`just run <pkg> version` or similar).
