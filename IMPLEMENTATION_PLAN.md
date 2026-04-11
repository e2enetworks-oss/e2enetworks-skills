# E2E Networks Skills Productionization Plan

## Goal

Make branch `intial-setup` production-ready for public users by turning the existing installer into the single public setup path for both:

- the `use-e2e` skill
- the published CLI `@e2enetworks-oss/e2ectl`

The product should feel like one installable experience:

1. run the installer
2. get the skill
3. get `e2ectl`
4. rerun the installer later to update

## Locked Decisions

- Public mode is the default everywhere.
- Internal mode exists only as a hidden escape hatch.
- Public docs must not mention `develop`, `hitesh-test`, or repo-clone testing flows.
- Re-running the installer updates the skill pack.
- The installer preserves the ability to install the skill from a non-default skills repo branch when the user explicitly chooses that source.
- If no alternate source is specified, the installer uses the official main repo.
- In interactive installs, if a newer stable `e2ectl` is already installed, ask whether to upgrade it.
- In non-interactive installs, do not prompt. Install missing `e2ectl`, and only upgrade automatically when explicitly requested by flag.
- Runtime must never silently install or upgrade the CLI.

## Verified Current Problems

1. `scripts/install.sh` breaks the documented `curl | bash` flow because non-interactive installs fail when `--scope` is omitted.
2. `plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh` checks for package name `e2ectl`, not `@e2enetworks-oss/e2ectl`, so it can miss the intended repo checkout.
3. Public docs still describe pre-release behavior: `develop` checkout first, `hitesh-test` fallback, and repo-first testing.
4. `tests/regression.sh` encodes that same pre-release contract, so code and docs cannot be productionized without changing the regression contract.
5. The repo has no clean public story for installing and updating `e2ectl` alongside the skill.

## Public Product Contract

### Public installation

Public users should use one script.

```text
installer
   |
   +--> install skill globally by default
   |
   +--> ensure global e2ectl exists
   |
   +--> if interactive and newer stable e2ectl exists:
   |       ask whether to upgrade
   |
   +--> print "rerun installer to update"
```

### Public update story

- Skills update: rerun installer.
- CLI update: rerun installer.
- Runtime fallback message when CLI is too old: rerun installer.

### Internal mode

Internal mode remains hidden:

- enabled only by env var or hidden flag
- may use local repo checkout / `develop`
- never documented in `README.md`

## Runtime Resolution Design

### Public mode

```text
explicit --bin
   |
   +--> yes: use it
   |
   +--> no:
         |
         +--> installed e2ectl present? ---------> use it
         |
         +--> not installed ---------------------> fail with rerun-installer guidance
```

### Internal mode

```text
explicit --bin
   |
   +--> yes: use it
   |
   +--> no:
         |
         +--> valid local e2ectl checkout? yes --> use dist/app/index.js
         |
         +--> installed e2ectl present? ---- yes --> use it
         |
         +--> otherwise -------------------------> fail with internal bootstrap guidance
```

## Installer Design

### Source resolution

The installer keeps one script, but supports both public and advanced source selection.

Default:

- official repo
- default branch behavior from that source

Advanced:

- explicit `--repo-url`
- explicit `--repo-dir`
- explicit `--repo-ref <branch|tag|commit>` for users who want another remote skills repo branch or ref

The default user path should still be one command from the official repo.

Installer runs are stateless:

- do not persist repo URL or repo ref metadata across runs
- each run uses the source inputs passed on that run
- if no advanced source is passed, default back to the official repo and default branch

### Scope behavior

Interactive:

- ask `global` vs `project`
- recommend `global`

Non-interactive:

- default to `global`

Scope affects where the skill is installed.

It does not change the default CLI policy:

- `e2ectl` is installed globally by default
- `project` scope still installs or upgrades global `e2ectl`
- `--skip-cli` remains the explicit escape hatch

### CLI lifecycle

Installer owns CLI install and upgrade logic.

Behavior:

- if `e2ectl` is missing:
  - install `@e2enetworks-oss/e2ectl@latest` globally
- if `e2ectl` is installed:
  - compare installed version with npm `latest`
  - interactive mode: ask whether to upgrade when newer stable exists
  - non-interactive mode: upgrade only when a dedicated flag is passed
  - if npm version lookup fails but `e2ectl` is already installed, warn and continue

Default installer behavior is fail-closed:

- if skill install succeeds but required CLI install or upgrade fails, exit non-zero
- do not leave the default public flow in a half-installed state
- `--skip-cli` is the explicit opt-out that allows skill-only installation

Recommended flags:

- `--skip-cli`
- `--upgrade-cli`
- `--no-upgrade-cli`

## Planned Changes

### Commit 1

`fix: make installer and public cli resolution reliable`

Files:

- `scripts/install.sh`
- `plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh`
- `tests/regression.sh`

