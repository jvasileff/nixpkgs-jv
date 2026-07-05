# TODO

## GitHub Actions: automated update PRs + multi-platform tests

Two workflows:

1. **update** (weekly cron + manual dispatch): run
   `just update update-nixpkgs` — packages and nixpkgs pin together, one
   PR. If there are changes, commit and
   `git push --force` to a fixed `auto-update` branch (force-push so reruns
   replace stale PRs; a push to a branch with an open PR updates that PR),
   then `gh pr create` if none exists (`gh` is preinstalled on runners).
   Open the PR *before* tests pass — failures should surface as a red PR,
   not vanish in the Actions tab.
   Gotcha: pushes made with the default `GITHUB_TOKEN` do not trigger other
   workflows (anti-recursion rule), so the PR would get no checks — push
   with a fine-grained repo-scoped PAT stored as a secret instead.
2. **check** (on `pull_request` and push to main): matrix of `just check`
   per platform. Runners: `ubuntu-latest` (x86_64-linux),
   `ubuntu-24.04-arm` (aarch64-linux), `macos-15` (aarch64-darwin).
   x86_64-darwin runs on an ARM runner via Rosetta: `extra-platforms =
   x86_64-darwin` is a *daemon* setting (append to /etc/nix/nix.conf and
   restart the daemon — not a client flag unless the user is trusted), and
   Rosetta must be present (`softwareupdate --install-rosetta`; verify
   whether GitHub's macOS images preinstall it). Fallback: eval-only
   coverage (`--all-systems` already gives that everywhere).

Then: branch ruleset on the default branch requiring the matrix checks
(stable job names — required-check matching is by name; include
administrators or the rule is advisory).

Decisions:

- Repo is public (free ARM/macOS runners).
- No third-party actions. First-party `actions/*` (checkout) is fine; PR
  creation is plain `git push` + `gh pr create`; Nix comes from the official
  installer: `curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes`
  with `NIX_CONFIG: experimental-features = nix-command flakes` in the env
  (slower than the wrapper actions by ~a minute; acceptable).
- `just` via `nix run nixpkgs#just` or the dev shell.
