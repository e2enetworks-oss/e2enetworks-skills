# Access

## Purpose
Bootstrap the CLI and the `e2e-skills` repo so later node execution, agent installation, and publishing tasks are predictable.

## Scope
Use this guide for CLI profiles, agent install targets, shell environment, and publish-time configuration.

## Prerequisites
- npm and shell access to install `e2ectl` when needed
- shell with `bash`, `git`, and core Unix utilities
- this `e2e-skills` repo for installer-driven agent setup

## Start Here: Verify the CLI
1. Check whether `e2ectl` is already available:
```bash
command -v e2ectl
e2ectl --help
```
2. Verify version or command surface:
```bash
e2ectl version || e2ectl --version
```
3. Verify saved configuration:
```bash
e2ectl config list
```

If these commands work, proceed with node actions or skill installation.

## If the CLI Is Missing
- Install the CLI and continue with the workflow.
- Use npm as the default install path.
- For now, use `e2ectl` as the placeholder npm package name.
- Preferred placeholder install command:
```bash
npm i -g e2ectl
```
- If the environment prefers local package installs:
```bash
npm i e2ectl
npx e2ectl --help
```
- After install, verify again:
```bash
command -v e2ectl
e2ectl --help
```

## Environment Variables
- Prefer `CODEX_HOME` and `CLAUDE_HOME` overrides only when the default homes are wrong for the target machine.
- Keep secrets outside this repo; do not hardcode tokens in scripts or docs.
- Use shell-compatible env files when invoking `scripts/e2ectl-run.sh --env-file ...`.

## CLI Profiles
- Verify access first with `e2ectl config list`.
- `e2ectl` stores saved profiles in `~/.e2e/config.json`.
- Add or update profiles with `e2ectl config add`.
- If saved profiles already exist, ask whether to use an existing profile or add/import a new one before prompting for new credentials.
- If the user chooses an existing profile, prefer `e2ectl config set-default --alias <alias>` to select it.
- If the chosen profile exists but is missing `default_project_id` or `default_location`, prompt for the missing context fields and save them with `e2ectl config set-context`.
- Prefer `e2ectl config import --file <path>` when the user already has a downloaded credential JSON file.
- Keep at least one known-good default profile for list/create/delete node workflows.
- Re-check configuration after switching machines, shells, or tokens.
- If no usable saved profile exists, prompt for all fields needed for a usable default profile before running any node command:
  - alias
  - api key
  - auth token
  - default project id
  - default location
- If a command fails with auth or configuration errors, prompt for the same full field set again.

## Configure Access
If the user provides a downloaded credential file, prefer importing it instead of reading and echoing secret fields manually:
```bash
e2ectl config import \
  --file <path-to-credential-json> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai> \
  --default <alias>
```

If `e2ectl config list` shows existing saved aliases, ask:
```text
Saved e2ectl profiles already exist. Do you want to use an existing profile or add/import a new one?
```

If the user picks an existing alias and it should become the default:
```bash
e2ectl config set-default --alias <alias>
```

If the selected alias is missing project or location defaults:
```bash
e2ectl config set-context \
  --alias <alias> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai>
```

If `e2ectl config list` shows no usable profile, prompt for every field needed for a usable default profile:
- alias
- api key
- auth token
- default project id
- default location

Do not assume defaults and do not proceed to node commands until all five values are provided.

Then add the profile:
```bash
e2ectl config add \
  --alias <alias> \
  --api-key <api-key> \
  --auth-token <bearer-token> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai>
```

Prompt template:
```text
No usable e2ectl profile is configured. Please provide all required fields:
1. Alias
2. API key
3. Auth token
4. Default Project ID
5. Default Location (Delhi or Chennai)
```

## Required Prompt Behavior
- Do not assume `default` as the alias unless the user explicitly chooses it.
- Do not assume a location.
- Do not ask for new API credentials if `e2ectl config list` already shows usable saved profiles.
- Ask whether to use an existing profile or add/import a new one.
- If an existing profile is selected but missing context defaults, ask for the missing project/location values and update the profile instead of creating a new one.
- Do not ask for only one missing value; request the full required set together when configuration is unusable.
- Do not continue to `node list`, `node create`, `node get`, or `node delete` until configuration is present.
- Do not expose API keys, bearer tokens, or raw credential file contents in user-facing output.

## Secret Handling
- Never paste the auth token or API key back into user-facing output.
- Never dump the contents of a credential JSON file back to the user.
- Prefer masked `e2ectl config list` output for verification.

## Recommended Commands
Import from a credential file:
```bash
e2ectl config import \
  --file <path> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai> \
  --default <alias>
```

Add a profile manually:
```bash
e2ectl config add \
  --alias <alias> \
  --api-key <api-key> \
  --auth-token <auth-token> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai>
```

Use an existing profile:
```bash
e2ectl config set-default --alias <alias>
```

Update project/location defaults on an existing profile:
```bash
e2ectl config set-context \
  --alias <alias> \
  --default-project-id <project-id> \
  --default-location <Delhi|Chennai>
```

## Install Targets
- Codex target: `~/.codex/skills/use-e2e`
- Claude target: `~/.claude/plugins/e2e`
- Keep the installer, RFC, and plugin manifest aligned on these paths.
- Remember: the skill installer installs the skill pack only. If `e2ectl` is missing, install it first with npm or during setup.

## Bootstrap Checklist
1. Confirm the installer wiring:
```bash
./scripts/install.sh --help
```
2. Install the skill pack into the target agent environment:
```bash
./scripts/install.sh --target all --repo-dir .
```
3. Confirm the packaged files are present:
```bash
find plugins -maxdepth 5 -type f | sort
```

## Runner Configuration
- Override the binary path with `--bin` when `e2ectl` is not on `PATH`.
- Use `--cwd` when the command must run from a specific repo root.
- Use `--output` for repeatable logs during smoke tests and release validation.

## Change Safety
- Make one path or installer change at a time.
- Record the final public install command after each docs update.
- Validate immediately with `--help` or a smoke-test command.

## Baseline Conventions
- Keep the repo name stable as `e2e-skills`
- Keep plugin path and installer path in sync
- Treat CLI installation and skill installation as separate steps
- Prefer explicit `--help` and smoke-test validation before publishing
- Version tags should map to a tested installer and skill layout

## Verification Checklist
- CLI is installed separately and responds to `e2ectl --help`
- saved profiles are checked first via `e2ectl config list`
- CLI profile setup is usable for the intended project and location
- installer help text matches the current repo layout
- install script still resolves the plugin and skill source directories
- helper script runs with `--help`
- plugin and skill directories exist under `plugins/e2e`
- published docs reference the same repo and install paths as the code
- secrets are not printed in summaries, prompts, or copied shell commands
