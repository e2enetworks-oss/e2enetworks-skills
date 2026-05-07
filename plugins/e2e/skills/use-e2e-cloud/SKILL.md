---
name: use-e2e-cloud
description: Manage E2E Networks cloud platform resources — nodes, load balancers, databases, networking, and storage — using the official e2ectl CLI.
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

Use this skill when the user wants E2E Networks infrastructure work.

## 0. Version Check

**Run once per session, before anything else.**

### 0a. Read local version

Run:
```bash
cat ~/.claude/skills/use-e2e-cloud/VERSION 2>/dev/null \
  || cat ~/.codex/skills/use-e2e-cloud/VERSION 2>/dev/null \
  || cat ~/.cursor/skills/use-e2e-cloud/VERSION 2>/dev/null \
  || cat ~/.config/opencode/skills/use-e2e-cloud/VERSION 2>/dev/null
```

Capture output as `LOCAL_VERSION`. If the file is missing or the command fails, treat `LOCAL_VERSION` as `"0.0.0"`.

### 0b. Check throttle cache

Read `~/.e2e/.version-check-cache.json`:
```json
{ "checked_at": "<iso8601>", "result": "up-to-date|upgrade-available", "remote_version": "<x.y.z>" }
```
If it exists, `checked_at` is within **60 minutes** of now, and `result` is `"up-to-date"` → skip the rest of Section 0 and proceed to Section 2.

If `result` is `"upgrade-available"` but the snooze file (Section 0d) is still valid for that remote version → also skip.

### 0c. Fetch remote version

Run:
```bash
curl -fsSL --max-time 10 https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/VERSION
```

Capture as `REMOTE_VERSION`. If the command fails, returns empty output, or the output does not match `^[0-9]+\.[0-9]+\.[0-9]+$` → treat `REMOTE_VERSION` as equal to `LOCAL_VERSION` and proceed to Section 2 (**fail-open — never block the user on a network error**).

Write `~/.e2e/.version-check-cache.json` immediately after the fetch (`mkdir -p ~/.e2e` first if needed):
- `REMOTE_VERSION == LOCAL_VERSION` → `result: "up-to-date"`, TTL 60 min
- `REMOTE_VERSION > LOCAL_VERSION` → `result: "upgrade-available"`, TTL 720 min

### 0d. Compare versions and check snooze

Compare `LOCAL_VERSION` and `REMOTE_VERSION` by splitting on `.` and comparing major, minor, patch as integers in order.

If `REMOTE_VERSION <= LOCAL_VERSION` → proceed to Section 2.

If `REMOTE_VERSION > LOCAL_VERSION`:
1. Read `~/.e2e/.version-snooze.json` if it exists:
   ```json
   { "snoozed_until": "<iso8601>", "remote_version": "<x.y.z>" }
   ```
2. Snooze is **active** only if ALL three conditions hold:
   - File exists
   - `snoozed_until` is in the future
   - `remote_version` in the file **equals** `REMOTE_VERSION` (a newer release bypasses any prior snooze)
3. If snooze is active → proceed to Section 2 silently.
4. If snooze is not active → go to Section 0e.

### 0e. Prompt the user

Use `AskUserQuestion`:
- **question**: `A newer version of the use-e2e-cloud skill is available. You have **v{LOCAL_VERSION}** installed; the latest is **v{REMOTE_VERSION}**. Would you like to upgrade now?`
- **options**: `Yes` / `No`

**"Yes"** → Run the installer automatically:
```bash
curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
```
If the command succeeds, tell the user:
> Upgraded to v{REMOTE_VERSION}. Please start a fresh conversation and invoke `/use-e2e-cloud` again — the new version is now installed and will load on your next session.

If the command fails, tell the user what went wrong and suggest they run the installer manually.

Either way, **stop** (do not proceed to Section 2). The currently loaded SKILL.md is from the old version; the new version must load fresh in a new session.

**"No"** → Do not write any snooze file. Proceed to Section 2. (Check runs again next session.)

## 1. Session Load — Fast Path

Keep session start cheap. The minimum work that runs on every load is:

1. Section 0 — skill version check (cached 60 min, single network call at most)
2. `which e2ectl` (no network)
3. Read saved profile from `~/.e2e/config.json` (no network)

That's it. Trust saved alias, project ID, and location silently — see `references/access.md` Step 7a.

