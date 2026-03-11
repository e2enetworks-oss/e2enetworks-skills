# E2E Skills RFC

## Objective
Publish a standalone `e2e-skills` repository that supports:
1. Codex skill installation with one `curl` command
2. Claude plugin installation from the same repo
3. a workflow where the `e2ectl` CLI is published separately, then verified and used by agents for node operations

## Repository Layout

```text
e2e-skills/
├── plugins/e2e/
│   ├── .claude-plugin/plugin.json
│   ├── hooks/
│   └── skills/use-e2e/
│       ├── SKILL.md
│       ├── scripts/e2ectl-run.sh
│       └── references/
├── scripts/install.sh
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
└── rfc.md
```

## Publishing Guide

1. Create a new GitHub repository named `e2e-skills`.
2. Copy this folder’s contents into that repository root.
3. Update plugin metadata:
- edit `plugins/e2e/.claude-plugin/plugin.json`
- replace `https://github.com/REPLACE_ME/e2e-skills` with your actual GitHub URL
4. Make scripts executable:
```bash
chmod +x scripts/install.sh
chmod +x plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh
```
5. Push to `main`:
```bash
git add .
git commit -m "Initial e2ectl skills and plugin pack"
git push origin main
```
6. Create a release tag (recommended):
```bash
git tag v0.1.0
git push origin v0.1.0
```

## Release Order

1. Publish the `e2ectl` CLI to npm.
2. Verify the published CLI installs and responds to `--help`.
3. Install or update this skill pack in the target agent environment.
4. Use the skill for `node list`, `node create`, `node get`, and confirmed `node delete` flows.

Note: `scripts/install.sh` installs the skill pack only. If `e2ectl` is missing, install it first with npm. For now, use `e2ectl` as the placeholder package name in commands such as `npm i -g e2ectl`.

## Curl Install Commands (for users)

Replace `<OWNER>` with your GitHub org/user.

Install both Codex skill + Claude plugin:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<OWNER>/e2e-skills.git --target all --force
```

Install only Codex skill:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<OWNER>/e2e-skills.git --target codex --force
```

Install only Claude plugin:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/e2e-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/<OWNER>/e2e-skills.git --target claude --force
```

## Claude Plugin Usage

After install, plugin files are placed at:

```text
~/.claude/plugins/e2e
```

The shipped plugin contains:
- `.claude-plugin/plugin.json`
- `skills/use-e2e`
- `hooks/` for optional future automation hooks

If Claude is already running, restart Claude so it reloads plugin files.

## Codex Skill Usage

After install, skill files are placed at:

```text
~/.codex/skills/use-e2e
```

Codex can trigger the skill based on `SKILL.md` metadata and then use references/scripts on demand.

## Operational Notes

- Keep `main` stable; publish tested changes only.
- For breaking structure changes, bump tag versions and document migration notes in release descriptions.
- Prefer adding new references/scripts over bloating `SKILL.md`.
