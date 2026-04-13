# E2E Networks Skills

Agent skill for [E2E Networks](https://www.e2enetworks.com), following the [Agent Skills](https://agentskills.io) format.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```

You can also install via [skills.sh](https://skills.sh):

```bash
npx skills add e2enetworks-oss/e2enetworks-skills
```

Supports Claude Code, OpenAI Codex, OpenCode, Cursor or any coding agent. Run the installer again to update.

## Quickstart

1. Create an API token in [E2E MyAccount > API & IAM](https://myaccount.e2enetworks.com/services/apiiam) and download the config JSON.
2. In your coding agent, invoke the skill — for example in Claude Code:

   ```
   /use-e2e
   ```

   Or just ask in natural language: *"Set up my E2E config."*

3. The skill will:
   - check whether `e2ectl` is already installed
   - if `e2ectl` is missing, ask whether to install it globally or in this project
   - import your config JSON (point it at `~/Downloads/config.json` when asked)
   - prompt for a default project id and location if they aren't already saved
   - confirm the saved profile is ready

From that point on, the skill uses your saved alias, project id, and location for every request — you don't need to type CLI commands yourself.

## What you can ask

- "Show me my saved E2E profiles."
- "List my nodes and call out anything stopped."
- "Create a new Ubuntu node and attach my SSH key."
- "Create a volume, attach it to this node, and mount it at `/data`."
- "Attach this node to my VPC."
- "Power-cycle this node and confirm it comes back healthy."
- "Deploy my backend repo on this node."

In Claude Code, you can also run `/use-e2e`.


## Workflow coverage

`use-e2e` covers:

- Profile and config setup
- Node provisioning and lifecycle
- Node actions (power, save-image, attach)
- SSH key upload and attach
- VPC create and attach
- Volume create, attach, and mount
- Frontend and backend deployment on a node
- DNS and HTTPS (Certbot)
- Fleet inventory and status checks

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for repository structure and development notes.

## License

MIT
