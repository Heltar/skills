---
name: heltar-schedule
description: 'Schedule future actions on Heltar — chatbot follow-up nudges for unresponsive contacts, future-dated single messages, and future-dated bulk campaigns. Use when the user needs delayed delivery or a re-engagement nudge.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Automation
  tags: schedule, nudge, scheduled-message, scheduled-campaign, follow-up, re-engagement
  uses:
    - heltar-authentication
---

# Heltar Schedule

## Overview

Three things can be scheduled: chatbot **nudges** (a follow-up the bot sends if a contact hasn't replied), single **messages**, and full **campaigns**. All three share a `DELETE /v1/schedule/:id` for cancellation.

## Agent Instructions

Map the user's wording to the right endpoint:

| Sounds like…                                               | Endpoint                     |
| ---------------------------------------------------------- | ---------------------------- |
| "follow up if they don't reply in N seconds/minutes/hours" | `POST /v1/schedule/nudge`    |
| "send this message tomorrow at 9am"                        | `POST /v1/schedule/message`  |
| "send this template to my CSV next Monday"                 | `POST /v1/schedule/campaign` |
| "list pending nudges"                                      | `GET /v1/schedule/nudges`    |
| "cancel scheduled X"                                       | `DELETE /v1/schedule/:id`    |

Two timestamp formats coexist — surface this clearly:

- **`delaySeconds`** (relative): used by **nudge**. Seconds from now (1 to 10,000,000).
- **`scheduleTime`** (absolute): used by **message** and **campaign**. **Unix SECONDS** (not millis), must be in the future, ≤ 2 years out.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Quick Start — schedule a 5-minute follow-up nudge

```bash
curl -X POST "$API_URL/v1/schedule/nudge" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientWaNumber": "919876543210",
    "delaySeconds": 300,
    "chatbotId": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

> **Nudges are auto-cancelled** if the contact replies before the nudge fires, or if a new nudge for the same contact + chatbot is scheduled (the old one is cancelled first).

## Schedule a future-dated message

```jsonc
POST /v1/schedule/message
{
  "messages": [
    { "clientWaNumber": "919876543210",
      "messageType": "text",
      "message": "Hi! Just following up on your order." }
  ],
  "scheduleTime": 1735689600
}
```

`messages[]` is exactly the same shape as [`heltar-messaging`](../heltar-messaging/SKILL.md) — text, media, template, etc.

## Schedule a future-dated campaign

```jsonc
POST /v1/schedule/campaign
{
  "campaignName": "New Year Sale",
  "templateName": "promo_template",
  "languageCode": "en",
  "messages": [{ "clientWaNumber": "919876543210", "variables": [{ "type": "text", "text": "John" }] }],
  "scheduleTime": 1735689600
}
```

Same shape as [`heltar-campaigns`](../heltar-campaigns/SKILL.md) but with a required `scheduleTime`. The campaign starts in `schedule` status and flips to `running` then `sent` automatically.

## Cancel anything scheduled

```
DELETE /v1/schedule/:id
```

Where `:id` is the `scheduleId` (nudges) or `id` (message/campaign) returned at create time.

## Nudge selection priority

| Scenario                                                  | Behavior                                                                                  |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `chatbotId` provided + contact has different bot assigned | Re-assigns contact to the new bot, then schedules                                         |
| Contact already has assigned bot, no `chatbotId`          | Existing pending nudges for that bot are cancelled, new nudge scheduled with the same bot |
| No bot assigned + no `chatbotId`                          | A bot is auto-selected via weighted assignment, contact is updated, nudge scheduled       |

## Common gotchas

- Sending `scheduleTime` in **milliseconds** (e.g. `Date.now()` from JS) — the API rejects it as too far in the future. Divide by 1000.
- `delaySeconds` is capped at 10,000,000 (≈ 115 days). For longer delays, use a scheduled message instead.
- Scheduling a campaign with an unapproved template does not error at create time — it errors at fire time. Verify approval first via [`heltar-templates`](../heltar-templates/SKILL.md).

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
