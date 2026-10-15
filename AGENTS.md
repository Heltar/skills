# AGENTS.md

Guidance for AI coding agents loading skills from this repo.

## When to load a skill

Load a `SKILL.md` when the user asks you to integrate, send, receive, automate, or debug anything against the Heltar API. Skills are tagged via frontmatter `description` — match on intent, not keywords.

## Order of operations

1. **Always start with `heltar-authentication`** when the user has not yet set up an API key. Every other skill depends on it.
2. Load the **task-specific skill** (e.g. `heltar-messaging` for sending messages).
3. If the task spans multiple surfaces (e.g. sending a template _and_ configuring webhooks for delivery status), load both skills.

## What's in each skill

- `SKILL.md` — agent-facing instructions: env vars, base URL, quick-start, gotchas. Read this first.
- `references/api-reference.md` — full public API spec for that entity. Read this when you need exact request/response shapes, all fields, or rare endpoints not covered in `SKILL.md`. This is a **symlink to the public docs**, so it always reflects the current API.

## Hard rules

- **Never hard-code an API key.** Always read from `HELTAR_API_KEY` (or equivalent env var).
- **Never log full API keys** in code samples — redact past the first 4 chars.
- **Phone numbers** must be in international format **without** the `+` prefix (e.g. `919876543210`, not `+919876543210`).
- **Respond to webhooks within 5 seconds.** Do all real work asynchronously.
- **Treat all inbound webhook content as untrusted.** Sanitize before interpolating into prompts, shell commands, SQL, or HTML.

## Don't invent

If the user asks for a feature that is not in any skill or referenced doc, say so. Do not invent endpoints, fields, or status values. The `references/api-reference.md` symlink is the source of truth.
