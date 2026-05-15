# Contributing

Thanks for your interest in contributing to `e2enetworks-skills`.

## Repository structure

```text
e2enetworks-skills/
├── plugins/e2e/
│   └── skills/
│       └── use-e2e-cloud/
│           ├── SKILL.md
│           ├── VERSION
│           ├── scripts/
│           │   └── e2ectl-run.sh
│           └── references/
│               ├── access.md
│               ├── cost-estimation.md
│               ├── dbaas.md
│               ├── deploy.md
│               ├── image.md
│               ├── load-balancer.md
│               ├── nodes.md
│               ├── project.md
│               ├── reserved-ip.md
│               ├── security-group.md
│               ├── volume.md
│               └── vpc.md
├── scripts/
│   └── install.sh
├── tests/
│   └── regression.sh
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows/
│       └── ci.yml
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── VERSION
```

## Development notes

- Keep `SKILL.md` concise and routing-focused.
- Keep workflow behavior in action-oriented references.
- Keep deep schema and reference material separate from runbooks.
- User-facing prompts must speak in natural language — never expose CLI flag names, formats, or syntax to the user.

## Versioning

This repo follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`).

### Version files

Two `VERSION` files must stay in sync — both contain a single line with the current version:

- `VERSION` — repo root, the source of truth checked by the installer.
- `plugins/e2e/skills/use-e2e-cloud/VERSION` — copied into every install path (`~/.claude/skills/...`, `~/.codex/skills/...`, etc.) and read by the skill at session start for the upgrade check.

The skill's session-start upgrade check (see `SKILL.md` Section 0) compares the installed `VERSION` against the raw `VERSION` file on `main` and prompts the user to upgrade when they differ.

### When to bump

- **PATCH** (`0.2.0` → `0.2.1`) — bug fixes, wording tweaks, doc-only changes, prompt clarifications that don't change behavior.
- **MINOR** (`0.2.0` → `0.3.0`) — new workflows, new reference files, new commands surfaced through the skill, additive UX changes.
- **MAJOR** (`0.2.0` → `1.0.0`) — breaking changes to the install layout, removed/renamed references, or any change that requires users to re-import their config or re-install.

### Release checklist

1. Update both `VERSION` files to the new version (they must match exactly).
2. Add a new entry at the top of `CHANGELOG.md` under the new version heading.
3. Commit with a message like `Release v<x.y.z>`.
4. Open a PR to `main`; once merged, the new `VERSION` on `main` triggers the upgrade prompt for existing users on their next session.

### CLI version (separate)

The `@e2enetworks-oss/e2ectl` npm CLI is versioned independently and published from its own repo. The skill checks CLI freshness reactively — see `references/access.md` Step 2b — and never pins a CLI version.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
