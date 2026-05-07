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

### 2a. Check whether `e2ectl` is installed

```bash
which e2ectl
```

If not found, ask the user via `AskUserQuestion` (button-style — never plain text):

- question: `e2ectl CLI is not installed. How should I install it?`
- header: `Install e2ectl`
- options:
  - `Global` — `npm install -g @e2enetworks-oss/e2ectl` (available system-wide as `e2ectl`)
  - `Project` — `npm i @e2enetworks-oss/e2ectl` (used via `npx e2ectl`)

Run the matching `npm` command. If project-local, use `npx e2ectl` for all later commands.

### 2b. Ensure the installed CLI is up to date

If `e2ectl` was already installed, verify it is current. Cache the result for 24 hours so this isn't a per-session network call.

1. Read the cache `~/.e2e/.cli-version-check.json` (`{ "checked_at": "<iso8601>", "result": "up-to-date|upgrade-available", "installed": "<x.y.z>", "latest": "<x.y.z>" }`). If `checked_at` is within **24 hours**, trust `result` and skip the rest of 2b.

2. Otherwise compare versions:
   ```bash
   e2ectl --version       # or: npx e2ectl --version
   npm view @e2enetworks-oss/e2ectl version
   ```
   If either command fails (no network, npm outage), **fail open** — proceed silently with whatever is installed and don't write the cache.

3. Compare semver by splitting on `.`:
   - `installed >= latest` → write cache with `result: "up-to-date"`, TTL 24h, proceed silently.
   - `installed < latest` → ask via `AskUserQuestion`:
     - question: `Your e2ectl CLI is **v<installed>**; the latest is **v<latest>**. Update now? Some skill features may depend on newer flags.`
     - options: `Yes, update` / `No, continue with current version`
   - On `Yes`: re-run the same install command the user originally chose (`npm install -g @e2enetworks-oss/e2ectl@latest` for Global, `npm i @e2enetworks-oss/e2ectl@latest` for Project). After install, write cache with `result: "up-to-date"`.
   - On `No`: write cache with `result: "upgrade-available"` and TTL 24h, then proceed. The user keeps working but is on notice.

4. If a later command fails with an "unknown flag" / "unknown command" / "unrecognized argument" error and the cache shows `upgrade-available`, surface in plain language: "This command needs a newer e2ectl. Run the update prompt? It usually takes ~10 seconds." Then offer the same Yes/No.

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

**Important — what this list does and doesn't include:**

`project list` only returns projects **owned by this account**. If the user has been added to another account's project via **IAM** (Identity & Access Management), that project **will not appear** here even though they can use it. To work in an IAM-shared project, the user must enter its numeric project ID manually — they can get it from the project owner or from the project page in E2E MyAccount.

Always communicate this to the user before asking them to pick a project. Print the list with a short note, like:

```
Your projects (owned by this account):
  48660  normaDbaaS            ← previously used CLI default
  48103  default-project-42526
  51234  my-other-project
  ...

If you've been added to another account's project via IAM, it won't appear above —
choose "Enter a project ID manually" below and paste the ID from the project owner
or from E2E MyAccount.
```

Mark the previously-used CLI default with `← previously used CLI default` if one exists.

Do NOT use one button per project — `AskUserQuestion` supports a maximum of 4 options and most accounts have more projects than that. Use this fixed layout instead:

- question: `Which project should be the default? (see the list above)`
- options:
  - `<id> — <name> (Recommended)` — the previously-used CLI default, if one exists
  - `<id> — <name>` — the account default project, if different from the above
  - `Pick another from the list above` — for any other project owned by this account
  - `Enter a project ID manually` — for an IAM-shared project not in the list, or any other ID the user has

If the user selects `Pick another from the list above` or `Enter a project ID manually`, ask as a follow-up free-text prompt:

- question: `Enter the project ID:` (free-text)

After the user enters an ID, validate it by running a lightweight call against that project (e.g. `node list --project-id <id> --alias <alias>`). If it returns an error like "project not found" or "permission denied", tell the user in plain language what happened and offer to either retry with a different ID or go back to the list.

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

## Step 7a — Session Load Behavior (saved context already exists)

When the skill loads and the profile already has a saved default project ID and location, **trust the saved values** and proceed silently. Do not run `project list` just to validate the saved project ID against the listing.

**Critical — do not warn about a "missing" project ID:**

If the saved default project ID does not appear in `project list` output, this does **not** mean the project was deleted. It is most likely an IAM-shared project (owned by another account, accessible via IAM) — `project list` only shows projects owned by the current account, so IAM-shared projects are never in that listing.

Therefore:
- Do NOT print messages like "your saved default project ID X doesn't appear in your current project list — it may have been deleted."
- Do NOT prompt the user to re-select a project on session load.
- Do NOT re-run Step 5 unless the user explicitly asks to switch projects, or a real API call returns "project not found" / "permission denied" for that ID.

If a later command actually fails for that project ID (e.g. real 404 / 403 from the API), only then tell the user in plain language and offer to re-select. The trigger is a real error, never an absence from `project list`.

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

