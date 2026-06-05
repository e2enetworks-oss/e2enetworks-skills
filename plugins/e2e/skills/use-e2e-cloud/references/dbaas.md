# DBaaS

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

DBaaS is a managed database — connect via public endpoint, public IP, or private IP. SSH is not allowed.

## Missing Specs — Ask Before Creating

If the user asks to create a database without specifying all required details, ask for each missing value one at a time using `AskUserQuestion` before running any command. Never assume or default any value silently.

**Step 1 — database engine** (run `dbaas types` first, then ask):
Ask: "Which database engine would you like to use?"
Options: one button per engine type from `dbaas types` output (e.g. `MariaDB` / `MySQL` / `PostgreSQL`)

**Step 2 — version** (from `dbaas types --type <type>` output):
Ask: "Which version would you like?"
Options: one button per available version for the chosen engine

**Step 3 — cluster name** (if not given):
Ask: "What would you like to name this database cluster?"
Options: suggest 2–3 names derived from the user's stated purpose (e.g. `my-postgres`, `app-db`). Always include `Enter a custom name` as the last option (free-text follow-up).

**Step 4 — plan** (run `dbaas plans --type <type> --db-version <version>` first, then ask):
Ask: "Which plan suits your needs?"
Options: one button per plan from `dbaas plans` output

**Step 5 — database name** (if not given):
Ask: "What would you like to call the initial database?" (free-text)

**Step 6 — admin username** (always ask):
Ask: "What username would you like for the admin account?"
Options: `admin` / `Enter a custom username` (free-text follow-up)

**Step 7 — password** (always required):
Ask: "Please set a secure password for the admin account." (free-text — stored via password file, never in shell history)

**Step 8 — how should this database be accessed?**:
Ask: "How would you like to access this database?"
Options: `Public IP only` / `Public IP + private VPC` / `Private VPC only`

**Step 9 — VPC** (only if VPC option chosen — run `vpc list` first):
Ask: "Which VPC would you like to attach this database to?"
Options: one button per VPC showing name and CIDR plus `Create a new VPC first`

**Step 10 — billing type** (if not given):
Ask: "How would you like to be billed?"
Options: `Hourly — pay as you go` / `Committed — save with a fixed term`

**Step 11 — committed plan** (only if committed billing chosen — from `dbaas plans` output):
Ask: "Which committed plan would you like?"
Options: one button per committed SKU from `dbaas plans` output

**Step 12 — post-commit renewal** (only if committed billing chosen):
Ask: "What should happen when the committed term ends?"
Options: `Auto-renew` / `Switch to hourly billing`

**Step 13 — confirmation summary:**
Before running any command, display a summary of all selected options:

> Here's what will be created:
>
> - **Engine:** `<engine> <version>`
> - **Cluster name:** `<name>`
> - **Plan:** `<plan>`
> - **Database name:** `<database-name>`
> - **Admin username:** `<username>`
> - **Access:** `<Public IP only / Public IP + VPC / Private VPC only>`
> - **VPC:** `<vpc name or None>`
> - **Billing:** `<hourly / committed plan>`

Ask: "Ready to create this database?"
Options: `Yes, create it` / `No, go back`

If "No, go back" — ask which detail they'd like to change and loop back to that step.

Do not proceed to `dbaas create` until the user confirms with "Yes, create it".

## Discovery (required before create)

Discover engine types:

```bash
CLI dbaas types --alias <alias>
CLI dbaas types --type postgres --alias <alias>
```

User-facing types: `maria`, `sql`, `postgres`.

Discover plans for a version:

```bash
CLI dbaas plans --type postgres --db-version 16 --alias <alias>
```

This shows hourly template plans AND committed SKU IDs in the same output.

## Core Commands

List:

```bash
CLI dbaas list --alias <alias>
CLI dbaas list --type sql --alias <alias>
```

Get detail:

```bash
CLI dbaas get <dbaas-id> --alias <alias>
```

Create (hourly):

```bash
CLI dbaas create \
  --name <cluster-name> \
  --type sql \
  --db-version 8.0 \
  --plan <plan-name> \
  --database-name <database-name> \
  --password-file /secure/path/dbaas-password.txt \
  --alias <alias>
```

Use `--password-file -` to read from stdin. `--username <user>` for custom admin user.

Create (committed billing):

