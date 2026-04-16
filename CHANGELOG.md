# Changelog

All notable changes to `e2enetworks-skills` are documented here.

## [Unreleased]

### Changed
- Fixed `&&` chain contradiction in SKILL.md permission rules
- Added `schema_version` field to state file schema
- Added error recovery tables to `nodes.md` and `vpc.md`
- Fixed `security-group update` to document required `--name` flag
- Fixed stdin pipe pattern in `nodes.md` (use `--public-key-file` directly)
- Added `docs-index.md` with verified E2E documentation URLs (`GettingStarted/index` omitted — returns 404 in browser)
- Added CI workflow (regression tests + docs URL validation)
- Updated CONTRIBUTING.md file tree to reflect actual reference files
