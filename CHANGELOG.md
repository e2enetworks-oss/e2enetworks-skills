# Changelog

All notable changes to `e2enetworks-skills` are documented here.

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
