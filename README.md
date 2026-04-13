# E2E Networks Skills

`use-e2e` gives your coding agent a clean way to manage E2E Networks resources with the official E2E CLI.

Use it to create and manage nodes, volumes, VPCs, and SSH keys from natural language requests.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

This installs the skill and sets up `@e2enetworks-oss/e2ectl` if needed.

## First Run

1. Create an API token in [E2E MyAccount > API & IAM](https://myaccount.e2enetworks.com/services/apiiam) and download the config JSON.
2. Import it:

```bash
e2ectl config import --file ~/Downloads/config.json
```

3. Verify your setup:

```bash
e2ectl --version
e2ectl config list
```

Once a default alias, project id, and location are saved, the skill can use them in future requests.

## What You Can Ask

- "Show me my saved E2E profiles."
- "List my nodes and call out anything stopped."
- "Create a new Ubuntu node and attach my SSH key."
- "Create a volume, attach it to this node, and mount it at `/data`."
- "Attach this node to my VPC."
- "Power-cycle this node and confirm it comes back healthy."
- "Deploy my backend repo on this node."

In Claude Code, you can also run `/use-e2e`.

## Update

Run the installer again to update the skill.

Use `--upgrade-cli` for non-interactive CLI upgrades, or `--skip-cli` if you manage `e2ectl` yourself.

## Optional Flags

- `--target claude` installs for one agent target
- `--scope project --project-dir "$PWD"` installs into the current project
- `--upgrade-cli` upgrades `e2ectl` in non-interactive environments

## Troubleshooting

If `e2ectl` is still missing after install, rerun the installer and follow the guidance it prints.

## References

- [E2E Networks Docs](https://docs.e2enetworks.com)

## License

MIT
