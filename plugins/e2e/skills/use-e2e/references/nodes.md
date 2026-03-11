# Nodes

## Purpose
Use this guide for safe day-to-day node listing, inspection, creation, and deletion after the CLI and config are ready.

## Readiness Gate
Before any node command:
```bash
e2ectl --help
e2ectl config list
```

If saved profiles already exist, ask whether to use an existing profile or add/import a new one before asking for credentials.

If the user selects an existing alias but it is missing project or location defaults, update that alias with `e2ectl config set-context`.

If configuration is missing or unusable and there is no usable saved profile, prompt for every required field before continuing:
- alias
- api key
- auth token
- default project id
- default location

If configuration is usable and the user wants to create a node, prompt for these inputs before catalog discovery:
- node name
- location
- project

Suggested defaults:
- node name: `node-01`
- location: current configured profile location, otherwise `Delhi`
- project: current configured profile project ID when available

Use defaults only as suggestions. Let the user override them.

## List Nodes
```bash
e2ectl node list --json
```

If the active profile does not have the needed default project/location, use overrides:
```bash
e2ectl node list --project-id <project-id> --location <location> --json
```

## Get Node Details
```bash
e2ectl node get <node-id> --json
```

## Discover Valid Create Inputs
List OS options first:
```bash
e2ectl node catalog os --json
```

Then list valid plan and image combinations:
```bash
e2ectl node catalog plans \
  --display-category "<display-category>" \
  --category "<category>" \
  --os "<os>" \
  --os-version "<os-version>" \
  --project-id <project-id> \
  --location <location> \
  --json
```

If one valid OS row returns an unexpected response-shape error, summarize the failure and retry with another row instead of immediately concluding the API is unusable.

## Create a Node
Create only after the user has selected the exact plan and image values returned by the catalog:
```bash
e2ectl node create \
  --name <node-name> \
  --plan <full-plan-string> \
  --image <image> \
  --project-id <project-id> \
  --location <location> \
  --json
```

## Create Flow
1. Verify CLI and config.
2. Ask for node name. Suggested default: `node-01`.
3. Ask for location. Suggested default: current configured profile location, otherwise `Delhi`.
4. Ask for project. Suggested default: current configured profile project ID when available.
5. If the requested location or project does not match the active profile, switch to or create the correct profile first.
6. Show OS choices from `catalog os`.
7. Show plan and image choices from `catalog plans`.
8. Confirm the final create command once before launch.

## Delete Policy
- Always list or inspect the node first.
- Always confirm with the user before running delete.
- Use the exact node ID chosen by the user.

## Delete Command
```bash
e2ectl node delete <node-id> --project-id <project-id> --location <location> --json
```

## Delete Flow
1. Run `e2ectl node list --json`.
2. Confirm the target node ID with the user.
3. State the exact delete command that will be executed.
4. Run delete only after explicit approval.

## Notes
- Prefer `--json` when parsing CLI output.
- Use the full `plan` string returned by the catalog, not the short SKU label.
- `node create`, `node get`, `node list`, `node delete`, and `catalog plans` support `--project-id` and `--location` overrides.
- List nodes before and after create to confirm the result.
- Treat delete as irreversible unless the platform explicitly documents recovery.
- Capture delete results for auditability when possible.
- Do not show raw API calls or raw JSON by default; convert command results into readable user-facing output.
- Show raw JSON only when the user explicitly asks for raw output.
- Do not show API keys or bearer tokens in user-facing output.
