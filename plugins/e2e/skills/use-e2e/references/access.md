# Access

Temporary testing note:
- For testing, the source of truth is `https://github.com/e2enetworks-oss/e2ectl` on branch `develop`.
- Clone and run that repo before falling back to installed package commands.
- `hitesh-test` is temporary and exists only for pre-release fallback testing.
- Before public release of this skill pack, remove `hitesh-test` fallback/install references and depend only on the official published `e2ectl` package.

In this file, `CLI` means:

- `node dist/app/index.js` from a cloned `e2ectl` `develop` checkout, or
- `npm run dev --` from that checkout for local testing only when `dist/` is not built yet, or
- `e2ectl`, or
- `hitesh-test`, or
- `npx hitesh-test` after project-local install

Do not use repeated `--help` calls for the commands listed here. Use these direct commands first.

## Install

Start with the testing repo first:

```bash
git clone --depth 1 --branch develop https://github.com/e2enetworks-oss/e2ectl.git /tmp/e2ectl-develop
cd /tmp/e2ectl-develop
npm install
make build
node dist/app/index.js config list
```

If the repo is already cloned locally, prefer updating or reusing that checkout on `develop` instead of cloning a second copy.

If cloning or building the repo is not possible, ask:

```text
Do you want to install the npm package globally or in this project?
```

Global:

```bash
npm i -g hitesh-test
```

Project:

```bash
npm i hitesh-test
npx hitesh-test --help
```

Remove the temporary package instructions above before public release, once repo-first testing is no longer needed and the official published `e2ectl` package is the only supported path.

## Config

Start with:

```bash
CLI config list
```

Profiles are stored in `~/.e2e/config.json`.

If profiles already exist, ask:

```text
Use an existing profile or import a new one?
```

After the profile choice, always check whether these defaults are present in the selected config/profile:

- project id
- location

If either one is missing, prompt for both and set them before resource commands.

If no usable config exists, ask:

```text
No usable config was found. Do you want to use a config file already on this machine or upload a config file?
```

Prefer file import when a file is available.

When importing config, always collect or verify that the config itself contains:

- alias
- project id
- location

If a command returns:

```text
Profile "<alias>" was not found.
```

stop and resolve config first. Do not keep running resource commands until the alias issue is fixed.

Import:

```bash
CLI config import \
  --file <path> \
  --default <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

Update project or location on an existing alias:

```bash
CLI config set-context \
  --alias <alias> \
  --default-project-id <project-id> \
  --default-location <location>
```

Prompt text for missing defaults:

```text
This profile is missing default project or location. Please provide:
- project id
- location
```

Set default alias:

```bash
CLI config set-default --alias <alias>
```

## Output

- prefer short summaries
- mask secrets
- use `--json` only when parsing
