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

## Consider later: auto-merge

Only worthwhile after the above — with the approval click still required,
a human is already on the PR, and auto-merge would save one click while
costing review. Native auto-merge (`gh pr merge --auto --rebase` after
`gh pr create`, plus enabling "Allow auto-merge" in repo settings) merges
when the required checks pass. Decide first whether unreviewed upstream
version/hash bumps landing on main is acceptable for a package flake;
splitting update PRs per package would make that call easier.
