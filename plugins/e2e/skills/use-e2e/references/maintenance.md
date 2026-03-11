# Maintenance

## Purpose
Use this guide for request intake, publishing, deployment, release hygiene, and day-2 operations.

## Request Handling
Use this format when intake arrives as "please update the e2ectl skills repo" or "use the skill to manage nodes" without enough detail.

### Required Request Fields
- repo or workspace path
- requested action (`setup`, `deploy`, `configure`, `operate`, `publish`, `node-list`, `node-create`, `node-delete`, or `fix`)
- target install surface (`codex`, `claude`, or `both`)
- expected command or user-facing outcome
- urgency and impact

### Change Request Template
```text
Title:
Repo/Workspace:
Request Type:
Requested Change:
Reason:
Install Target:
Validation Plan:
Rollback Plan:
Requested By:
Needed By:
```

### Incident Request Template
```text
Title:
Detected At (UTC):
Affecting Path or Script:
User Impact:
Observed Symptoms:
Most Recent Changes:
Current Mitigation:
Requested Support:
```

### Completion Checklist
- scope confirmed
- change applied
- validation evidence captured
- rollback readiness confirmed
- requester updated

## Standard Deploy Flow
1. Confirm the CLI release target: npm package name, version, and tag.
2. Publish the `e2ectl` CLI first.
3. Smoke-test CLI installation in a clean shell.
4. Validate changed skill scripts and docs locally.
5. Push the skills repo to GitHub.
6. Tag a release after the installer and repo layout are stable.
7. Smoke-test skill installation from another repo or clean shell.

## CLI-Oriented Commands
```bash
git status
git tag v0.1.0
./scripts/install.sh --target all --repo-dir .
```

## Release Order
- Publish the CLI to npm before updating skills that depend on the released command shape.
- Verify the published CLI can be installed and run in a separate environment.
- Then update and release the skills repo that agents will install.

## Pre-Deploy Checks
- plugin manifest path matches the real skill path
- install targets use `plugins/e2e` and `use-e2e`
- docs explain that skill installation and CLI installation are separate steps
- publish docs reference the current GitHub repository name

## Post-Deploy Checks
- the published CLI installs and responds to `--help`
- raw installer URL downloads successfully
- local `curl | bash` install places files in the expected directories
- another repo can install the skill pack into Codex or Claude successfully
- Codex and Claude targets contain the updated plugin/skill files

## Rollback Guidance
- If the CLI release breaks installation or command shape, roll back or deprecate the bad npm version first.
- If the skill release breaks installation, restore the previous tag or commit immediately.
- Re-run the CLI and installer smoke tests against the rollback target.
- Capture the failed command, bad revision, and mitigation in release notes or incident notes.

## Goal
Maintain a stable `e2ectl` workflow for CLI readiness, configuration, agent skill installation, and safe node operations.

## Day-2 Runbook
1. Verify `e2ectl` is installed and responds to `--help`.
2. Verify configuration with `e2ectl config list`.
3. Install or refresh the skill pack in the target agent environment if needed.
4. Run safe smoke tests such as `node list` before destructive changes.
5. Confirm delete operations are explicitly approved.
6. Record regressions, unresolved gaps, and rollback targets.

## Common Commands
```bash
bash -n scripts/install.sh
./scripts/install.sh --help
./plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh -- --help
e2ectl config list
e2ectl node list --json
```

## Safe Operation Order
- verify CLI
- verify config
- install or refresh skills when moving to another repo or machine
- list nodes before create or delete
- confirm delete explicitly

## Incident Triage
- Confirm blast radius: CLI install, CLI auth/config, skill installer, or node operation flow.
- Identify the most recent risky change to npm publish, tokens, paths, script names, or repo URLs.
- Apply the fastest safe mitigation first: restore CLI availability, restore a working profile, revert the bad revision, or fix the public installer URL.
- Communicate the failing command, expected result, and current mitigation clearly.

## Reliability Practices
- Keep CLI publish and skills publish as separate validated stages.
- Re-verify config before running create or delete commands.
- Keep a known-good tag that has a verified installer.
- Re-run smoke tests before and after releases.
- Convert repeated install or docs failures into script checks or runbook updates.
