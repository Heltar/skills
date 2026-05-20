---
name: heltar-templates
description: 'Create, list, retrieve, delete, and analyze WhatsApp message templates on Heltar. Use when a user wants to submit a template for Meta approval, check template status, or pull delivery analytics.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: templates, meta-approval, utility, marketing, authentication, components, buttons, analytics
  uses:
    - heltar-authentication
---

# Heltar Templates

## Overview

Templates are pre-approved message bodies required to start a conversation outside the WhatsApp 24-hour customer service window. Heltar wraps Meta's template approval flow and exposes status / analytics on top.

## Agent Instructions

Before creating a template, gather:

1. **Category** — `UTILITY` (transactional: order, shipping, OTP-style updates), `MARKETING` (promo, re-engagement), or `AUTHENTICATION` (OTP / 2FA).
2. **Language** — ISO code (`en`, `hi`, `es`, …).
3. **Components** — header (text/image/video/doc), body (with `{{1}}` placeholders + example values), optional footer, optional buttons.
4. **Buttons** — quick reply (max 3), URL (max 2), phone, copy code. Mixed-type combos have stricter limits.

> Meta approval typically takes 24–48 hours; simple `UTILITY` templates often clear in minutes. `UTILITY` also has lower per-message cost than `MARKETING`.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Endpoints

| Method | Path                                      | Purpose                                  |
| ------ | ----------------------------------------- | ---------------------------------------- |
| POST   | `/v1/templates`                           | Submit a new template for Meta review    |
| GET    | `/v1/templates`                           | List all templates with status           |
| GET    | `/v1/templates/:templateName`             | Fetch one template                       |
| DELETE | `/v1/templates/:templateName/:templateId` | Delete (only if not in active campaigns) |
| GET    | `/v1/templates/analytics`                 | Sent/delivered/read/failed per template  |

## Quick Start — submit a UTILITY template

```bash
curl -X POST "$API_URL/v1/templates" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "order_confirmation",
    "category": "UTILITY",
    "language": "en",
    "components": [
      { "type": "BODY",
        "text": "Hi {{1}}, your order {{2}} has been confirmed.",
        "example": { "body_text": [["John", "ORD-123"]] }
      }
    ]
  }'
```

Response carries `data.status: "PENDING"`. Poll `GET /v1/templates/:name` (or wait for the dashboard) until `APPROVED`.

## Component cheatsheet

```jsonc
[
  { "type": "HEADER", "format": "TEXT", "text": "Order Confirmed!" }, // or IMAGE/VIDEO/DOCUMENT
  {
    "type": "BODY",
    "text": "Hi {{1}}, your order {{2}}.",
    "example": { "body_text": [["John", "ORD-1"]] },
  },
  { "type": "FOOTER", "text": "Thank you!" }, // optional, max 60 chars
  {
    "type": "BUTTONS",
    "buttons": [
      { "type": "URL", "text": "Track", "url": "https://x.com/{{1}}" },
      { "type": "QUICK_REPLY", "text": "Support" },
      {
        "type": "PHONE_NUMBER",
        "text": "Call",
        "phone_number": "+919876543210",
      },
      { "type": "COPY_CODE", "example": "DISCOUNT20" },
    ],
  },
]
```

Body max 1024 chars, header text max 60.

## Status values

`PENDING` (under review) · `APPROVED` (usable) · `REJECTED` (fix and resubmit) · `PAUSED` (temporarily) · `DISABLED` (permanently).

## Sending an approved template

Pass `templateName` + `languageCode` + `variables[]` to `POST /v1/messages/send`. See [`heltar-messaging`](../heltar-messaging/SKILL.md).

## Analytics

```
GET /v1/templates/analytics?from=2026-01-01&to=2026-01-31&templateName=order_confirmation
```

Returns `{ templateName, sent, delivered, read, failed }`. Use it to spot quality issues (high `failed`) before they trigger Meta-side template pauses.

## Common gotchas

- Submitting a body without an `example.body_text` entry covering every `{{N}}` placeholder → 400.
- Reusing a name with a different category or language is a separate template, not an edit. Use a new name (`order_confirmation_v2`) and migrate.
- `DELETE` fails if the template is referenced by an active campaign; pause / complete the campaign first.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
