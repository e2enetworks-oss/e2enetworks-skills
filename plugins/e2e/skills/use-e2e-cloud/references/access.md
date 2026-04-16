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

Import command:

```bash
CLI config import \
  --file <path> \
  --default <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

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

After the profile is resolved, list projects for the account:

```bash
CLI project list --alias <alias>
```

Present the returned projects as a button-style `AskUserQuestion`:

- question: `Which project should be used as the default?`
- options: one button per project showing `<project-name> (id: <project-id>)`
- include one extra option: `Enter project ID manually`

If the user selects `Enter project ID manually`, ask:

- question: `Please enter your project ID:`
- accept free-text input

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
