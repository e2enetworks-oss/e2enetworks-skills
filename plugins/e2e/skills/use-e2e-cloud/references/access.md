# Access

In this file, `CLI` means `e2ectl` (global) or `npx e2ectl` (project-local).

Do not use repeated `--help` calls for the commands listed here. Use these directly.

## Step 1 — Check Node.js

Before checking for `e2ectl`, verify that `npm` is available:

```bash
which npm
```

If `npm` is not found, stop and ask the user to install Node.js first:

```
npm is not installed. Please install Node.js from https://nodejs.org (LTS recommended),
then reopen your terminal and try again.
```

Do not proceed until `npm` is available.

## Step 2 — Resolve CLI

Check if `e2ectl` is already installed:

```bash
which e2ectl
```

If not found, ask the user via the `AskUserQuestion` tool (button-style — never plain text):

- question: `e2ectl CLI is not installed. How should I install it?`
- header: `Install e2ectl`
- options:
  - `Global` — `npm install -g @e2enetworks-oss/e2ectl` (available system-wide as `e2ectl`)
  - `Project` — `npm i @e2enetworks-oss/e2ectl` (used via `npx e2ectl`)

Run the matching `npm` command. If project-local, use `npx e2ectl` for all later commands.

## Step 3 — Resolve Config

Start with:

```bash
CLI config list
```

Profiles are stored in `~/.e2e/config.json`.

If profiles already exist, ask the user via `AskUserQuestion` (button-style):

- question: `Saved profiles found. What would you like to do?`
- options:
  - `Use existing profile` — proceed with profile selection
  - `Import new profile` — go to import flow

If no usable config exists, ask via `AskUserQuestion` (button-style):

- question: `No config found. To get your credentials, go to E2E MyAccount → API & IAM: https://myaccount.e2enetworks.com/services/apiiam — create an API token and download the config JSON. Then choose how to import it:`
- options:
  - `Use a config file on this machine` — ask for the file path, then import
  - `Upload a config file` — ask the user to provide the file, then import

Import command — always use `--file`, never pass the path as a bare argument:

```bash
CLI config import \
  --file "<path>" \
  --default <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

**Overwrite error:** If the command returns `Import would overwrite existing aliases: <alias>`, ask the user via `AskUserQuestion`:

- question: `A saved profile named "<alias>" already exists. Overwrite it with the new config?`
- options:
  - `Yes, overwrite` — re-run with `--force`
  - `No, keep the existing profile` — skip import and use the existing alias

If the user chooses overwrite, add `--force` to the same command and re-run. Do not use `--help` on import failures — the flag syntax above is correct.

## Step 4 — Select Default Profile (multiple aliases)

If `config list` returns more than one saved profile (alias), ask the user via
`AskUserQuestion` (button-style) which one to use as the default:

- question: `Multiple profiles found. Which one should be used as the default?`
- options: one button per alias showing `<alias>` (mask any key/token values in display)
- include one extra option: `Import a new profile`

If only one profile exists, use it automatically without prompting.

After the user selects an alias, set it as the default:

```bash
CLI config set-default --alias <alias>
```

Each profile may contain multiple credentials (auth token, API key, or both).
If the selected profile has more than one credential entry, ask the user which
to treat as active for this session:

- question: `This profile has multiple credentials. Which should be used?`
- options: one button per credential type, e.g. `Auth Token` / `API Key`
- mask all secret values in the display — show type label only

## Step 5 — Select Default Project

After the profile is resolved, list all projects for the account:

```bash
CLI project list --alias <alias>
```

Print every project as a plain text summary so the user can see all of them:

```
Your projects:
  48660  normaDbaaS            ← previously used CLI default
  48103  default-project-42526
  51234  my-other-project
  ...
```

Mark the previously-used CLI default with `← previously used CLI default` if one exists.

Do NOT use one button per project — `AskUserQuestion` supports a maximum of 4 options and most accounts have more projects than that. Use this fixed layout instead:

- question: `Which project ID should be the default? (see the list above)`
- options:
  - `<id> — <name> (Recommended)` — the previously-used CLI default, if one exists
  - `<id> — <name>` — the account default project, if different from the above
  - `Enter a different ID` — for any other project shown in the list above

If the user selects `Enter a different ID`, ask as a follow-up free-text prompt:

- question: `Enter the project ID from the list above:`

## Step 6 — Select Location

After the project is selected, ask for the default location via `AskUserQuestion` (button-style):

- question: `Which location should be used as the default?`
- options:
  - `Delhi`
  - `Chennai`

## Step 7 — Save Context

Once project and location are chosen, save them on the profile:

```bash
CLI config set-context \
  --alias <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

Confirm to the user: profile alias, project id, and location are now set.

## Step 8 — Error Handling

If any resource command returns:

```
Profile "<alias>" was not found.
```

Stop immediately and re-run the config flow from Step 3 before continuing.

If the user switched accounts or imported a new profile, re-run Step 4 (profile
selection) and Step 5 (project selection) to re-establish the correct context.

If `config set-context` is called but project id or location is still missing,
prompt for both before running any resource command.

## Config Commands Reference

List profiles:

```bash
CLI config list
```

Update project or location on an existing alias:

```bash
CLI config set-context \
  --alias <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

Set default alias:

```bash
CLI config set-default --alias <alias>
```

Remove a profile:

```bash
CLI config remove --alias <alias>
```

## Output Rules

- mask API keys and secrets in all output
- use `--json` only when parsing output programmatically
- after setup is complete, summarize: alias, project id, location — one line each

## Docs

- Official documentation: https://docs.e2enetworks.com/docs/myaccount/GettingStarted/iam
