# TODO

- Do the one-time GitHub setup for the Actions workflows (Actions PR
  setting, branch ruleset) — steps in [DEVELOP.md](DEVELOP.md).

## Explore: auto-trigger checks on the update PR

Today the weekly PR's checks need an "Approve workflows to run" click.
`workflow_dispatch` events are exempt from the GITHUB_TOKEN anti-recursion
rule, so the update workflow could start them itself: add
`workflow_dispatch:` to check.yml (must land on main first — dispatch 404s
until the trigger exists on the default branch), give update.yml
`actions: write`, and `gh workflow run check.yml --ref auto-update` after
the push (re-dispatch after every push). Caveats: the run builds the
branch head, not the `refs/pull/N/merge` merge ref (fine here — the branch
is recreated from fresh main weekly), and it satisfies the ruleset because
required-check matching is by check-run name on the head SHA, regardless
of triggering event. Alternative if merge-ref runs ever matter: a GitHub
App + first-party `actions/create-github-app-token` (private keys don't
expire, unlike PATs).

## Consider later: binary cache

Adopt when CI wall-clock (the Rosetta job especially) or from-source
installs on consumer machines start to annoy. Solves two problems: CI
rebuilds only what changed, and machines substitute prebuilt binaries
instead of compiling. Public-read is fine — integrity comes from Nix
signatures (private signing key in Actions secrets, public key in README
and `trusted-public-keys`), not access control. Mechanically it's
additive: a `nix copy` push step after builds, a substituter line for
readers. A cache is disposable (miss = rebuild), so blunt age-based
cleanup is enough.

Options:

- **Cloudflare R2** (leaning): S3-compatible, so plain
  `nix copy --to 's3://...?endpoint=<account>.r2.cloudflarestorage.com'`.
  Egress free at any volume; storage 10 GB free then $0.015/GB-month
  (100 GB ≈ $1.35/mo). Reads need a custom domain on a Cloudflare zone —
  `r2.dev` URLs are rate-limited, dev-only. GC via bucket lifecycle rule
  (e.g. delete objects older than 180 days). Secrets: R2 API token +
  signing key.
- **S3 proper**: same tooling, but ~$0.09/GB egress is the wrong shape
  for a download-heavy cache.
- **Cachix**: zero infra, free 5 GB public tier, manages keys and
  eviction. CLI is in nixpkgs (`nix run nixpkgs#cachix -- push`), so no
  third-party action needed. Secrets: `CACHIX_AUTH_TOKEN`. Cost: reliance
  on a niche service's free plan.

## Consider later: auto-merge

Only worthwhile once the update PR's checks start without manual
approval (see "Explore: auto-trigger checks on the update PR") — while
the approval click is still required, a human is already on the PR, and
auto-merge would save one click while costing review. Native auto-merge (`gh pr merge --auto --rebase` after
`gh pr create`, plus enabling "Allow auto-merge" in repo settings) merges
when the required checks pass. Decide first whether unreviewed upstream
version/hash bumps landing on main is acceptable for a package flake;
splitting update PRs per package would make that call easier.
