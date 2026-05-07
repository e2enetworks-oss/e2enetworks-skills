# Load Balancer

In this file, `CLI` means the resolved command from `SKILL.md`.

ALB = Application Load Balancer (HTTP/HTTPS). NLB = Network Load Balancer (TCP).

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Missing Specs — Ask Before Creating

If the user asks to create a load balancer without specifying all required details, ask for each missing value one at a time using `AskUserQuestion` before running any command. Never assume or default any value silently.

**Step 1 — LB kind** (ask first — drives all later choices):
Ask: "What kind of load balancer do you need?"
Options: `Application Load Balancer (ALB) — HTTP/HTTPS` / `Network Load Balancer (NLB) — TCP`

**Step 2 — visibility** (if not given):
Ask: "Should this load balancer be publicly accessible or internal (within a VPC only)?"
Options: `Public` / `Internal (VPC only)`

**Step 3 — LB name** (if not given):
Ask: "What would you like to name this load balancer?"
Options: suggest 2–3 names derived from the user's stated purpose. Always include `Enter a custom name` as the last option (free-text follow-up).

**Step 4 — plan** (run `lb plans` first, then ask):
Ask: "Which plan would you like?"
Options: one button per plan from `lb plans` output

**Step 5 — protocol** (if not given):
- For ALB: Ask: "Which protocol should the load balancer accept?" Options: `HTTP` / `HTTPS` / `HTTP + HTTPS`
- For NLB: skip — protocol is TCP

**Step 6 — port** (only for NLB):
Ask: "Which port should the load balancer listen on?" (free-text)

**Step 7 — SSL certificate** (only for ALB with HTTPS or HTTP + HTTPS — run `ssl list` first):
Ask: "Which SSL certificate would you like to use?"
Options: one button per certificate name plus `I don't have one yet`

**Step 8 — backend group name** (if not given):
Ask: "What would you like to call the backend group?" (free-text, e.g. `web`, `api`)

**Step 9 — backend group protocol** (only for ALB — if not given):
Ask: "Which protocol should traffic use when reaching your backend servers?"
Options: `HTTP` / `HTTPS`

**Step 10 — backend servers** (if not given — run `node list` first):
Ask: "Which servers should receive traffic?"
Options: one button per node showing `<node-name> — <private-ip>` plus `Add a custom server` (free-text follow-up asking for name, IP, and port separately)
After each selection ask: "Add another server?" Options: `Yes` / `No`

**Step 11 — traffic distribution** (if not given):
Ask: "How should traffic be spread across your backend servers?"
Options: `Round Robin — evenly spread` / `Least Connections — send to least busy` / `Source IP — same client always hits same server`

**Step 12 — reserved IP** (for public LBs — run `reserved-ip list` first):
Ask: "Would you like to assign a reserved IP to this load balancer?"
Options: one button per unattached reserved IP (showing the IP address) plus `No — assign automatically`

**Step 13 — VPC** (for internal LB only — run `vpc list` first):
Ask: "Which VPC should this load balancer run in?"
Options: one button per VPC name and CIDR
For public LB: do not ask. Only include `--vpc-id` if the user explicitly requests it.

**Security group:** Do not ask. The CLI attaches the region default automatically. Only include `--security-group` if the user explicitly specifies one.

**Step 14 — billing type** (if not given):
Ask: "How would you like to be billed?"
Options: `Hourly — pay as you go` / `Committed — save with a fixed term`

**Step 15 — committed plan** (only if committed billing chosen — from `lb plans` output):
Ask: "Which committed plan would you like?"
Options: one button per committed plan

**Step 16 — post-commit behavior** (only if committed billing chosen):
Ask: "What should happen when the committed term ends?"
Options: `Auto-renew` / `Switch to hourly billing`

**Step 17 — confirmation summary:**
Before running any command, display a summary of all selected options:

> Here's what will be created:
> - **Type:** `<ALB / NLB>`
> - **Visibility:** `<Public / Internal>`
> - **Name:** `<name>`
> - **Plan:** `<plan>`
> - **Protocol:** `<protocol>`
> - **Backend servers:** `<server list>`
> - **Algorithm:** `<algorithm>`
> - **Reserved IP:** `<ip or None>`
> - **VPC:** `<vpc name or None>`
> - **Billing:** `<hourly / committed plan>`

