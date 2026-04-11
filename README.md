# E2E Networks Skills

`use-e2e` lets coding agents manage E2E Networks resources with the official `e2ectl` CLI.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

The installer is the public entry point. By default it:

- installs the `use-e2e` skill
- installs `@e2enetworks-oss/e2ectl` globally if it is missing
- installs the skill globally unless you pass `--scope project`

Supported targets:

- Codex
- Claude Code
- OpenCode
- Amp

## Update

Run the installer again to update the skill.

If `e2ectl` is already installed:

- interactive runs ask whether to upgrade when a newer stable version is available
- non-interactive runs keep the current CLI unless you pass `--upgrade-cli`

Use `--skip-cli` only if you want to manage `e2ectl` yourself.

## What It Supports

This repo ships one installable skill:

- [`use-e2e`](plugins/e2e/skills/use-e2e/SKILL.md)

`use-e2e` is node-first and also covers:

- node actions and lifecycle checks
- SSH key upload and attach
- volume create, attach, and mount
- VPC create and attach
- frontend and backend deployment
- app updates, incident checks, and safe cleanup workflows

## Secure Auth And Config Flow

The skill keeps auth and context setup explicit:

- start with `e2ectl config list`
- use an existing profile or import a new config file
- prefer file import when a config file already exists on disk
- verify default project id and default location before resource changes
- avoid printing secrets or raw config content unless the user asks

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [E2E Networks Docs](https://docs.e2enetworks.com)

## License

MIT
