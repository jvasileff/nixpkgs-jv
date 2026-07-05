#!/usr/bin/env bash
# Updates ttn-lw-cli-bin to the latest upstream release: bumps the version
# and refreshes every per-platform hash from the release's checksums.txt.
set -euo pipefail

package_nix="$(dirname "$0")/package.nix"

tag=$(curl -fsSL https://api.github.com/repos/TheThingsNetwork/lorawan-stack/releases/latest |
  sed -nE 's/^ *"tag_name": *"([^"]+)".*/\1/p')
version=${tag#v}

current=$(sed -nE 's/^ *version = "([^"]+)";.*/\1/p' "$package_nix")
if [[ $version == "$current" ]]; then
  echo "ttn-lw-cli-bin is already at $version"
  exit 0
fi

echo "updating ttn-lw-cli-bin: $current -> $version"

checksums=$(curl -fsSL "https://github.com/TheThingsNetwork/lorawan-stack/releases/download/${tag}/lorawan-stack_${version}_checksums.txt")

sed -i -E "s|(version = \")[^\"]+|\1${version}|" "$package_nix"

for suffix in linux_amd64 linux_arm64 darwin_amd64 darwin_arm64; do
  hex=$(grep "lorawan-stack-cli_${version}_${suffix}.tar.gz" <<<"$checksums" | cut -d' ' -f1)
  sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  # suffix and hash are on separate lines: anchor on the suffix line,
  # then edit the hash on the line that follows it.
  sed -i -E "/suffix = \"${suffix}\";/{n;s|(hash = \")[^\"]+|\1${sri}|;}" "$package_nix"
done

echo "done; verify with: nix build .#ttn-lw-cli-bin"
