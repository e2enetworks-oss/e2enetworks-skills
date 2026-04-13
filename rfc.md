# E2E Skills RFC

## Objective
Publish a standalone `e2enetworks-skills` repository that supports:
1. Codex skill installation with one `curl` command
2. Claude skill installation from the same repo
3. a workflow where the `e2ectl` CLI is published separately, then verified and used by agents for node operations

## Repository Layout

```text
e2enetworks-skills/
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

Official repository:
- `https://github.com/e2enetworks-oss/e2enetworks-skills`

1. Use the official GitHub repository above for this skill pack.
2. Copy this folder’s contents into that repository root.
3. Update Claude metadata:
- edit `plugins/e2e/.claude-plugin/plugin.json`
- ensure the `repository` field matches `https://github.com/e2enetworks-oss/e2enetworks-skills`
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

1. Install the official `e2ectl` CLI: `npm install -g @e2enetworks-oss/e2ectl`
2. Verify it responds to `e2ectl --help`.
3. Install or update this skill pack in the target agent environment.
4. Use the skill for `node list`, `node create`, `node get`, and confirmed `node delete` flows.

Note:
- `scripts/install.sh` installs the skill pack only.
- The official CLI package is `@e2enetworks-oss/e2ectl` on npm.

## Curl Install Commands (for users)

Install both Codex skill + Claude skill:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target all --force
```

Install only Codex skill:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target codex --force
```

Install only Claude skill:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target claude --force
```

## Claude Skill Usage

After install, skill files are placed at:

```text
~/.claude/skills/use-e2e
```

Current Claude Code builds discover local skills from `~/.claude/skills`. If Claude is already running, restart it so it reloads skill files.

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
