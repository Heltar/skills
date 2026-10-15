---
name: heltar-campaigns
description: 'Send bulk template-message campaigns over WhatsApp on Heltar — immediate or scheduled, inline recipients or an NDJSON file for very large audiences — with per-recipient personalization, live delivery counts, per-recipient status, and export-ready stats. Use when sending the same template to many recipients with their own variable values.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: campaigns, bulk, template, schedule, stats, ndjson, recipient-status, export, integrations
  uses:
    - heltar-authentication
    - heltar-templates
---

# Heltar Campaigns

## Overview

Campaigns send the same approved template to many recipients with per-recipient variable substitution. The platform queues and dispatches messages in the background at your account's send rate and tracks delivery state at campaign + recipient level.

## Agent Instructions

Before generating campaign code:

1. **Is the template APPROVED?** Campaigns can only use approved templates — verify via [`heltar-templates`](../heltar-templates/SKILL.md) first.
2. **Immediate or scheduled?** `POST /v1/campaigns/send` ships now. `POST /v1/schedule/campaign` (see [`heltar-schedule`](../heltar-schedule/SKILL.md)) ships at a `scheduleTime` (Unix seconds, future, within 2 years).
3. **Audience size sanity-check.** If the user has >100 recipients, suggest a 10-20 recipient pilot first to catch template/variable bugs before the full blast. For a few lakh recipients, upload an NDJSON file instead of an inline `messages` array.
4. **Tracking IDs.** If they use WebEngage / CleverTap / MoEngage, or want their own data echoed in webhooks, pass per-recipient `integrations[]`.

Match user intent:

| User intent                                     | Endpoint                                                                                         |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Send now, recipients inline                     | `POST /v1/campaigns/send` with `messages[]`                                                      |
| Send now, very large audience                   | `POST /v1/campaigns/send` with `finalPayloadFileUrl` (NDJSON) + `recipientCount`                 |
| Schedule for a future time                      | `POST /v1/schedule/campaign` ([`heltar-schedule`](../heltar-schedule/SKILL.md))                  |
| List campaigns with their counts                | `GET /v1/campaigns?startDate=&endDate=&limit=&cursor=` → `{ campaigns, nextCursor }`             |
| Poll one campaign's counts (cheapest)           | `GET /v1/campaigns/get-one/:id`                                                                  |
| Per-recipient delivery status + failure reasons | `GET /v1/campaigns/:id` → `{ messages: [{ status, clientWaNumber, failureReason, timestamp }] }` |
| Export-ready rows + cumulative funnel counts    | `GET /v1/campaigns/download-stats/:id` → JSON `{ statusCounts, campaignStats[] }`                |

## Authentication

Bearer API key. `POST /v1/campaigns/send` needs the `campaigns:write` scope; the `GET` endpoints need `campaigns:read`. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

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
        "variables": [{ "type": "body", "parameters": [
          { "type": "text", "text": "John" }, { "type": "text", "text": "20%" }
        ] }] },
      { "clientWaNumber": "919876543211",
        "variables": [{ "type": "body", "parameters": [
          { "type": "text", "text": "Jane" }, { "type": "text", "text": "25%" }
        ] }] }
    ]
  }'
