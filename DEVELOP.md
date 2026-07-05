# Development

## GitHub setup

The workflows in `.github/workflows/` run entirely on the default
`GITHUB_TOKEN` — no PAT or other secret to create or rotate. Two one-time
pieces of repo configuration are needed. Everything else works out of the
box on a public repo (public = free ARM and macOS runners).

### 1. Allow Actions to create PRs (required by the update workflow)

Settings → Actions → General → Workflow permissions: enable **Allow
GitHub Actions to create and approve pull requests**. Without it,
`gh pr create` with the default `GITHUB_TOKEN` fails.

### 2. Branch ruleset on `main` (required checks)

Settings → Rules → Rulesets → New branch ruleset:

- Enforcement status: Active. Target: the default branch.
- Enable *Require status checks to pass* and add all four:
  - `check (x86_64-linux)`
  - `check (aarch64-linux)`
  - `check (x86_64-darwin)`
  - `check (aarch64-darwin)`
- Leave the bypass list empty so the rule binds administrators too;
  otherwise it is advisory.

Required-check matching is by name: these must stay in sync with the job
names in `.github/workflows/check.yml` (pinned there as
`check (${{ matrix.system }})`). Renaming the job or a matrix `system`
entry silently orphans the rule.

## Weekly update PRs

The update workflow (Monday cron, or Actions → update → Run workflow)
force-pushes `auto-update` and opens a PR if none is open. PRs created
with `GITHUB_TOKEN` get their `pull_request` runs in an
*approval-required* state (GitHub behavior since June 2026):

- Click **Approve workflows to run** in the PR's merge box to start the
  checks; merge when green.
- Each force-push (e.g. a rerun of the update workflow) needs the click
  again.
- Runs left unapproved for more than 30 days are deleted automatically.

Removing the click (auto-dispatching the checks) and auto-merge are
possible follow-ups — see [TODO.md](TODO.md).

## Testing the automation

Never rehearse on `main`. The update workflow targets whatever branch it
was dispatched on (cron only ever runs on the default branch, so a test
branch is manual-only by construction):

1. Create a test branch with something stale for the updater to find:
   `git switch -c automation-test main`, set an old version/hash in some
   `package.nix` (or revert a previous update commit), push the branch.
2. `gh workflow run update --ref automation-test`. The run should update
   the stale package, push `auto-update-automation-test`, and open a PR
   based on `automation-test` — `main` is never touched.
3. On the PR: click "Approve workflows to run" and watch the four checks.
   Dispatch again to confirm a rerun force-pushes into the same PR.
4. Clean up: close the PR, delete `auto-update-automation-test` and
   `automation-test`.
