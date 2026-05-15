# Cost Estimation

In this file, `CLI` means the resolved command from `SKILL.md`.

Use this reference when a user asks about pricing, wants an estimate, or is comparing options. Always run the relevant plans commands below — never guess prices.

## Pricing Model

E2E resources support two billing modes:

| Mode | How it works |
|---|---|
| **Hourly** | Pay-as-you-go. Billed per hour of usage. Cancel anytime. |
| **Committed** | Upfront commitment for a term (e.g. 30/90/180/365 days). Lower hourly-equivalent rate. `auto-renew` or `hourly-billing` at term end. |

All `plans` commands show hourly rates by default. Committed plan IDs and durations appear in the same output when available.

## Service Plans Commands

Run these to get real-time pricing for each service:

### Nodes (Compute)

```bash
# Step 1 — pick OS
CLI node catalog os --alias <alias>

# Step 2 — see all plans with pricing for that OS
CLI node catalog plans \
  --alias <alias> \
  --display-category "<value-from-os-output>" \
  --category "<value-from-os-output>" \
  --os "<value-from-os-output>" \
  --os-version "<value-from-os-output>" \
  --billing-type all
```

Shows: plan name, vCPUs, RAM, SSD, hourly price, committed plan IDs.

### Load Balancers (ALB/NLB)

```bash
CLI lb plans --alias <alias>
```

Shows: plan name, hourly price, committed plan IDs.

### DBaaS (Managed Database)

```bash
# Step 1 — discover types
CLI dbaas types --alias <alias>

# Step 2 — see plans for a specific type + version
CLI dbaas plans --type <type> --db-version <version> --alias <alias>
```

Shows: plan name, vCPUs, RAM, hourly price, committed SKU IDs.

### Block Storage (Volumes)

```bash
CLI volume plans --alias <alias>
```

Shows: available sizes, IOPS, hourly price per size.

Filter to a specific size or only currently available:

```bash
CLI volume plans --size <size-gb> --alias <alias>
CLI volume plans --available-only --alias <alias>
```

### VPC Networks

```bash
CLI vpc plans --alias <alias>
```

Shows: plan name, hourly price, committed plan IDs.

### Reserved IPs

Reserved IPs have a fixed price (no plans command needed):
- **INR:** ₹199/month
- **USD:** $3/month

Non-E1 nodes include a bundled reserved IP at no extra cost.

## Estimation Workflow

When a user wants a cost estimate:

1. **Ask what services they need** — node(s), load balancer, database, storage, VPC, reserved IPs
2. **Run the relevant plans command** for each service
3. **Summarize** the total estimated monthly cost (hourly rate × 730 hours) or committed cost
4. **Show a breakdown** — one line per resource with plan name and monthly estimate

### Quick Estimate (no plans commands yet)

If the user just wants a ballpark before running discovery, ask:

- What size node? (e.g. "2 vCPU / 4 GB RAM")
- What other services?
- Hourly or committed?

Then run the plans commands to give exact numbers.

## Output Rules

- Always run the plans command before giving price numbers
- Never guess VPC cost — always run `vpc plans` to get real pricing
- Show: resource type, plan name, specs, hourly rate, monthly estimate (×730)
- For committed: show term length and total upfront cost
- Present as a clean table or bullet list — never raw JSON
- If a price seems off, re-run the plans command to confirm
- Mention that reserved IPs are bundled with non-E1 nodes (no extra cost)
