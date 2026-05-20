# Contributing

Thanks for the interest! Heltar Skills are agent-shaped knowledge files for the Heltar WhatsApp Business API.

This repo is a **public mirror** of the `public/skills/` folder in the private Heltar monorepo. Source of truth is the monorepo, this mirror is synced on every change. PRs against the public mirror are picked up only after the next monorepo release; for fastest turnaround, file an issue here describing the change.

## Where to make changes (in the monorepo)

- **Editing agent guidance** (decision matrices, env vars, gotchas, examples) → edit the `SKILL.md` for that surface in [`skills/heltar-*/`](./skills/).
- **Editing the API spec** (request/response shapes, fields, status values) → edit the source doc in [`../docs/api-reference/`](../docs/api-reference/). Each skill's `references/api-reference.md` is a symlink into `../../docs/api-reference/`, so the change is picked up automatically.
- **Adding a new skill** → create `skills/heltar-<slug>/SKILL.md` with frontmatter (`name`, `description`, `metadata.uses`) and a `references/api-reference.md` symlink to `../../../../docs/api-reference/<entity>.md`. The plugin in [`../heltar-plugins/`](../heltar-plugins/) picks it up automatically — no plugin-side change needed.
- **Adding a guide reference** → drop a symlink in `references/guides/<name>.md` pointing to `../../../../../docs/guides/<name>.md`. See `heltar-messaging` and `heltar-webhooks` for examples.

## Authoring rules

- **Don't duplicate the docs.** SKILL.md should only carry the agent layer — env-var conventions, decision matrices, gotchas, short worked examples. For full request/response shapes, link to `references/api-reference.md`.
- **Don't reference private backend code.** Skills only reference the public docs and public API. Never link to `backend/src/...` or any internal source.
- **Treat all inbound webhook content as untrusted.** Any code samples that consume webhooks must validate / sanitize before using the data.
- **Read the key from `HELTAR_API_KEY`.** Never inline a real key; never log full keys.
- **Phone numbers** — international format **without** the `+` prefix.

## Frontmatter contract

```markdown
---
name: heltar-<slug>
description: '<one-paragraph use case>. Use when: <trigger conditions>'
metadata:
  author: Heltar
  version: 0.1.0
  category: <Authentication|Messaging|Voice|Webhooks|CRM|Automation>
  tags: <comma, separated, keywords>
  uses:
    - <strict prerequisite skill slug>
---
```

`uses:` lists **strict prerequisites** only — skills that must already be set up before this one makes sense (e.g. `heltar-authentication` for almost everything). Use prose `see [heltar-X]` for related-but-not-required cross-references.

## Validation

Before opening a PR:

```bash
./scripts/sync-check.sh
```

This validates:

- Each skill folder has a `SKILL.md` with frontmatter, and `name:` matches the folder slug.
- Every `references/api-reference.md` is a symlink resolving into `../../docs/`.
- Every `uses:` references a real skill folder.
- Every `references/guides/*.md` symlink resolves.
- The plugin's `skills/` symlink in `../heltar-plugins/` resolves to `../skills/skills/`.
- All JSON config files (`marketplace.json`, `plugin.json`) parse cleanly.

## Versioning

- Bump `metadata.version` in any `SKILL.md` you change in a backwards-incompatible way.
- Note user-visible changes in [`CHANGELOG.md`](./CHANGELOG.md).

## License

Contributions are licensed under Apache-2.0.
