# Support Ticket

In this file, `CLI` means the resolved command from `SKILL.md`.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## Overview

Support tickets let the user raise, track, and resolve MyAccount support requests from
the terminal: open a ticket, list and filter existing tickets, read the reply thread,
post replies with attachments, close, reopen, and review a ticket's activity timeline.

- Tickets are **project- and location-scoped** — they belong to the active project and
  location. Use a saved default project/location context, or pass `--project-id` and
  `--location` explicitly alongside `--alias`.
- `create` requires a numeric **department id**, which is account-specific. Always run
  `support-ticket departments` first to discover valid ids — never guess one.
- **SOC** and **Abuse** tickets are tracked in separate tables and are **view-and-reply
  only**: you can view them (`get`, `get-replies`) and reply (`reply`) by adding
  `--soc-ticket` or `--abuse-ticket`, but they cannot be created, closed, or reopened
  through this skill. The two flags are mutually exclusive.

## Limits

| Field                          | Limit                                                                 |
| ------------------------------ | --------------------------------------------------------------------- |
| Subject                        | ≤ 60 characters, printable ASCII only                                 |
| Description                    | ≤ 6000 characters                                                     |
| Reply / close / reopen comment | ≤ 250 characters                                                      |
| Attachments                    | `.jpg`, `.jpeg`, `.png`, `.pdf` only — ≤ 5 MB each, max 5 per request |

## Allowed Values

- **Create categories:** `Cloud`, `Billing`, `Sales`
- **Filter categories** (`list --category`): `Cloud`, `Billing`, `Sales`, `SOC`, `Abuse`
- **Priority:** `High`, `Medium`, `Low`
- **Status** (`list --status`): `New`, `Open`, `On Hold`, `Waiting on Customer`, `Escalated`, `Resolved`, `Closed` — plus presets `open` (Open, On Hold, Waiting on Customer, Escalated) and `resolved` (Resolved, Closed)
- **Priority filter preset** (`list --priority`): `urgent` (High, Medium)
- **Contact type:** `Technical Lead`, `Billing`, `Manager`, `Admin`

### Category Rules for `create`

| Category | `--component` | `--priority`       | `--resource` |
| -------- | ------------- | ------------------ | ------------ |
| Cloud    | Required      | Required           | Allowed      |
| Billing  | Required      | Required           | Not allowed  |
| Sales    | Optional      | Optional (ignored) | Not allowed  |

## Commands

Discover department ids (run this before `create`):

```bash
CLI support-ticket departments --alias <alias>
```

List tickets:

```bash
CLI support-ticket list --alias <alias>
```

Filter the list (repeat any filter flag to combine values):

```bash
CLI support-ticket list --status open --priority urgent --alias <alias>
CLI support-ticket list --category Cloud --category Billing --year 2026 --alias <alias>
CLI support-ticket list --page-no 2 --per-page 25 --alias <alias>
```

Get one ticket's details:

```bash
CLI support-ticket get <ticket-id> --alias <alias>
```

Read the full reply thread (original description plus every follow-up):

```bash
CLI support-ticket get-replies <ticket-id> --alias <alias>
```

Open a new ticket:

```bash
CLI support-ticket create \
  --department <department-id> \
  --subject "<subject>" \
  --description "<description>" \
  --ticket-category Cloud \
  --component "<service-or-component>" \
  --priority Medium \
  --alias <alias>
```

Reply to a ticket (add `--attachment <file>`, repeatable, for screenshots or documents):

```bash
CLI support-ticket reply <ticket-id> --comment "<reply-body>" --alias <alias>
```

Close a ticket (posts the comment and resolves it in one call):

```bash
CLI support-ticket close <ticket-id> --comment "<closing-comment>" --alias <alias>
```

Reopen a closed ticket:

```bash
CLI support-ticket reopen <ticket-id> --comment "<reason-for-reopening>" --alias <alias>
```

Review a ticket's activity timeline (creation, status changes, comments):

```bash
CLI support-ticket timeline <ticket-id> --alias <alias>
CLI support-ticket timeline <ticket-id> --month 5 --year 2026 --alias <alias>
```

`--month` (1-12) and `--year` are optional filters.

## Optional Flags

- `--cc <email>` on `create` — repeat for multiple CC addresses.
- `--resource <id:name[:ip]>` on `create` — Cloud tickets only; repeat to link multiple resources. The CLI rejects `--resource` on Billing and Sales tickets.
- `--contact-email <email>` and `--contact-type <type>` on `create`, `get`, `get-replies`,
  `reply`, `close`, and `reopen` — when omitted, MyAccount uses the account owner as the
  contact person.
