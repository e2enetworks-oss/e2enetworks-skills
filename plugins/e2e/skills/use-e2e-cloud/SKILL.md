---
name: use-e2e-cloud
description: Manage E2E Networks cloud platform resources — nodes, networking, and storage — using the official e2ectl CLI.
---

# use-e2e-cloud

## Allowed Tools

- `Bash(e2ectl *)` — run e2ectl CLI (`npm install -g @e2enetworks-oss/e2ectl`)
- `Bash(npm *)` — install e2ectl or app dependencies
- `Bash(npx *)` — run project-local e2ectl
- `Bash(ssh *)` — SSH into nodes and run remote commands
- `Bash(scp *)` — upload files to nodes
- `Bash(ssh-keygen *)` — manage known_hosts
- `Bash(sleep *)` — wait between status checks
- `Bash(for *)` — polling loops
- `Bash(until *)` — polling loops
- `Bash(dig *)` — DNS propagation checks
- `Bash(curl *)` — HTTP health checks
- `Bash(cat *)` — read local files
- `Bash(ls *)` — inspect local paths
- `Bash(which *)` — detect installed CLI
- `Bash(go *)` — build Go binaries locally before upload
- `WebFetch(https://docs.e2enetworks.com/*)` — fetch E2E docs when reference files don't cover a specific question

Use this skill when the user wants E2E Networks infrastructure work.

## 0. Session Resume Detection

After config resolves, check `~/.e2e/use-e2e-state.json`. If it exists and is under 24h old, offer to resume:

- question: `You have an unfinished flow. Resume it?`
- options: `Resume — [next pending step]` / `Start fresh`

If no state file, AND this is the first message of the session, AND the user's message explicitly contains "create", "provision", or "deploy": run `node list`, find any recently-created `Running` node with no SSH key attached, and ask if they want to continue its setup. Do not run this check for any other intent.

**Write state at each major step** (node_created → ssh_key_attached → vpc_attached → volume_attached → app_deployed). Delete on completion, cancellation, or after 24h. State file: `~/.e2e/use-e2e-state.json`.

State file schema (always include `schema_version`):
```json
{
  "schema_version": 1,
  "step": "<current-step>",
  "node_id": "<node-id>",
  "alias": "<profile-alias>",
  "updated_at": "<iso8601-timestamp>"
}
```

## 1. Resolve CLI

See `references/access.md` for the full flow (Node.js check → CLI install → Global vs Project).

**Permission rules — strictly required:**
- Each Bash call must start with a single command token — no `&&` or `;` chains
- Poll node status by running `sleep` and `node get` as separate Bash calls, never chained
- `&&` inside an `ssh` remote command string is fine — only the outer `Bash` tool call must not chain
- Only `node delete` and `reserved-ip delete` need explicit user confirmation

## 2. Resolve Config

See `references/access.md` for the full flow (config list → profile select → project select → location).

If any command returns `Profile "<alias>" was not found`: tell the user in plain language — "A profile is your saved E2E credentials. It looks like it was removed or never saved. Let's set one up." — then re-run the config flow.

## 3. Capability Index

| Want to... | Reference |
|---|---|
| Set up credentials / switch profiles | `references/access.md` |
| List or create projects | `references/project.md` |
| Provision, upgrade, or delete nodes | `references/nodes.md` |
| Power on/off, save image, attach resources | `references/nodes.md` |
| Manage reserved IPs | `references/reserved-ip.md` |
| Create or attach volumes | `references/volume.md` |
| Create or attach VPCs | `references/vpc.md` |
| Create or attach security groups | `references/security-group.md` |
| Deploy a frontend or backend app | `references/deploy.md` |
| SSH into a node, DNS, HTTPS | `references/deploy.md` |
| Docs for any resource / pricing / limits | `references/docs-index.md` |

## 4. Critical Rules

These rules are not obvious from the CLI — always apply them.

**Nodes:**
- `--plan` must be the exact full string from `node catalog plans` output (e.g. `"c2.large (8 vCPUs / 16 GB RAM / 100 GB SSD)"`). Using the SKU shortname causes a 412 error.
- E1/E1WC plans require `--disk <gb>`. All other plans reject it.
- Do not attempt any attach action while a node is `Creating`. Poll `node get` until `Running`.
- After any power or state-changing action, always follow up with `node get` — never show only the action receipt.
- `node action public-ip detach` removes public reachability — confirm with the user first.

**VPC:**
- `node action vpc attach` takes the **Network ID** (from `vpc list`), not the VPC ID from `vpc create`.
- VPC must be `Active` before attaching. Poll `vpc list` after create.

**Volumes:**
- Always run `volume plans` before `volume create` — minimum sizes vary by location.
- Never delete an `Attached` volume. Detach first.

**Bulk delete order:** nodes → volumes → VPCs → security groups → SSH keys → reserved IPs.

## 5. Defaults

Always apply these unless the user says otherwise:

| Value | Default |
|---|---|
| SSH user | `root` |
| Mount path | `/data` |
| Public key path | `~/.ssh/id_ed25519.pub` |
| SSH key label | `node-access` |

## 6. Output Rules

- Natural language summaries — never raw JSON or raw CLI output
- Node lists: id, name, status, public IP
- Node details: id, name, status, plan, public IP, private IP, created time
- After any action: show what happened + next useful step
- Errors: plain language — what broke, why, how to fix it

## 7. UX Rules

- One-line summary at the start of each step
- One question at a time — use `AskUserQuestion` with buttons, never plain text
- If the user says "deploy my server", "run something on the node", or "check what's running" → SSH-into-node workflow

## References

- setup, config, and onboarding: `references/access.md`
- nodes and node actions: `references/nodes.md`
- projects: `references/project.md`
- reserved IPs: `references/reserved-ip.md`
- block storage volumes: `references/volume.md`
- VPC networks: `references/vpc.md`
- security groups: `references/security-group.md`
- app deployment, DNS, HTTPS, services: `references/deploy.md`
- E2E docs index (all resource URLs): `references/docs-index.md`
