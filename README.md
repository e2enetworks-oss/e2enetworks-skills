# E2E Networks Skills

Manage E2E Networks cloud infrastructure in plain English from your coding agent — no dashboard, no CLI flags, no docs required.

```
"Create a Ubuntu node and deploy my Node.js backend"
"List my nodes and show anything that's stopped"
"Attach a volume to this node and mount it at /data"
```

Works with Claude Code, Codex, Cursor, and any agent that supports the [Agent Skills](https://agentskills.io) format.

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

1. Go to [E2E MyAccount > API](https://myaccount.e2enetworks.com/services/apiiam). If you already have a token with **Read and Write** permissions, use it — otherwise create a new token (ensure both Read and Write permissions are enabled). Then click the **Download Tokens** button to download all the tokens.
2. In your coding agent, invoke the skill — for example in Claude Code:

   ```
   /use-e2e-cloud
   ```

   Or just ask in natural language: _"Set up my E2E config."_

3. The skill will:
   - check whether `e2ectl` is already installed
   - if `e2ectl` is missing, ask whether to install it globally or in this project
   - import your config JSON (give it the path where you saved the downloaded file; if it contains multiple tokens, pick which one to import)
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

In Claude Code, you can also run `/use-e2e-cloud`.

## Workflow coverage

`use-e2e-cloud` covers:

- Profile and config setup
- Node provisioning and lifecycle (create, upgrade, delete, power)
- Node actions (power, save-image, attach VPC / volume / security group / SSH key)
- Saved images (list, rename, delete, create node from a saved image)
- SSH key upload and attach
- VPC create and attach (Standard or Custom CIDR)
- Volume create, attach, and mount
- Reserved IP allocation, attach, and release
- Security group create, update, attach, and detach
- Load balancers (ALB, NLB, internal) — backend groups, SSL, VPC
- Managed databases (DBaaS) — MariaDB, MySQL, PostgreSQL — networking and whitelisting
- Cost estimation for any service before provisioning
- Frontend and backend deployment on a node
- Support tickets (create, list, reply, close, reopen, timeline)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for repository structure and development notes.

## Questions & Support

Stuck? Found a bug? Want to request a workflow? [Open a GitHub Issue](https://github.com/e2enetworks-oss/e2enetworks-skills/issues).

## License

MIT
