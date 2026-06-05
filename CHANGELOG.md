# Changelog

All notable changes to `e2enetworks-skills` are documented here.

## [0.2.3] - 2026-06-04

### Added

- Support ticket reference (`references/support-ticket.md`): create, list and filter, get, read reply threads, reply with attachments, close, reopen, and review a ticket's timeline — including department discovery, category rules, SOC/Abuse routing, and an interactive "Missing Specs" create flow
- Support ticket entries in the `SKILL.md` Capability Index and References list, and in the mid-session "what can you do" capability summary
- "Offer a Ticket After a Failure" flow — when an operation fails and recovery is exhausted, the skill offers to open a support ticket pre-filled with the failure context (action, error, affected resources, project/location, time)

## [0.2.2] - 2026-05-15

### Changed

- Mid-session "what can you do" replies now summarize the skill's actual E2E capabilities (nodes, images, reserved IPs, volumes, VPCs, security groups, load balancers, DBaaS, app deployment, cost estimation, profile/project/location setup) instead of repeating the initial greeting. Section 8a first-load greeting is unchanged.

## [0.2.1] - 2026-05-15

### Added

- Multi-token handling in the access flow — when the downloaded config JSON contains more than one token, the skill now asks which one to import (token names only, secrets masked)
- `Versioning` section in `CONTRIBUTING.md` documenting both `VERSION` files, when to bump MAJOR/MINOR/PATCH, and the release checklist
- `VERSION` file at the repo root as the installer's source of truth

### Changed

- README quickstart clarifies the "Download Tokens" flow and the Read + Write permission requirement
- `access.md` "no config" prompt updated to match the new token download flow

## [0.2.0] - 2026-05-07

### Added

- Saved image management workflows (`references/image.md`): list, rename, delete, create node from saved image
- DBaaS reference (`references/dbaas.md`): MariaDB / MySQL / PostgreSQL clusters, networking, whitelisting, password management
- Load balancer reference (`references/load-balancer.md`): ALB, NLB, internal LB, backend groups, SSL, reserved IP, VPC
- Cost estimation reference (`references/cost-estimation.md`)
- Interactive "Missing Specs" flows for node, load balancer, DBaaS, and VPC creation — guided natural-language prompts with a confirmation summary before provisioning
- Section 0 version-check mechanism in `SKILL.md` with a simple Yes/No upgrade prompt
- Hard rule for unsupported actions: skill points users to E2E Cloud MyAccount only after exhausting CLI options

### Changed

- Section 0e upgrade prompt simplified from 4 options (Upgrade now / Snooze 24h / Snooze 7 days / Skip) to Yes / No
- Removed `## Docs` sections and inline docs links from all reference files
- Region default is used automatically for security groups in node and LB creation — never asked
- VPC and reserved IP flows reordered for natural conversation: node and LB now ask about both with a list of available resources
- Load balancer creation flow now asks ALB vs NLB first as the type-differentiating question
- DBaaS admin username always asked, with `admin` as the suggested default

### Removed

- `WebFetch(https://docs.e2enetworks.com/*)` permission from skill `Allowed Tools` (no longer used)
- Docs link from `CONTRIBUTING.md`

## [0.1.0] - 2026-04-17

### Changed

- Fixed `&&` chain contradiction in SKILL.md permission rules
- Added `schema_version` field to state file schema
- Added error recovery tables to `nodes.md` and `vpc.md`
- Fixed `security-group update` to document required `--name` flag
- Fixed stdin pipe pattern in `nodes.md` (use `--public-key-file` directly)
- Added CI workflow (regression tests)
- Updated CONTRIBUTING.md file tree to reflect actual reference files