```bash
CLI dbaas create \
  --name <cluster-name> \
  --type sql \
  --db-version 8.0 \
  --plan <plan-name> \
  --database-name <database-name> \
  --password-file /secure/path/dbaas-password.txt \
  --billing-type committed \
  --committed-plan-id <sku-id> \
  --alias <alias>
```

Default committed renewal is auto-renew. Pass `--committed-renewal hourly` to switch to hourly at term end.

Create with VPC (use network_id from `vpc list`):

```bash
CLI dbaas create \
  --name <cluster-name> \
  --type postgres \
  --db-version 16 \
  --plan <plan-name> \
  --database-name <database-name> \
  --password-file /secure/path/dbaas-password.txt \
  --vpc-id <vpc-id> \
  --alias <alias>
```

For non-default VPCs, add `--subnet-id <subnet-id>`. VPC-attached DBaaS gets a public IP by default. Add `--no-public-ip` for private-only.

## Networking

### Networking Options Matrix

| Public IP | VPC | Whitelist | Use case                                                |
| --------- | --- | --------- | ------------------------------------------------------- |
| Yes       | No  | Required  | Public access only — whitelist your IPs                 |
| Yes       | Yes | Required  | Public access + private VPC communication               |
| No        | Yes | N/A       | Private-only — accessible only within VPC               |
| No        | No  | N/A       | Not allowed — DBaaS must have at least one network path |

### VPC Commands

```bash
CLI dbaas network vpc attach <dbaas-id> --vpc-id <vpc-id> --alias <alias>
```

For non-default VPCs, add `--subnet-id <subnet-id>`.

Detach VPC:

```bash
CLI dbaas network vpc detach <dbaas-id> --vpc-id <vpc-id> --alias <alias>
```

Attach public IP:

```bash
CLI dbaas network public-ip attach <dbaas-id> --alias <alias>
```

Detach public IP (requires `--force` in non-interactive):

```bash
CLI dbaas network public-ip detach <dbaas-id> --force --alias <alias>
```

## Whitelist IPs

```bash
CLI dbaas whitelist add <dbaas-id> --ip 203.0.113.10 --alias <alias>
CLI dbaas whitelist list <dbaas-id> --alias <alias>
CLI dbaas whitelist remove <dbaas-id> --ip 203.0.113.10 --alias <alias>
```

## Reset Password

```bash
CLI dbaas reset-password <dbaas-id> --password-file /secure/path/dbaas-password.txt --alias <alias>
```

## Delete

```bash
CLI dbaas delete <dbaas-id> --force --alias <alias>
```

Ask for confirmation once. When confirmed, always use `--force`.

## Rules

- Run `dbaas types` then `dbaas plans` before any create — never skip discovery
- Use exact `--plan` name from `dbaas plans` output
- Prefer `--password-file <path>` or `--password-file -` over `--password <password>` to keep passwords out of shell history
- For committed billing, use `--committed-plan-id` with the SKU ID from `dbaas plans`
- `--committed-plan` (named) and `--committed-plan-id` (numeric) are mutually exclusive
- VPC attach at create requires `--vpc-id` (network_id from `vpc list`)
- VPC-attached DBaaS defaults to public IP. Use `--no-public-ip` for private-only

## Polling

After create, poll `dbaas get` until status is `Running`. Do not attempt network/whitelist actions while status is `Creating`.

## Error Recovery

| Error                   | Cause                                         | Fix                                                                            |
| ----------------------- | --------------------------------------------- | ------------------------------------------------------------------------------ |
| Plan validation fails   | Wrong plan name or mismatch with type/version | Re-run `dbaas plans --type <type> --db-version <version>`, use exact plan name |
| Committed SKU not found | Wrong SKU ID for given type/version           | Re-run `dbaas plans`, use exact SKU ID from output                             |
| Network attach fails    | DBaaS not Running or wrong vpc-id             | Poll `dbaas get` until Running, verify vpc-id from `vpc list`                  |
| Whitelist add fails     | Invalid IP or DBaaS not Running               | Verify IPv4 format, poll until Running                                         |

## Output Rules

- List: name, type, db-version, database name, admin username, endpoint, status
- Detail: add plan, price, configuration, vpc connections, whitelisted IPs, public IP, port
- After create: show endpoint, port, database name, and admin username so the user can connect
- After any action: confirm with follow-up `dbaas get`
- Do not show raw JSON unless asked