- `--channel <channel>` on `create` and `reply` — origin/reply channel (defaults to `Web`).
- `--priority-ticket` on `create` — mark the ticket as a priority (chat) ticket.
- `--soc-ticket` / `--abuse-ticket` on `get`, `get-replies`, `reply` — route to the SOC or
  abuse table (mutually exclusive).

## Missing Specs — Create Flow

When the user wants to open a ticket but hasn't given everything, gather the required
fields one question at a time with `AskUserQuestion`, then confirm before submitting:

1. **Department** — run `support-ticket departments` and present the department names as
   options; map the chosen name back to its id. Never ask the user for a raw id.
2. **Category** — `Cloud`, `Billing`, or `Sales`.
3. **Subject** — a short summary (≤ 60 characters).
4. **Description** — what's happening, since when, and any impact.
5. **Component** — required for Cloud and Billing; the affected service or area.
6. **Priority** — required for Cloud and Billing; `High`, `Medium`, or `Low`.
7. **Resources** (Cloud only — optional) — offer to link affected nodes/resources.

Show a one-line confirmation summary (department, category, subject, priority) before
running `create`.

## Common Workflows

Open a Cloud ticket linked to affected nodes:

```bash
CLI support-ticket departments --alias <alias>
# choose the department, note its id
CLI support-ticket create \
  --department <department-id> \
  --subject "Node 4567 reachability" \
  --description "Node has been unreachable since 14:00 IST." \
  --ticket-category Cloud \
  --component "Compute" \
  --priority High \
  --resource 4567:web-node-1:203.0.113.10 \
  --resource 4568:web-node-2 \
  --alias <alias>
```

Open a Billing ticket with CCs and an attached invoice:

```bash
CLI support-ticket create \
  --department <department-id> \
  --subject "Invoice clarification for April 2026" \
  --description "Please review the highlighted line items in the attached invoice." \
  --ticket-category Billing \
  --component "Invoicing" \
  --priority Medium \
  --cc finance@example.com \
  --cc cfo@example.com \
  --attachment ./invoice-2026-04.pdf \
  --alias <alias>
```

Reply to a ticket with a screenshot:

```bash
CLI support-ticket reply <ticket-id> \
  --comment "See the attached screenshot from the dashboard." \
  --attachment ./dashboard.jpg \
  --alias <alias>
```

Check on open, urgent tickets:

```bash
CLI support-ticket list --status open --priority urgent --alias <alias>
```

Work with a SOC or Abuse ticket:

```bash
CLI support-ticket get <ticket-id> --soc-ticket --alias <alias>
CLI support-ticket get-replies <ticket-id> --abuse-ticket --alias <alias>
CLI support-ticket reply <ticket-id> --abuse-ticket --comment "..." --alias <alias>
```

## Offer a Ticket After a Failure

When another workflow in this skill fails and recovery is exhausted — a node won't
provision, an attach keeps erroring, an API call returns a server-side error the user
can't resolve — offer to open a support ticket on their behalf instead of leaving them
stuck. This is the bridge from a failed action to getting help from E2E support.

1. First report the failure in plain language (what broke, why, what was tried).
2. Then ask with `AskUserQuestion`: "Want me to open a support ticket for this?" — `Yes` / `No`.
3. On **Yes**, pre-fill `create` from the failure context you already have — never make the
   user re-type details you can see:
   - **Category** — `Cloud` for node/volume/VPC/LB/DBaaS failures and any
     connectivity/reachability issue, `Billing` for billing or quota errors, else ask.
   - **Component** — the service that failed (e.g. `Compute`, `Block Storage`, `Load Balancer`).
   - **Subject** — a one-line summary of the failure (≤ 60 chars), e.g. "Node 4567 stuck
     in Provisioning".
   - **Description** — the action attempted, the exact error message, affected resource
     ids/names, the project and location, and the time it occurred.
   - **Resource** — link the affected resource(s) as `id:name[:ip]`. Cloud tickets only;
     the CLI rejects `--resource` on other categories.
   - **Priority** — suggest `High` for an outage or stuck resource, `Medium` otherwise.
   - **Department** — run `support-ticket departments` and ask the user to pick.
4. Show the pre-filled subject, category, and priority for confirmation before submitting,
   then run `create` and report the new ticket id and number.

Only offer this once per failure — if the user declines, don't re-prompt.

## Output Rules

- after list, show ticket id, number, subject, status, priority, and category — plus the
  page summary (open count, resolved count, urgent count, total) when present
- after create, show the new ticket's id and number and suggest replying or checking its status
- after get-replies, summarize the thread (author, channel, attachments) in plain language
- after reply, close, or reopen, confirm the action and the ticket it applied to
- after timeline, list the events in chronological order
- if a ticket was created but its full detail couldn't be loaded, tell the user it was
  created and that its details can be fetched with a follow-up `get`
- do not show raw JSON unless asked
