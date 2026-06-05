# VPC

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Missing Specs — Ask Before Creating

If the user asks to create a VPC without specifying all required details, ask for each missing value one at a time using `AskUserQuestion` before running any command. Never assume or default any value silently.

**Step 1 — IP range assignment** (ask first — most fundamental choice):
Ask: "How would you like to set up the IP range for this network?"
Options: `Let E2E assign it automatically` / `I'll specify my own IP range`

**Step 2 — custom CIDR** (only if user chose custom):
Ask: "What IP range would you like? (e.g. 10.0.0.0/16)" (free-text)

**Step 3 — VPC name** (if not given):
Ask: "What would you like to name this network?"
Options: suggest 2–3 names derived from the user's stated purpose (e.g. `app-vpc`, `prod-network`). Always include `Enter a custom name` as the last option (free-text follow-up).

**Step 4 — billing type** (run `vpc plans` first, if not given):
Ask: "How would you like to be billed?"
Options: `Hourly — pay as you go` / `Committed — save with a fixed term`

**Step 5 — committed plan** (only if committed billing chosen — from `vpc plans` output):
Ask: "Which committed plan would you like?"
Options: one button per committed plan from `vpc plans` output

**Step 6 — post-commit behavior** (only if committed billing chosen):
Ask: "What should happen when the committed term ends?"
Options: `Auto-renew` / `Switch to hourly billing`

**Step 7 — confirmation summary:**
Before running any command, display a summary of all selected options:

> Here's what will be created:
>
> - **Name:** `<name>`
> - **IP range:** `<E2E assigned / custom CIDR>`
> - **Billing:** `<hourly / committed plan>`

Ask: "Ready to create this network?"
Options: `Yes, create it` / `No, go back`

If "No, go back" — ask which detail they'd like to change and loop back to that step.

Do not proceed to `vpc create` until the user confirms with "Yes, create it".

## VPC ID Disambiguation

The API returns two different IDs when you create or list a VPC:

- **VPC ID** — internal identifier, shown in `vpc create` output
- **Network ID** (`network_id`) — the canonical VPC ID used by all follow-up commands

All of the following use the **Network ID**:

- `vpc get <vpcId>`
- `vpc delete <vpcId>`
- `node action vpc attach --vpc-id`
- `node action vpc detach --vpc-id`

Always run `vpc list` after `vpc create` and read the **Network ID** column.
Never pass the raw VPC ID from `vpc create` output to `--vpc-id`.

## Commands

Inspect hourly and committed billing options:

```bash
CLI vpc plans --alias <alias>
```

Create hourly with E2E-assigned CIDR:

```bash
CLI vpc create \
  --name <vpc-name> \
  --billing-type hourly \
  --cidr-source e2e \
  --alias <alias>
```

Create with custom CIDR:

```bash
CLI vpc create \
  --name <vpc-name> \
  --billing-type hourly \
  --cidr-source custom \
  --cidr <custom-cidr> \
  --alias <alias>
```

Create committed:

```bash
CLI vpc create \
  --name <vpc-name> \
  --billing-type committed \
  --committed-plan-id <committed-plan-id> \
  --post-commit-behavior auto-renew \
  --cidr-source e2e \
  --alias <alias>
```

`--post-commit-behavior` choices: `auto-renew` or `hourly-billing`.

List (use Network ID column for follow-up commands):

```bash
CLI vpc list --alias <alias>
```

Get details by Network ID:

```bash
CLI vpc get <network-id> --alias <alias>
```

Delete by Network ID:

```bash
CLI vpc delete <network-id> --force --alias <alias>
```

## Attach to a Node

`node action vpc attach` only works when the VPC state is `Active`. Use case-insensitive matching (`grep -i`).
After `vpc create`, poll `vpc list` until the state becomes `Active` before attaching.
Do not attempt attach while state is `Creating` — it will fail with "VPC X not found".

Attach:

```bash
CLI node action vpc attach <node-id> --vpc-id <network-id> --alias <alias>
```

Optional flags: `--subnet-id <subnetId>`, `--private-ip <privateIp>`.

Detach:

```bash
CLI node action vpc detach <node-id> --vpc-id <network-id> --alias <alias>
```

## When to Use VPC

| Scenario                             | VPC needed? | Notes                                                              |
| ------------------------------------ | ----------- | ------------------------------------------------------------------ |
| DBaaS with private networking        | Yes         | Attach VPC at DBaaS create or after via `dbaas network vpc attach` |
| DBaaS with public IP only            | No          | DBaaS can be reached via public endpoint without VPC               |
| Nodes communicating privately        | Yes         | Attach same VPC to all nodes                                       |
| Load balancer with internal backends | Yes         | LB and backends in same VPC                                        |
| No private networking needed         | No          | Nodes with public IPs only                                         |

Security groups do not apply to DBaaS. DBaaS access is controlled via IP whitelisting, not security groups.

## Full Networking Workflow

```bash
# 1. Check billing options
CLI vpc plans --alias <alias>

# 2. Create VPC
CLI vpc create --name <vpc-name> --billing-type hourly --cidr-source e2e --alias <alias>

# 3. Poll until Active (run vpc list, check State column, sleep between checks)
CLI vpc list --alias <alias>

# 4. Attach to node using Network ID
CLI node action vpc attach <node-id> --vpc-id <network-id> --alias <alias>

# 5. Verify node has private IP
CLI node get <node-id> --alias <alias>
```

## Error Recovery

| Error                                              | Cause                                               | Fix                                                                       |
| -------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------- |
| `node action vpc attach` returns "VPC X not found" | VPC state is not yet `Active`                       | Poll `vpc list` until State column shows `Active`, then retry             |
| `vpc delete` rejected                              | Node is still attached to the VPC                   | Detach with `node action vpc detach`, verify with `node get`, then delete |
| Attach succeeds but node has no private IP         | Wrong ID passed (`vpc create` VPC ID vs Network ID) | Run `vpc list`, use the **Network ID** column value for `--vpc-id`        |

## Output Rules

- after `vpc list`, show id (Network ID), name, state, CIDR, and location
- after create, remind the user to wait for `Active` state before attaching
- after attach, confirm the node now has a private IP
- do not show raw JSON unless asked