```

The call returns once every recipient is queued. `data.campaign` is the new campaign (UUID `id`, status `running`, `statsWait` equal to `statsTotal`); `data.messagesResponse.success` is keyed by each recipient's **position in your `messages` array** (`"0"`, `"1"`, …) and echoes the recipient back. `fail` is always `{}` here because sending happens in the background — per-recipient failures appear later in `GET /v1/campaigns/:id` with a `failureReason`.

## Large campaigns (NDJSON file)

Upload the recipients as an **NDJSON** file — one JSON object per line, each line exactly what a `messages` entry would have been — anywhere the API can read it over HTTPS, then send `finalPayloadFileUrl` + `recipientCount` instead of `messages`:

```json
{
  "campaignName": "Diwali Sale 2026",
  "templateName": "promo_offer",
  "languageCode": "en",
  "finalPayloadFileUrl": "https://your-storage.example.com/diwali-recipients.ndjson",
  "recipientCount": 200000
}
```

`recipientCount` is a ceiling: only the first `recipientCount` lines are sent (fewer is fine; missing or `0` → 400). No line may exceed 1,000,000 characters; a file written as one big JSON array is a single line and is rejected with nothing sent; invalid JSON lines are skipped. `messagesResponse` comes back empty for this form — track with `GET /v1/campaigns/get-one/:id`.

## Scheduling

```jsonc
{
  "campaignName": "New Year Sale",
  "templateName": "promo_template",
  "languageCode": "en",
  "messages": [
    /* same recipient shape as above */
  ],
  "scheduleTime": 1735689600, // Unix SECONDS (not millis)
}
```

`scheduleTime` must be in the future. The campaign is listed with status `schedule`, every recipient in `statsWait`, and its planned start in `scheduleTime`; it flips to `running` then `sent` automatically. Not-yet-started scheduled campaigns are pinned to the top of the first list page and are not available from `download-stats`.

## Status lifecycle

Campaign `status`: `draft` → `schedule` → `running` → `sent`, plus `paused` (sending paused). Counts on every campaign object: `statsTotal`, `statsWait`, `statsSent`, `statsDelivered`, `statsRead`, `statsResponded`, `statsClicked`, `statsClickedResponded`, `statsFailure` — a cumulative funnel (`statsSent` includes everything further down). `get-one` refreshes counts from the latest message statuses for campaigns sent in the last 90 days; older campaigns return frozen final counts.

Per-recipient message `status` (in `GET /v1/campaigns/:id` and `download-stats`): `waiting`, `sent`, `delivered`, `read`, `responded`, `clicked`, `clicked_responded`, `failed` (see `failureReason`), `expired` (counted with failed). Track them in real time via webhooks ([`heltar-webhooks`](../heltar-webhooks/SKILL.md)) rather than polling the recipient list.

## Variable shape

Same shape as a single template send (see [`heltar-messaging`](../heltar-messaging/SKILL.md)): each recipient's `variables[]` is a list of **component objects** — `{ "type": "body" | "header" | "button" | "limited_time_offer" | "carousel", "parameters": [...] }` — with body parameters matched **by position** to `{{1}}`, `{{2}}`, … A flat `[{ "type": "text", "text": "John" }]` list is not accepted.

## Analytics integrations

Per-recipient `integrations[]` lets you tag each send with an external tracking id or your own data:

```jsonc
"integrations": [
  { "name": "webEngage", "msgId": "we-123" },
  { "name": "cleverTap", "msgId": "ct-123" },
  { "name": "moEngage",  "msgId": "me-456" },
  { "name": "metaCustomFieldHook", "customField": { "order_id": "ORD-12345" } }
]
```

`msgId` is generated for you when omitted; `customField` accepts an object or a string. These round-trip in webhook deliveries so external analytics can attribute the `sent` / `delivered` / `read` event back to the originating campaign step.

## Key Rules / Gotchas

- `campaignName`, `templateName`, `languageCode` are required. Supply **either** `messages` **or** `finalPayloadFileUrl` + `recipientCount` — neither or both → 400. Unknown body fields → 400.
- `variables` are component objects, not flat parameter lists — see Variable shape above.
- List: `startDate` / `endDate` filter on creation day (`YYYY-MM-DD`, IST) and must be sent together or not at all; `limit` is 1–10000 (default 1000); `nextCursor` is set when the page is full and `null` on the last page. 404 when the business has no WhatsApp number connected.
- `GET /v1/campaigns/:id` returns **every** recipient — huge for large campaigns; use `get-one` when you only need counts. `download-stats` is JSON (the data behind the dashboard's Export button), not a CSV: `campaignStats` rows carry `name`, `respondedMsg`, `failureReason`; `statusCounts` is a cumulative funnel with `total`.
- Status field names: `statsFailure` (not `statsFailed`), `statsClickedResponded`; campaign status `paused` exists alongside `draft` / `schedule` / `running` / `sent`.
- 503 on send means the queue was unavailable — the campaign may already have been created, so check `GET /v1/campaigns` before resending to avoid messaging the same contacts twice.
- `scheduleTime` in **milliseconds** (e.g. `Date.now()` from JS) is rejected as too far in the future. Divide by 1000.
- All recipients share **one** template + language — for A/B tests, run two separate campaigns.
- Opted-out contacts are recorded as failed (`Client did not opt-in`) and blocked contacts as `Client is blocked` — there is no suppression list at send time, so filter on `optedIn` / `isBlocked` via [`heltar-contacts`](../heltar-contacts/SKILL.md) before building the recipient list. Opt-in/opt-out rules live in [`heltar-business`](../heltar-business/SKILL.md).
- If the marketing-template pause is on (see [`heltar-templates`](../heltar-templates/SKILL.md)), `MARKETING` sends are cancelled while the campaign keeps running for its non-marketing messages.

## Related Skills

- [`heltar-templates`](../heltar-templates/SKILL.md) — approval status, fallback templates, marketing pause.
- [`heltar-schedule`](../heltar-schedule/SKILL.md) — schedule a campaign for later.
- [`heltar-messaging`](../heltar-messaging/SKILL.md) — the per-message `variables` and `integrations` shapes.
- [`heltar-contacts`](../heltar-contacts/SKILL.md) — audience building (`optedIn`, `isBlocked`, tags).
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — real-time delivery status and custom data echo.
- [`heltar-business`](../heltar-business/SKILL.md) — account status, opt-in/opt-out rules, link-tracking and send-rate settings.
- [`heltar-analytics`](../heltar-analytics/SKILL.md) — template, conversation, and cost analytics across campaigns.
- [`heltar-link-tracker`](../heltar-link-tracker/SKILL.md) — the tracked links behind `statsClicked` / `clicked`.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
