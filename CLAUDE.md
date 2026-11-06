# CLAUDE.md

Notes for Claude Code specifically when this repo is loaded as a skills source.

## Skill discovery

Each `skills/heltar-*/SKILL.md` declares `name`, `description`, `metadata.uses` in frontmatter. Match user intent against `description`; follow `uses` to load prerequisite skills (most commonly `heltar-authentication`).

## Reference resolution

When `SKILL.md` says "see `references/api-reference.md`", read the symlinked file directly. It resolves into the Heltar docs package; the content is the same markdown that ships on the public docs site.

## Don't paste full API reference into responses

When the user asks for an example, generate a minimal worked example. If they want the full schema, point them at the symlinked `references/api-reference.md` instead of inlining hundreds of lines.

## Code style for generated samples

- **Node**: native `fetch` (Node 18+), no third-party HTTP client unless asked.
- **Python**: `requests`, no async unless asked.
- **curl**: long form (`-X POST`, `-H`), one header per line.

Use `process.env.HELTAR_API_KEY` / `os.environ["HELTAR_API_KEY"]`. Use `{{API_URL}}` placeholder if the user has not specified the base URL — they will substitute their own.
