# Heltar Skills

AI agent skills for the Heltar WhatsApp Business API. Get expert guidance on getting started, best practices, and gotchas — right inside your AI coding agent.

These skills give your agent the context it needs to generate production-ready Heltar integrations, not just syntactically correct code.

## What's a skill?

A `SKILL.md` file is a piece of structured knowledge that AI coding agents (Claude Code, Cursor, Codex, Gemini CLI, etc.) load on demand. Each skill in this repo covers one Heltar API surface and points to the canonical public documentation for full request/response details.

## Available skills

| Skill                                                            | Surface                                                          |
| ---------------------------------------------------------------- | ---------------------------------------------------------------- |
| [heltar-authentication](./skills/heltar-authentication/SKILL.md) | API keys, headers, key rotation                                  |
| [heltar-messaging](./skills/heltar-messaging/SKILL.md)           | Send text / media / template / interactive messages, fetch media |
| [heltar-templates](./skills/heltar-templates/SKILL.md)           | Create, list, delete, analyze templates                          |
| [heltar-campaigns](./skills/heltar-campaigns/SKILL.md)           | Bulk campaigns, scheduling, stats                                |
| [heltar-chatbots](./skills/heltar-chatbots/SKILL.md)             | Activate bots, trigger talks, process conversations              |
| [heltar-webhooks](./skills/heltar-webhooks/SKILL.md)             | Configure webhooks, parse Meta payloads, custom data             |
| [heltar-contacts](./skills/heltar-contacts/SKILL.md)             | Create/update contacts, attributes, tags, chat assignment        |
| [heltar-calls](./skills/heltar-calls/SKILL.md)                   | WhatsApp / SIP voice calls, AI-agent dialing                     |
| [heltar-groups](./skills/heltar-groups/SKILL.md)                 | Create, list, update WhatsApp groups                             |
| [heltar-code-editor](./skills/heltar-code-editor/SKILL.md)       | Run deployed Code Editor functions                               |
| [heltar-schedule](./skills/heltar-schedule/SKILL.md)             | Schedule messages, campaigns, chatbot nudges                     |

## Installation

```bash
npx skills add Heltar/skills
```

Or install the Claude Code plugin (which bundles these same skills + a `/heltar-help` command): [`Heltar/heltar-plugins`](https://github.com/Heltar/heltar-plugins).

## What's inside a skill

Each skill is a `SKILL.md` plus a `references/` folder containing the canonical Heltar API documentation for that surface (kept in sync from [`Heltar/docs`](https://github.com/Heltar/docs)). `SKILL.md` carries the agent-shaped layer (env vars, decision matrices, gotchas, short worked examples); `references/api-reference.md` is the full request/response spec.

To validate the structure locally:

```bash
./scripts/sync-check.sh
```

## Repo layout

```
.
├── README.md            ← you are here
├── AGENTS.md            ← guidance for AI agents loading these skills
├── CLAUDE.md            ← Claude Code-specific notes
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── scripts/
│   └── sync-check.sh    ← validates skill structure
└── skills/
    └── heltar-<name>/
        ├── SKILL.md
        └── references/
            ├── api-reference.md
            └── guides/...   (optional, where applicable)
```

## License

Apache-2.0
