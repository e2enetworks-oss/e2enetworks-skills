---
name: use-e2e
description: Verify, install, and configure the e2ectl CLI; install this skill pack into agents; and use e2ectl to list, create, get details for, and delete E2E Networks nodes. Also use when publishing the CLI to npm or wiring the skill into another repo.
---

# E2ECTL Skill Workflow

1. Always start with CLI readiness:
- run `command -v e2ectl`
- run `e2ectl --help`
- if the CLI is missing, install it before doing anything else
- use npm as the default install path
- for now, use `e2ectl` as the placeholder npm package name
- preferred placeholder install command:
  - `npm i -g e2ectl`
- if the environment uses local project packages instead of global installs:
  - `npm i e2ectl`
  - `npx e2ectl --help`
- after install, verify again with `command -v e2ectl` and `e2ectl --help`

2. Ensure configuration is usable before node operations:
- run `e2ectl config list`
- remember that saved profiles live in `~/.e2e/config.json`
- if one or more saved profiles exist, do not prompt for API credentials first
- ask whether to use an existing profile or add/import a new one
- if the user chooses an existing profile:
  - use `e2ectl config set-default --alias <alias>` when that alias should become the default
  - if the alias is missing default project id or default location, prompt for only the missing context values and save them with `e2ectl config set-context`
- if the user provides a downloaded credential JSON file path, prefer:
  - `e2ectl config import --file <path> --default-project-id <project-id> --default-location <location> --default <alias>`
  - then verify with `e2ectl config list`
- if no usable profile exists and no import file is available, prompt for every field needed for a usable default profile and do not continue until all are provided:
  - alias
  - api key
  - auth token
  - default project id
  - default location
- then run `e2ectl config add ...`
- if a node command returns an auth or configuration error, stop and prompt for the same full field set again instead of guessing
- never echo secrets, credential file contents, auth tokens, or API keys back to the user

3. Install the skill pack into the target agent environment when needed:
- use `./scripts/install.sh --target codex|claude|all --repo-dir .`
- remember that this installer deploys the skill pack only; if `e2ectl` is missing, install it with npm first or during setup

4. Load only the reference file needed for the current request:
- access, configuration, and installer setup: `references/access.md`
- node list/get/create/delete workflows: `references/nodes.md`
- deploy, operate, publish, and request handling: `references/maintenance.md`

5. Prefer deterministic commands:
- inspect `e2ectl --help` or local project scripts before assuming command shape
- use `scripts/e2ectl-run.sh` to run `e2ectl` with captured output
- keep install and publish paths aligned with the actual repo layout

6. Node operation rules:
- `node list` and `node get` can run once the CLI and config are ready
- if multiple saved profiles exist, confirm which alias to use before node actions
- `node create` must prompt for node name, location, and project context before catalog discovery
- suggested defaults for those prompts are:
  - node name: `node-01`
  - location: current configured profile location, otherwise `Delhi`
  - project: current configured profile project ID when available
- treat those defaults as suggestions; let the user change them
- if the selected project or location does not match the active profile, switch to or create a matching profile before create
- use `e2ectl node get <nodeId>` for details; do not use a made-up `inspect` command
- `node create` must discover valid OS, plan, and image values before launch
- always pass the full `plan` field from `e2ectl node catalog plans`, not the short SKU label
- if `catalog plans` returns an unexpected response-shape error for one OS row, summarize the issue and retry with a different valid row or display category before giving up
- `node delete` requires explicit user confirmation
- when capturing CLI output programmatically, prefer `--json`
- do not show raw API calls or raw JSON responses to the user by default
- parse JSON internally and present readable summaries, short tables, or confirmation prompts
- show raw JSON only if the user explicitly requests it
- do not print secrets inside shell commands shown to the user

7. Validate after changes:
- lint changed shell scripts with `bash -n`
- run `--help` flows for changed scripts
- run at least one safe CLI readiness check when the binary is available
- verify install targets and published commands still match repo paths

8. Report outcome with:
- what changed
- what was validated
- open risks and rollback path

## Helper Script Usage

Examples:

```bash
./scripts/e2ectl-run.sh -- --help
```

```bash
./scripts/e2ectl-run.sh \
  --cwd /path/to/project \
  --output .artifacts/e2ectl-help.log \
  -- version
```