Ask: "Ready to create this load balancer?"
Options: `Yes, create it` / `No, go back`

If "No, go back" — ask which detail they'd like to change and loop back to that step.

Do not proceed to `lb create` until the user confirms with "Yes, create it".

## Discovery (required before create)

```bash
CLI lb plans --alias <alias>
```

## List And Inspect

```bash
CLI lb list --alias <alias>
CLI lb get <lbId> --alias <alias>
```

## Create ALB

`--port` defaults to `80` for HTTP and `443` for HTTPS/BOTH. Health checks are always on with check URL `/`.

```bash
CLI lb create \
  --name my-lb \
  --plan E2E-LB-2 \
  --frontend-protocol HTTP \
  --algorithm roundrobin \
  --backend-group-name web \
  --backend-group-protocol HTTP \
  --backend-group-server web-1:192.168.1.1:8080 \
  --backend-group-server web-2:192.168.1.2:8080 \
  --reserve-ip 203.0.113.10 \
  --security-group 42 \
  --alias <alias>
```

HTTPS/BOTH require `--ssl-certificate-id` from `e2ectl ssl list`:

```bash
CLI lb create \
  --name secure-lb \
  --plan E2E-LB-2 \
  --frontend-protocol HTTPS \
  --ssl-certificate-id 123 \
  --backend-group-name web \
  --backend-group-protocol HTTPS \
  --backend-group-server web-1:192.168.1.1:8443 \
  --alias <alias>
```

ALB protocols: frontend `HTTP`, `HTTPS`, `BOTH`; backend `HTTP`, `HTTPS`.

## Create NLB

`--port` is required for TCP. NLB has no backend protocol flag. Single backend group only.

```bash
CLI lb create \
  --name my-nlb \
  --plan E2E-LB-2 \
  --frontend-protocol TCP \
  --port 9000 \
  --backend-group-name tcp-main \
  --backend-group-server app-1:192.168.1.10:9000 \
  --backend-group-server app-2:192.168.1.11:9000 \
  --reserve-ip 203.0.113.10 \
  --alias <alias>
```

## Create Internal LB

Requires `--lb-type internal` and `--vpc-id`. Internal LBs have no public IP. Cannot use `--reserve-ip`.

```bash
CLI lb create \
  --name internal-lb \
  --plan E2E-LB-2 \
  --frontend-protocol HTTP \
  --lb-type internal \
  --vpc-id 123 \
  --backend-group-name web \
  --backend-group-protocol HTTP \
  --backend-group-server web-1:192.168.1.1:8080 \
  --alias <alias>
```

External LBs can optionally attach to VPC with `--vpc-id`. Both `--vpc-id` and `--reserve-ip` can be used together on external LBs.

## Update LB

```bash
CLI lb update <lbId> --name new-name --alias <alias>
CLI lb update <lbId> --frontend-protocol HTTPS --ssl-certificate-id 123 --alias <alias>
CLI lb update <lbId> --frontend-protocol BOTH --ssl-certificate-id 123 --redirect-http-to-https --alias <alias>
CLI lb update <lbId> --ssl-certificate-id 456 --alias <alias>
```

ALBs can move among `HTTP`/`HTTPS`/`BOTH`. NLBs stay `TCP`. `--redirect-http-to-https` valid only with `BOTH`.

## Network Attachments

```bash
CLI lb network reserve-ip reserve <lbId> --alias <alias>
CLI lb network vpc attach <lbId> --vpc-id <vpcId> --alias <alias>
CLI lb network vpc attach <lbId> --vpc-id <vpcId> --subnet <subnetId> --alias <alias>
CLI lb network vpc detach <lbId> --vpc-id <vpcId> --alias <alias>
```

Reserve-IP: preserves the LB's current public IP. Only works if a public IP is assigned.

## Backend Groups

```bash
CLI lb backend group list <lbId> --alias <alias>

CLI lb backend group add <lbId> \
  --backend-group-name api \
  --backend-group-protocol HTTP \
  --backend-group-server api-1:192.168.2.1:9000 \
  --alias <alias>

CLI lb backend group update <lbId> web \
  --backend-group-protocol HTTPS \
  --algorithm leastconn \
  --alias <alias>

CLI lb backend group update <lbId> web \
  --backend-group-name web-v2 \
  --alias <alias>

CLI lb backend group remove <lbId> api --alias <alias>
```

