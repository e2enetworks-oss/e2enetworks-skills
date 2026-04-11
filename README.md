# E2E Networks Skills

`use-e2e` gives your coding agent a clean way to manage E2E Networks resources through the official `@e2enetworks-oss/e2ectl` CLI.

Use it to work with nodes, volumes, VPCs, and SSH keys without building your own wrapper around the API.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

The installer:

- installs the `use-e2e` skill
- installs `@e2enetworks-oss/e2ectl` globally if it is missing
- works with Codex, Claude Code, OpenCode, and Amp

## What You Can Ask

- "List my E2E nodes and tell me which ones are stopped."
- "Create a new Ubuntu node and attach my SSH key."
- "Create a volume, attach it to this node, and mount it at `/data`."
- "Attach this node to my VPC."
- "Power-cycle this node and confirm it comes back healthy."
- "Deploy my backend repo on this node."

## First Run

1. Create an API token in [E2E MyAccount > API & IAM](https://myaccount.e2enetworks.com/services/apiiam) and download the config JSON.
2. Import it with:

```bash
e2ectl config import --file ~/Downloads/config.json
```

3. Confirm the saved profile:

```bash
e2ectl config list
```

Once a default alias, project id, and location are saved, the skill can use them for future commands.

## Verify The Install

```bash
e2ectl --version
e2ectl config list
```

Then give your agent a simple first task, like:

- "Show me my saved E2E profiles."
- "List my nodes and call out anything stopped."

## Update

Run the installer again to update the skill.

If `e2ectl` is already installed:

- interactive reruns ask before upgrading to a newer stable CLI
- non-interactive reruns keep the current CLI unless you pass `--upgrade-cli`
- `--skip-cli` lets you manage `e2ectl` yourself

## Common Variants

Install for a specific target:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --target claude --force
```

Install into the current project instead of globally:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --scope project --project-dir "$PWD" --target claude --force
```

Upgrade the CLI in non-interactive environments:

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
  bash -s -- --upgrade-cli --force
```

## Troubleshooting

If `e2ectl` is still missing after install, rerun the installer in the same Node/npm environment you use in your shell. The installer checks that the active `e2ectl` on your `PATH` is the one npm actually updated and will fail with guidance if your shell is pointed at a different global prefix.

## Included Skill

- [`use-e2e`](plugins/e2e/skills/use-e2e/SKILL.md)

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [E2E Networks Docs](https://docs.e2enetworks.com)

## License

MIT
