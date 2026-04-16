# VPC

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

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

`node action vpc attach` only works when the VPC state is `Active`.
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

## Output Rules

- after `vpc list`, show id (Network ID), name, state, CIDR, and location
- after create, remind the user to wait for `Active` state before attaching
- after attach, confirm the node now has a private IP
- do not show raw JSON unless asked