Changes:

- fix non-interactive installer default scope
- fix repo detection bug in the wrapper
- make public mode the default
- hide internal mode behind env or hidden flag
- remove `hitesh-test` from public resolution
- add the new installer control flow and source-selection contract, excluding npm CLI lifecycle logic
- update regression coverage for the new public default behavior

### Commit 2

`feat: install and upgrade e2ectl from installer`

Files:

- `scripts/install.sh`
- `plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh`
- `tests/regression.sh`

Changes:

- install global `@e2enetworks-oss/e2ectl` by default
- detect installed CLI version
- detect npm latest stable version
- prompt for CLI upgrade in interactive mode
- support explicit non-interactive upgrade flag
- own all npm CLI lifecycle behavior in this commit only
- add regression coverage for missing, stale, and current CLI cases

### Commit 3

`docs: productionize public readme and local release checks`

Files:

- `README.md`
- `AGENTS.md`
- `plugins/e2e/skills/use-e2e/SKILL.md`
- `plugins/e2e/skills/use-e2e/references/access.md`
- `plugins/e2e/skills/use-e2e/references/maintenance.md`
- `tests/regression.sh`

Changes:

- rewrite public docs around the shipped npm CLI
- document rerun-installer update flow
- remove public references to `develop`, repo-first testing, and `hitesh-test`
- keep internal instructions only in maintainer-facing docs
- document local release checks instead of CI

## What Already Exists

- `scripts/install.sh` already handles target selection, source repo resolution, and global vs project skill installs.
- `e2ectl-run.sh` already handles explicit binaries, cwd-aware execution, env file loading, and output capture.
- `tests/regression.sh` already acts as a local release gate for installer and wrapper behavior.
- `SKILL.md` plus the references folder already separate routing from workflow details.

The plan reuses those pieces instead of introducing a second installer, a second wrapper, or a separate update script.

## Documentation Ownership

- `README.md` is the only public source for install, update, and supported environments.
- `plugins/e2e/skills/use-e2e/SKILL.md` is the source of truth for runtime behavior.
- `AGENTS.md` is maintainer-facing and may document hidden internal behavior.
- `references/` files document task workflows only, not product install policy.

## Verification Plan

### Local release checks

Run:

```bash
bash tests/regression.sh
```

### Installer smoke checks

Run:

```bash
bash scripts/install.sh --repo-dir . --target claude --scope global --claude-home /tmp/e2e-skills-claude --force
```

Run again to verify update behavior:

```bash
bash scripts/install.sh --repo-dir . --target claude --scope global --claude-home /tmp/e2e-skills-claude --force
```

### Public runtime smoke checks

Verify:

- public mode prefers installed `e2ectl`
- public mode fails cleanly if `e2ectl` is missing
- explicit `--bin` still overrides resolution

### Internal runtime smoke checks

Verify:

- internal mode can use a valid local repo checkout
- internal mode still falls back to installed `e2ectl`

### Required regression coverage expansion

`tests/regression.sh` must be extended to cover:

- non-interactive install defaulting to global scope
- public installer path installing the skill and global `e2ectl`
- interactive CLI upgrade prompt accepted
- interactive CLI upgrade prompt declined
- npm lookup failure with an already-installed CLI
- fail-closed behavior when required CLI install or upgrade fails
- `--skip-cli`
- `--repo-ref` branch fixture
- `--repo-ref` tag fixture
- `--repo-ref` commit fixture
- public wrapper resolution using installed `e2ectl`
- public wrapper missing-CLI guidance
- internal wrapper resolution using a local repo checkout
- internal wrapper fallback to installed `e2ectl`

Interactive coverage should use `expect` or `script`, not manual release notes.

Advanced source coverage should use local temporary git fixtures, not network-dependent branch tests.

Installer regression coverage should stub:

- `npm view`
- `npm install -g`
- `e2ectl --version`

using PATH-based command fixtures, while keeping `--repo-ref` coverage on real local temporary git repositories.

## Failure Modes To Cover

- installer still fails in piped non-interactive mode
- installer installs skill but skips CLI silently
- installer upgrades CLI when the user declined in interactive mode
- wrapper silently uses the wrong binary
- CLI upgrade detection misreports current vs latest version
- public docs drift back toward internal testing instructions

## NOT in Scope

- Hosted CI or GitHub Actions.
- Browser-based auth or new secret-entry UX.
- New skill surfaces beyond `use-e2e`.
- Support for `hitesh-test`.
- Reworking the entire resource workflow vocabulary.

## Worktree Parallelization

Sequential implementation, no parallelization opportunity.

Why:

- installer behavior, runtime resolution, docs, and regression tests all depend on the same public contract and touch the same boundary.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 27 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **UNRESOLVED:** 0
- **VERDICT:** ENG CLEARED — ready to implement
