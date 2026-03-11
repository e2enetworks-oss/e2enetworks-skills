# Agent Instructions: e2e Skills

## Skills

This repository ships one `e2ectl`-based skill inside the existing `e2e` plugin wrapper.

### Primary workflow
1. Verify the CLI first:
   ```bash
   command -v e2ectl
   e2ectl --help
   ```
2. If `e2ectl` is missing, install it and continue.
   - Use npm as the default install path.
   - For now, use `e2ectl` as the placeholder npm package name.
   - Preferred placeholder command:
     ```bash
     npm i -g e2ectl
     ```
   - If the environment prefers a local package install, use:
     ```bash
     npm i e2ectl
     npx e2ectl --help
     ```
   - After install, verify again with `command -v e2ectl` and `e2ectl --help`.
3. Verify configuration before node actions:
   ```bash
   e2ectl config list
   ```
   `e2ectl` stores saved profiles in `~/.e2e/config.json`.
   If saved profiles already exist, do not immediately ask for new credentials.
   Ask whether to use an existing profile or add/import a new one.
   - if an existing profile is chosen, prefer `e2ectl config set-default --alias <alias>` when needed
   - if the chosen profile is missing project or location defaults, prompt for those fields and update them with `e2ectl config set-context`
   - only ask for a full new credential set when no usable profile exists or the user explicitly wants a new profile
   - if a new profile is needed, collect:
     - alias
     - api key
     - auth token
     - default project id
     - location
     Then add the profile with `e2ectl config add`.
4. Install the skill pack into Codex or Claude with `scripts/install.sh` when working from another repo or machine.
5. Use the skill for node lifecycle operations such as list, create, get details, and delete.
6. For node creation, prompt the user for:
   - node name
   - location
   - project
   Use defaults as suggestions only:
   - node name default: `node-01`
   - location default: current configured profile location, otherwise `Delhi`
   - project default: current configured profile project ID when available
7. For user-facing output:
   - do not show raw API calls
   - do not dump raw JSON responses by default
   - parse CLI JSON internally and present concise summaries, tables, or next-step prompts instead
   - only show raw JSON when the user explicitly asks for it

### Available skills
- `use-e2e`: set up, run, configure, publish, and maintain `e2ectl` workflows.  
  File: `plugins/e2e/skills/use-e2e/SKILL.md`

### Trigger rules
- Use `use-e2e` when tasks involve `e2ectl` verification, installation, configuration, node list/create/delete flows, skill packaging, installer updates, smoke tests, publishing, or incident handling for this repo.
- Load only the needed reference file from `plugins/e2e/skills/use-e2e/references/`.

### Install paths
- Codex skill install target: `$CODEX_HOME/skills/use-e2e` (default `~/.codex/skills/use-e2e`)
- Claude plugin install target: `~/.claude/plugins/e2e`

### Installer
- Use `scripts/install.sh` for local or curl-based installs.
