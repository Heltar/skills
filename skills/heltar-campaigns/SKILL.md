---
name: heltar-campaigns
description: 'Send bulk template-message campaigns over WhatsApp on Heltar — immediate or scheduled — with per-recipient personalization and delivery stats. Use when sending the same template to many recipients with their own variable values.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: campaigns, bulk, template, schedule, stats, csv, integrations
  uses:
    - heltar-authentication
    - heltar-templates
---

# Heltar Campaigns

## Overview

Campaigns send the same approved template to many recipients with per-recipient variable substitution. The platform queues and dispatches messages in batches and tracks delivery state at campaign + recipient level.

## Agent Instructions

Before generating campaign code:

1. **Is the template APPROVED?** Verify via [`heltar-templates`](../heltar-templates/SKILL.md). Campaigns silently fail at send-time if the template is `PENDING` / `REJECTED`.
2. **Immediate or scheduled?** `POST /v1/campaigns/send` ships now. `POST /v1/campaigns/schedule` ships at a `scheduleTime` (Unix seconds, future, ≤ 2 years out).
3. **Audience size sanity-check.** If the user has >100 recipients, suggest a 10-20 recipient pilot first to catch template/variable bugs before the full blast.
4. **Tracking IDs.** If they use WebEngage / CleverTap / MoEngage, pass per-recipient `integrations[]` so analytics platforms can stitch back to their journeys.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Endpoints

| Method | Path                               | Purpose                            |
| ------ | ---------------------------------- | ---------------------------------- |
| POST   | `/v1/campaigns/send`               | Send immediately                   |
| POST   | `/v1/campaigns/schedule`           | Schedule for future Unix timestamp |
| GET    | `/v1/campaigns`                    | List with stats                    |
| GET    | `/v1/campaigns/:id`                | Real-time stats for one campaign   |
| GET    | `/v1/campaigns/download-stats/:id` | Per-recipient CSV                  |

## Quick Start — send a personalized campaign

```bash
curl -X POST "$API_URL/v1/campaigns/send" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "campaignName": "Diwali Sale 2026",
    "templateName": "promo_offer",
    "languageCode": "en",
    "messages": [
      { "clientWaNumber": "919876543210",
        "variables": [{ "type": "text", "text": "John" }, { "type": "text", "text": "20%" }] },
      { "clientWaNumber": "919876543211",
        "variables": [{ "type": "text", "text": "Jane" }, { "type": "text", "text": "25%" }] }
    ],
    "source": "api"
  }'
```

Response gives a `campaign.id` (UUID), initial `statsTotal` / `statsSent`, and a per-recipient `messagesResponse.success` / `messagesResponse.fail` map.

## Scheduling

```jsonc
{
  "campaignName": "New Year Sale",
  "templateName": "promo_template",
  "languageCode": "en",
  "messages": [
    /* … */
  ],
  "scheduleTime": 1735689600, // Unix SECONDS (not millis)
}
```

`scheduleTime` must be in the future. Status starts as `schedule` and flips to `running` then `sent` automatically.

## Status lifecycle

`draft` → `schedule` → `running` → `sent`. Per-recipient delivery progresses through the same `sent` / `delivered` / `read` / `failed` states as one-off messages — track them via webhooks ([`heltar-webhooks`](../heltar-webhooks/SKILL.md)) or `GET /v1/campaigns/:id`.

## Variable shape

Same shape as a single template send (see [`heltar-messaging`](../heltar-messaging/SKILL.md)) — each recipient has its own `variables[]`, matched **by position** to `{{1}}`, `{{2}}`, … in the template body.

## Analytics integrations

Per-recipient `integrations[]` lets you tag each send with an external tracking id:

```jsonc
"integrations": [
  { "name": "webEngage", "msgId": "we-123" },
  { "name": "cleverTap", "msgId": "ct-123" },
  { "name": "moEngage",  "msgId": "me-456" }
]
```

These IDs round-trip in webhook deliveries so external analytics can attribute the `sent`/`delivered`/`read` event back to the originating campaign step.

## Common gotchas

- `scheduleTime` in **milliseconds** (e.g. `Date.now()` from JS) → API rejects as too far future. Divide by 1000.
- All recipients share **one** template + language — for A/B tests, run two separate campaigns.
- Don't include opted-out contacts. There's no built-in suppression list at campaign create time — query [`heltar-contacts`](../heltar-contacts/SKILL.md) for `optedIn: true` before building the recipient list.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
