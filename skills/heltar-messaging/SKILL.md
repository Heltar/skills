---
name: heltar-messaging
description: 'Send WhatsApp messages (text, media, template, interactive, location, contacts), retrieve conversation history, fetch a single message by wamid/hemid, and download customer-uploaded media via the Heltar API. Use when sending or reading WhatsApp messages.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: messages, send, text, media, template, interactive, wamid, hemid, fetch-media, presigned-url
  uses:
    - heltar-authentication
---

# Heltar Messaging

## Overview

Send and read WhatsApp messages on the Heltar platform. One unified `/v1/messages/send` endpoint handles every outbound message type. Inbound messages and status updates arrive via [webhooks](../heltar-webhooks/SKILL.md), not by polling.

## Agent Instructions

Before generating code, ask the user:

1. **Direction** — sending or reading?
2. **Message type** — `text`, `media`, `template`, or `interactive` (`button` / `list`)? Templates are required to start a new conversation outside the 24-hour customer service window.
3. **Bulk?** — single message vs. many recipients with personalized variables. For >1 recipient with a template, prefer the [Campaigns API](../heltar-campaigns/SKILL.md) instead — it gives you delivery stats and CSV export.

If the user is reading messages, distinguish:

- **Conversation history** for one contact → `GET /v1/messages/:clientWaNumber`
- **One specific message by ID** → `GET /v1/messages?wamid=...` (also accepts `hemid` for queued messages)
- **Customer-uploaded media** (file bytes, not metadata) → choose between `GET /v1/messages?wamid=...` (permanent CDN URL, retry 3-5s) and `GET /v1/messages/fetch-media?url=<encoded>` (instant, 5-min URL expiry). See [`heltar-webhooks`](../heltar-webhooks/SKILL.md) for the full webhook payload that contains the media URL.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Base URL

```
$API_URL/v1
```

## Phone number format

> **International format, no `+` prefix.** `919876543210` ✅, `+919876543210` ❌, `9876543210` ❌.

## Quick Start — send a text message

```bash
curl -X POST "$API_URL/v1/messages/send" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "clientWaNumber": "919876543210",
      "messageType": "text",
      "message": "Hello from the API!"
    }]
  }'
```

```javascript
await fetch(`${process.env.API_URL}/v1/messages/send`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.HELTAR_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    messages: [
      {
        clientWaNumber: '919876543210',
        messageType: 'text',
        message: 'Hello from the API!',
      },
    ],
  }),
});
```

```python
import os, requests
requests.post(
    f"{os.environ['API_URL']}/v1/messages/send",
    headers={"Authorization": f"Bearer {os.environ['HELTAR_API_KEY']}"},
    json={"messages": [{
        "clientWaNumber": "919876543210",
        "messageType": "text",
        "message": "Hello from the API!",
    }]},
)
```

## Message types — at a glance

| `messageType` | Required fields                                           | Notes                                                                                                                        |
| ------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `text`        | `message`                                                 | Max 4096 chars. `contextId` to reply to a wamid.                                                                             |
| `media`       | `mediaType`, `url`, `name`, `mimeType`                    | `mediaType` ∈ {image, video, audio, document, sticker}. URL must be public HTTPS. `caption` not supported for audio/sticker. |
| `template`    | `templateName`, `languageCode`, optional `variables[]`    | Template must be **APPROVED** by Meta. See [`heltar-templates`](../heltar-templates/SKILL.md).                               |
| `interactive` | `interactive: { type: "button" \| "list", body, action }` | Buttons: max 3 quick replies, 20-char title. Lists: max 10 rows × 10 sections.                                               |

## Template variables — important

Heltar's `variables` array maps to Meta's `components` structure. Each entry has a `type` (`header` / `body` / `button`) and a `parameters` array. Body parameters are matched **by position** to `{{1}}`, `{{2}}`, …

Minimal body-only template:

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "template",
  "templateName": "order_confirmation",
  "languageCode": "en",
  "variables": [
    {
      "type": "body",
      "parameters": [
        { "type": "text", "text": "John" },
        { "type": "text", "text": "ORD-12345" }
      ]
    }
  ]
}
```

Image header + URL button: see `references/api-reference.md` for the full shape.

## Custom data correlation (for templates)

Pass an `integrations` array with `name: "metaCustomFieldHook"` and a `customField` payload to receive your own data back in webhook callbacks — useful for tying delivery status to your own order IDs, campaign tags, etc. Requires the webhook to subscribe to `metaCustomFieldHook`. Walkthrough: `references/guides/custom-data-in-webhooks.md`.

## Reading messages

### Conversation history

```
GET /v1/messages/:clientWaNumber?limit=50&offset=0
```

Returned newest first. Pagination via `limit` (max 100) + `offset`. Each row carries `direction: "outbound" | "inbound"` so a single fetch covers both sides of the conversation.

### Single message by ID

```
GET /v1/messages?wamid=wamid.HBg...   # WhatsApp ID
GET /v1/messages?wamid=hemid.MTIz...   # Heltar ID for queued messages
```

For media messages, the response carries a permanent `awsLink` once the upload to our CDN finishes. **404 / empty `awsLink` immediately after webhook is normal** — retry every 3-5 seconds, or use `fetch-media` for instant access.

### Fetch raw media bytes

```
GET /v1/messages/fetch-media?url=<URL-encoded media URL from webhook>
```

Returns raw binary with the right `Content-Type`. The webhook URL expires in ~5 minutes, so download promptly. Full example with retry strategy: `references/guides/receiving-media-from-webhooks.md`.

### Upload your own media (for outbound messages)

```
GET /v1/messages/presigned-url?fileName=image.jpg&contentType=image/jpeg
```

Returns `{ presignedUrl, fileUrl }`. PUT bytes to `presignedUrl`, then send `fileUrl` as the `url` in the media message body.

## Status lifecycle

`sent` → `delivered` → `read`, or `failed` (with error code). Use webhooks to track in real time — never poll.

## Common errors / gotchas

| Symptom                                       | Likely cause                                  | Fix                                                                  |
| --------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------- |
| 400 `clientWaNumber is required`              | Missing or `+` prefix on the number           | Use country-code-prefixed digits only                                |
| Meta error 131047 "Re-engagement message"     | 24-hour window expired on a free-form text    | Send a template instead                                              |
| Meta error 131053 "Template not found"        | Template not approved or wrong `languageCode` | Verify status via [`heltar-templates`](../heltar-templates/SKILL.md) |
| 404 on `GET /v1/messages?wamid=...` for media | CDN upload still in progress                  | Retry after 3-5s, or use `fetch-media`                               |

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
- Custom-data correlation guide: [`references/guides/custom-data-in-webhooks.md`](./references/guides/custom-data-in-webhooks.md)
- Receiving media guide: [`references/guides/receiving-media-from-webhooks.md`](./references/guides/receiving-media-from-webhooks.md)