**Do not, on every load:**
- Run `e2ectl --version` or `npm view ...` to compare CLI versions (see `access.md` Step 2b — reactive only)
- Re-run `project list` to validate the saved default project ID (saved IDs may be IAM-shared and won't appear there)
- Re-prompt for profile, project, or location when valid context is already saved
- List nodes / volumes / VPCs / etc. as a "warmup"

The user wants to start working, not watch the skill audit itself. Prompts are reserved for: missing context, real API errors, and explicit user requests.

## 2. Resolve CLI

See `references/access.md` for the full flow (Node.js check → CLI install → Global vs Project).

**Permission rules — strictly required:**
- Each Bash call must start with a single command token — no `&&` or `;` chains
- Poll node status by running `sleep` and `node get` as separate Bash calls, never chained. Status values are case-insensitive — always use `grep -i` when matching status strings.
- `&&` inside an `ssh` remote command string is fine — only the outer `Bash` tool call must not chain
- Only `node delete` and `reserved-ip delete` need explicit user confirmation

## 3. Resolve Config

See `references/access.md` for the full flow (config list → profile select → project select → location).

If any command returns `Profile "<alias>" was not found`: tell the user in plain language — "A profile is your saved E2E credentials. It looks like it was removed or never saved. Let's set one up." — then re-run the config flow.

## 4. Capability Index

| Want to... | Reference |
|---|---|
| Set up credentials / switch profiles | `references/access.md` |
| List or create projects | `references/project.md` |
| Provision, upgrade, or delete nodes | `references/nodes.md` |
| Power on/off, save image, attach resources | `references/nodes.md` |
| List, rename, or delete saved images | `references/image.md` |
| Create a node from a saved image | `references/image.md` |
| Manage reserved IPs | `references/reserved-ip.md` |
| Create or attach volumes | `references/volume.md` |
| Create or attach VPCs | `references/vpc.md` |
| Create or attach security groups | `references/security-group.md` |
| Create or manage load balancers (ALB/NLB) | `references/load-balancer.md` |
| Create or manage DBaaS clusters (MariaDB/MySQL/PostgreSQL) | `references/dbaas.md` |
| Deploy a frontend or backend app | `references/deploy.md` |
| SSH into a node, DNS, HTTPS | `references/deploy.md` |
| Estimate costs for any service | `references/cost-estimation.md` |


## 5. Critical Rules

Critical rules live in each service's reference file — see the **Rules**, **Error Recovery**, and **Polling** sections inside each.

**Hard rules:**
- **Bulk delete order:** nodes → volumes → VPCs → security groups → SSH keys → reserved IPs
- **Case-insensitive status polling:** all status checks (Running, Active, Attached, etc.) must use case-insensitive matching — always `grep -i`, never bare `grep`
- **Unsupported actions:** always try your best to fulfill the request using the available CLI commands and reference files. Only if the action is genuinely not possible through this skill — after exhausting all options — tell the user: "This skill currently doesn't support that. You can do it directly in E2E Cloud MyAccount at https://myaccount.e2enetworks.com"

## 6. Defaults

Always apply these unless the user says otherwise:

| Value | Default |
|---|---|
| SSH user | `root` |
| Mount path | `/data` |
| Public key path | `~/.ssh/id_ed25519.pub` |
| SSH key label | `node-access` |

## 7. Output Rules

- Natural language summaries — never raw JSON or raw CLI output
- Never show CLI commands in responses to the user — no `e2ectl ...` hints, no "run this next" command snippets, no reference file paths
- Node lists: id, name, status, public IP
- Node details: id, name, status, plan, public IP, private IP, created time
- After any action: show what happened + next useful step
- Errors: plain language — what broke, why, how to fix it
- Overview / "what can you do" replies: respond with the same simple hello message as Section 8a (e.g. "Hey! I'm connected to your E2E Cloud MyAccount. What would you like to do?") — no capability lists, no service breakdowns, no bullets

## 8. UX Rules

- One-line summary at the start of each step
- One question at a time — use `AskUserQuestion` with buttons, never plain text
- If the user says "deploy my server", "run something on the node", or "check what's running" → SSH-into-node workflow
- If the user mentions ALB, NLB, or load balancer → create/use the LB workflow from `references/load-balancer.md`
- When creating any resource (node, volume, VPC, load balancer, DBaaS, etc.), always announce: "Creating <resource-type> using <alias>" before executing the command

### 8a. Skill Ready Message

After Sections 0 and 2 complete with no prior session state and no user intent already stated, greet the user with a simple friendly message:

> Hey! I'm connected to your E2E cloud. What would you like to do?

If a default config exists (profile, project, location resolved in Section 3), mention it briefly:

> Using profile **<alias>**, project **<project-name>**, location **<location>**.

If no config is set, say:

> No default config found. Let's set one up first.

Then stop and wait for the user to state intent. Do **not** follow the greeting with an `AskUserQuestion` action menu — the user prefers to type their request directly.

If the user already stated intent in their opening message (e.g. "create a node"), skip the greeting and proceed directly with their request.

## References

- setup, config, and onboarding: `references/access.md`
- nodes and node actions: `references/nodes.md`
- saved images (list, rename, delete, create node from image): `references/image.md`
- projects: `references/project.md`
- reserved IPs: `references/reserved-ip.md`
- block storage volumes: `references/volume.md`
- VPC networks: `references/vpc.md`
- security groups: `references/security-group.md`
- load balancers (ALB/NLB): `references/load-balancer.md`
- DBaaS clusters (MariaDB/MySQL/PostgreSQL): `references/dbaas.md`
- app deployment, DNS, HTTPS, services: `references/deploy.md`
- cost estimation and pricing: `references/cost-estimation.md`
