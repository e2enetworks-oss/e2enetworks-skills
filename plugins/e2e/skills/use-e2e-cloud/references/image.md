# Images

In this file, `CLI` means the resolved command from `SKILL.md`.

Saved images are reusable snapshots created from existing nodes. They can be used to launch new nodes with the same OS and software state.

Do not use repeated `--help` calls for these workflows. Use these commands directly.

## List Saved Images

```bash
CLI image list --alias <alias>
```

Key column: `Template ID` — pass this value as `--saved-image-template-id` when creating a node from a saved image.

Use `CLI --json image list` when a later step needs the exact `template_id` value.

## Rename A Saved Image

```bash
CLI image rename <image-id> --name <new-image-name> --alias <alias>
```

## Delete A Saved Image

```bash
CLI image delete <image-id> --force --alias <alias>
```

Always use `--force` in non-interactive terminals. Ask for confirmation once before delete.

## Create A Node From A Saved Image

Saved-image node creation is identical to a regular node create with one extra flag.

Step 1 — get the `Template ID` from saved images:

```bash
CLI image list --alias <alias>
```

Step 2 — run the standard catalog discovery:

```bash
CLI node catalog os --alias <alias>
CLI node catalog plans \
  --alias <alias> \
  --display-category "<display-category>" \
  --category "<category>" \
  --os "<os>" \
  --os-version "<os-version>" \
  --billing-type all
```

Step 3 — create with `--saved-image-template-id`:

```bash
CLI node create \
  --alias <alias> \
  --name <node-name> \
  --plan "<full-plan-string-from-catalog>" \
  --image <catalog-image> \
  --saved-image-template-id <template-id>
```

- `--image` is the same catalog image identifier from `node catalog plans` (e.g. `Ubuntu-24.04-Distro`), not the saved image's OS name.
- `--saved-image-template-id` is the `Template ID` column value from `image list`.
- `is_saved_image` is set automatically — do not pass it manually.
- Attach multiple SSH keys at create time by repeating `--ssh-key-id <id>`.

## Create A Saved Image From A Node

```bash
CLI node action save-image <node-id> --name <image-name> --alias <alias>
```

The node must be in `Running` status before saving. After the command completes, verify with `image list`.

## Rules

- Always run `image list` before a saved-image node create to get the current `Template ID`.
- `image list` is the only safe discovery source for `Template ID` — never guess or hardcode it.
- Do not delete a saved image while it is referenced by an in-progress node creation.
- Keep saved-image node creates catalog-first: discover `--plan` and `--image` from `node catalog plans`, then add `--saved-image-template-id` from `image list`.

## Automation Notes

- `image list` is the safest discovery command for scripts.
- Use `CLI --json image list` when later steps need the exact `template_id`.
- Use `image delete --force` in non-interactive automation.

## Error Recovery

| Error | Cause | Fix |
|---|---|---|
| `412` on saved-image node create | `--plan` is a SKU shortname, not the full string | Re-run `catalog plans`, copy the exact full string |
| `--saved-image-template-id` not found | Wrong ID or image deleted | Re-run `image list` to get the current `Template ID` |
| `--image` rejected on saved-image create | Using the saved image's OS name instead of a catalog image identifier | Use the `Image` value from `node catalog plans` output |

## Docs

- Official documentation: https://docs.e2enetworks.com/docs/myaccount/node/virt_comp_node/create_image/
