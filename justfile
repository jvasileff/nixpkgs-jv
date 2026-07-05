# Show available recipes
default:
    @just --list

# List the packages this flake provides for the current system
list:
    @nix eval --raw ".#packages.$(nix config show system)" --apply 'ps: builtins.concatStringsSep "\n" (map (name: "${name} (${ps.${name}.version or "?"})") (builtins.attrNames ps)) + "\n"'

# Per-package update knowledge lives with the package, not here:
# a package with a custom updater ships an update.sh next to its package.nix;
# anything else that declares passthru.updateScript is handled by nix-update;
# packages with neither are skipped.
# Update packages to their latest upstream releases, e.g. `just update [name...]` (all by default)
update *names:
    #!/usr/bin/env bash
    set -euo pipefail
    names="{{ names }}"
    [ -n "$names" ] || names=$(basename -a pkgs/by-name/*/*/)
    for name in $names; do
        matches=(pkgs/by-name/*/"$name")
        dir="${matches[0]}"
        if [ ! -d "$dir" ]; then
            echo "error: no package named '$name' under pkgs/by-name" >&2
            exit 1
        fi
        if [ -x "$dir/update.sh" ]; then
            echo "==> $name (update.sh)"
            "$dir/update.sh"
        elif nix eval ".#$name.updateScript" --apply 'x: true' >/dev/null 2>&1; then
            echo "==> $name (nix-update)"
            nix run nixpkgs#nix-update -- --flake "$name"
            # nix-update touches the lock as a side effect;
            # nixpkgs bumps stay deliberate (`just update-nixpkgs`)
            git checkout -- flake.lock
        else
            echo "==> $name: no update script, skipping"
        fi
    done

# Update the nixpkgs pin in flake.lock (toolchain/stdenv, not package versions)
update-nixpkgs:
    nix flake update

# Build one package, e.g. `just build ttn-lw-cli`
build pkg:
    nix build .#{{ pkg }}

# Run a package's main program, e.g. `just run ttn-lw-cli version`
run pkg *args:
    nix run .#{{ pkg }} -- {{ args }}

# Build and test every package (per-package checks run at build time)
check:
    nix flake check

# Format nix files
fmt:
    nix fmt
