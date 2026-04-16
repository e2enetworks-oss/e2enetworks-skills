# PR Review Notes

Date: 2026-03-19

Scope:
- `plugins/e2e/skills/use-e2e-cloud/scripts/e2ectl-run.sh`
- `plugins/e2e/.claude-plugin/plugin.json`

Official repo:
- `https://github.com/e2enetworks-oss/e2enetworks-skills`

Review context:
- base branch: `origin/main` (`fa19561cda89c2bc4d7d3f7d3897b854ab17ea34`)
- review branch: `intial-setup` (`6ed2fe6`)
- both flagged files are newly added by this PR and do not exist on `origin/main`

## Summary

The review found four issues in the current PR:
- 3 x `P2`
- 1 x `P3`

The main problems are in `e2ectl-run.sh`: local project installs are not resolved correctly, relative env files break when `--cwd` is used, and env-file load failures do not stop execution. The Claude plugin metadata also still points to a placeholder repository URL.

## Official Repo Study

Comparison against the official repository shows:
- `origin` in this local clone points to `https://github.com/e2enetworks-oss/e2enetworks-skills.git`
- the official `main` branch is still at the initial commit
- this PR introduces the runner script and plugin metadata for the first time
- the review comments therefore apply to newly introduced behavior in this branch, not to legacy code already present on `main`

The review is also consistent with repository documentation:
- `plugins/e2e/skills/use-e2e-cloud/SKILL.md` documents project-local install via `npm i hitesh-test` and says later commands should use `npx hitesh-test`
- `plugins/e2e/skills/use-e2e-cloud/references/access.md` repeats that project-local usage path
- `rfc.md` explicitly says the placeholder repository URL must be replaced before release

## Findings

### 1. P2: Support project-local CLI installs in `e2ectl-run.sh`

File:
- `plugins/e2e/skills/use-e2e-cloud/scripts/e2ectl-run.sh:36-43`

Problem:
- `resolve_default_bin()` only checks the current `PATH`.
- It does not look for a project-local install under `--cwd`, such as `node_modules/.bin/hitesh-test`.

Impact:
- A documented install flow like `npm i hitesh-test` inside a project leaves the CLI available through `npx hitesh-test` or `node_modules/.bin/hitesh-test`.
- In that setup, `e2ectl-run.sh --cwd <project> -- ...` can fail with `binary not found` even though the CLI is installed locally.

Suggested fix:
- When `--cwd` is set, probe the local bin directory under that project before failing.
- At minimum, check:
  - `<cwd>/node_modules/.bin/hitesh-test`
  - `<cwd>/node_modules/.bin/e2ectl`

### 2. P2: Resolve `--env-file` before changing into `--cwd`

File:
- `plugins/e2e/skills/use-e2e-cloud/scripts/e2ectl-run.sh:122-125`

Problem:
- A relative `--env-file` path is validated before `cd "$cwd"`, but it is sourced only after changing directories.
- That means the script can validate one file and later try to source a different path.

Impact:
- A call like `--env-file ./envfile --cwd /tmp/work` can validate `./envfile` in the original directory, then try to source `/tmp/work/envfile`.
- The wrapped command can then run without the requested environment.

Suggested fix:
- Normalize `--env-file` to an absolute path before changing directories.
- Source the resolved path instead of the original relative input.

### 3. P2: Abort when loading the env file fails

File:
- `plugins/e2e/skills/use-e2e-cloud/scripts/e2ectl-run.sh:132-134`

Problem:
- The `runner` function executes while the outer script is under `set +e`.
- If the env file is bad or unreadable at source time, the shell can print an error and still continue to the wrapped CLI command.

Impact:
- A typo or broken env file can still produce exit code `0` if the CLI command succeeds.
- Missing credentials or context may look like a successful run.

Suggested fix:
- Fail fast if sourcing the env file returns non-zero.
- Keep env loading and command execution as separate error boundaries so env setup failures cannot be masked by later command success.

### 4. P3: Replace the placeholder repository URL in plugin metadata

File:
- `plugins/e2e/.claude-plugin/plugin.json:5`

Problem:
- The plugin still advertises `https://github.com/REPLACE_ME/e2e-skills`.

Impact:
- Any UI or tooling that reads repository metadata will point users at a dead source URL.
- The RFC already calls out replacing this value before release.

Suggested fix:
- Replace the placeholder with the actual GitHub repository URL before shipping.

## Recommended Next Steps

1. Patch `e2ectl-run.sh` to resolve local project installs from `--cwd`.
2. Resolve `--env-file` to an absolute path before any `cd`.
3. Make env-file load failures exit non-zero before running the CLI.
4. Replace the placeholder repository URL in `plugins/e2e/.claude-plugin/plugin.json`.