Cannot remove the last backend group. Backend group names must be unique across the LB.

## Backend Servers

Syntax: `name:ip:port` (e.g. `web-1:192.168.1.1:8080`). The **name** is a label — it does not need to match a hostname. The **IP** can be any reachable IP (E2E node private IP, external server, etc.) — `node list` is a suggestion, not a requirement.

```bash
CLI lb backend server add <lbId> \
  --backend-group-name web \
  --backend-group-server web-3:192.168.1.3:8080 \
  --alias <alias>

CLI lb backend server remove <lbId> \
  --backend-group-name web \
  --backend-group-server-name web-3 \
  --alias <alias>
```

Cannot remove the last server from a group. Server names must be unique within a group; backend group names must be unique across the LB.

There is no update command for backend servers. To change a server (IP, port, or name), remove the old server and add the updated one.

## Load Balancing Algorithms

| Algorithm | Behavior |
|---|---|
| `roundrobin` (default) | Even distribution across servers in rotation |
| `leastconn` | Server with fewest active connections |
| `source` | Client IP-based session persistence |

Set at create with `--algorithm <algo>` or update with `lb backend group update <lbId> <groupName> --algorithm <algo>`.

## Billing Options

Default is hourly. For committed:

```bash
# By plan name
CLI lb create ... --billing-type committed --committed-plan "90 Days" --post-commit-behavior auto-renew --alias <alias>

# By plan ID
CLI lb create ... --billing-type committed --committed-plan-id 901 --post-commit-behavior hourly-billing --alias <alias>
```

`--post-commit-behavior`: `auto-renew` or `hourly-billing`. Cannot use `--committed-plan` and `--committed-plan-id` together.

## Delete

```bash
CLI lb delete <lbId> --force --alias <alias>
CLI lb delete <lbId> --force --reserve-public-ip --alias <alias>
```

Ask for confirmation once. When confirmed, always use `--force`. `--reserve-public-ip` preserves the LB public IP as a reserved IP.

## Rules

- Run `lb plans` before create — never skip discovery
- Backend server IPs: suggest using `node list` for E2E node private IPs, but any reachable IP works (external servers, manual IPs, etc.)
- Backend server names: labels only — no need to match hostnames or node names
- Use `reserved-ip list` to find unattached reserved IPs for `--reserve-ip`
- Use `security-group list` for `--security-group`
- `--plan` must match exact plan name from `lb plans` output
- HTTPS/BOTH require `--ssl-certificate-id` from `e2ectl ssl list`
- NLB: single backend group, no backend protocol, `--port` required
- Internal LB: requires `--lb-type internal` and `--vpc-id`, no `--reserve-ip`
- Managed LB — you cannot SSH into an LB or its backend nodes through the LB
- `lb network reserve-ip reserve` only works when the LB has a public IP assigned
- VPC attach/detach only works on a `Running` LB — poll `lb get` first
- If an API call fails, retry once after a 1-minute interval. If it fails again, tell the user the exact API error.

## Polling

After create, poll `lb get` until the LB is `Running`. Do not attempt backend group/server actions or VPC attach/detach while the LB is still provisioning.

## Error Recovery

| Error | Cause | Fix |
|---|---|---|
| 412 on `lb create` | Plan name mismatch | Re-run `lb plans`, use exact plan name |
| NLB multiple backend groups | NLB supports only one backend group | Use single `--backend-group-*` set |
| Last backend group not deletable | Must keep at least one | Create new group first if replacement needed |
| Last backend server not deletable | Must keep at least one server per group | Add new server first if replacement needed |
| Duplicate backend server name | Server names must be unique within group | Use unique server name |
| Reserved IP not found/available | IP doesn't exist or is already attached | Run `reserved-ip list`, pick unattached IP |

## Output Rules

- List: id, name, type (ALB/NLB), frontend protocol, public IP, status
- Detail: add plan, backend groups, backend servers, VPC, reserved IP
- After create: show public IP or endpoint
- After any action: confirm with follow-up `lb get`
- Do not show raw JSON unless asked

## Related References

- `references/reserved-ip.md` — for `--reserve-ip`
- `references/security-group.md` — for `--security-group`
- `references/vpc.md` — for `--vpc-id`

