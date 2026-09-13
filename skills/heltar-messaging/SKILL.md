---
name: heltar-messaging
description: 'Send WhatsApp messages (text, media, template, interactive, location, contacts), read and search conversation history, fetch a single message by wamid/hemid, mark messages read, show a typing indicator, list WhatsApp Flow form submissions, and upload or download media via the Heltar API. Use when sending or reading WhatsApp messages.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: messages, send, text, media, template, interactive, wamid, hemid, search, mark-read, typing-indicator, flows, fetch-media, presigned-url
  uses:
    - heltar-authentication
---

# Heltar Messaging

## Overview

Send and read WhatsApp messages on the Heltar platform. One unified `/v1/messages/send` endpoint handles every outbound message type. Inbound messages and status updates arrive via [webhooks](../heltar-webhooks/SKILL.md), not by polling.

## Agent Instructions

Before generating code, ask the user:

1. **Direction** — sending or reading?
2. **Message type** — `text`, `media`, `template`, `interactive`, `contacts`, or `location`? Templates are required to start a new conversation outside the 24-hour customer service window.
3. **Bulk?** — single message vs. many recipients with personalized variables. For >1 recipient with a template, prefer the [Campaigns API](../heltar-campaigns/SKILL.md) instead — it gives you delivery counts and export-ready per-recipient rows.

Match user intent:

| User intent                                                  | Endpoint                                                         |
| ------------------------------------------------------------ | ---------------------------------------------------------------- |
| Send one or more messages (any type)                         | `POST /v1/messages/send`                                         |
| Send now, skipping the queue when async message mode is on   | `POST /v1/messages/send?priority=true`                           |
| Conversation history for one contact                         | `GET /v1/messages/:clientWaNumber`                               |
| Search message text / captions / file names across all chats | `GET /v1/messages/search?searchQuery=&limit=`                    |
| One specific message by ID                                   | `GET /v1/messages?wamid=` (also accepts `hemid.` IDs)            |
| Show blue ticks without replying                             | `GET /v1/messages/mark-read-msg/:clientWaNumber`                 |
| Blue ticks + "typing..." bubble right before a reply         | `POST /v1/business/typing-indicator` (Full-access key)           |
| List form submissions from a WhatsApp Flow                   | `GET /v1/messages/flow-id/:flowId`                               |
| Attach a call recording to a call-log message                | `PUT /v1/messages/:wamid`                                        |
| Download customer-uploaded media bytes immediately           | `GET /v1/messages/fetch-media?url=<encoded>`                     |
| Get a permanent CDN link for inbound media                   | `GET /v1/messages?wamid=` → `awsLink` (retry 3-5s after webhook) |
| Host a file to send as outbound media / template header      | `GET /v1/messages/presigned-url?file_name=&file_type=`           |

For inbound media, choose between `GET /v1/messages?wamid=...` (permanent CDN URL, retry 3-5s) and `GET /v1/messages/fetch-media?url=<encoded>` (instant; the webhook URL expires in ~5 minutes). See [`heltar-webhooks`](../heltar-webhooks/SKILL.md) for the webhook payload that contains the media URL.

## Authentication

Bearer API key. `GET` endpoints under `/v1/messages` need the `messages:read` scope, everything else `messages:write`. `POST /v1/business/typing-indicator` is outside the per-resource scope picker — it needs a **Full access** key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Base URL

```
$API_URL/v1
```

## Phone number format

> **International format, no `+` prefix.** `919876543210` ✅, `+919876543210` ❌, `9876543210` ❌. A contact who hides their number behind a WhatsApp username is addressed by the user ID from their inbound message (`BD.1068713429041673`) instead; a group by its group ID.

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

**Response shape:** `data.success` and `data.fail` are objects keyed by each message's **position in your `messages` array** (`"0"`, `"1"`, …). `success[i].message` is the saved message (`wamid`, `status: "waiting"`, your `refId` echoed back); `fail[i]` carries `clientWaNumber`, `errorCode`, `errorData`, and the message you sent. HTTP 200 = every message accepted, 206 = some failed (both maps populated), 4xx/5xx = every message failed (`errorRaw` holds `{ success, fail }`).

## Message types — at a glance

| `messageType` | Required fields                                                                                   | Notes                                                                                                                                                                                                                                                         |
| ------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `text`        | `message`                                                                                         | Max 4096 chars.                                                                                                                                                                                                                                               |
| `media`       | `mediaType`, `url`, `name`, `mimeType`                                                            | `mediaType` ∈ {image, video, audio, document, sticker}. URL must be public HTTPS. Optional `size`, `caption` (not for audio/sticker).                                                                                                                         |
| `template`    | `templateName`, `languageCode`, optional `variables[]`                                            | Template must be **APPROVED** by Meta. `contextId` is rejected (400). See [`heltar-templates`](../heltar-templates/SKILL.md).                                                                                                                                 |
| `interactive` | `interactive: { type, body, action }`                                                             | `type` ∈ `button` (max 3 quick replies, 20-char titles), `list` (max 10 rows × 10 sections), `cta_url`, `flow`, `location_request_message`, `address_message`, `request_contact_info`, `catalog_message`, `product`, `product_list`, `carousel` (2-10 cards). |
| `contacts`    | `contacts[]` — each with `name.formatted_name`, `name.prefix`, `phones[].phone`, `phones[].wa_id` | Share one or more contact cards.                                                                                                                                                                                                                              |
| `location`    | `location: { latitude, longitude }`                                                               | Optional `name` and `address` labels under the pin.                                                                                                                                                                                                           |

Optional fields on every type: `contextId` (reply to a wamid — not on `template`), `refId` (echoed back, not stored), `isPrivate` (save as a private inbox note, nothing sent), `integrations[]`, `groupId` (alias of `clientWaNumber` for groups). `text`, `media`, and `template` reject unknown fields with a 400. `sms` is reserved and returns 400.

## Template variables — important

Heltar's `variables` array maps to Meta's `components` structure. Each entry has a `type` (`header` / `body` / `button` / `limited_time_offer` / `carousel`) and a `parameters` array (`carousel` carries `cards[]` instead). Body parameters are matched **by position** to `{{1}}`, `{{2}}`, …

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

Image header, dynamic URL button (`sub_type: "url"`, 0-based `index`), limited-time offer and carousel shapes: see `references/api-reference.md`.

## Custom data correlation (for templates)

Pass an `integrations` array with `name: "metaCustomFieldHook"` and a `customField` payload to receive your own data back in webhook callbacks — useful for tying delivery status to your own order IDs, campaign tags, etc. Requires the webhook to subscribe to `metaCustomFieldHook`. Walkthrough: `references/guides/custom-data-in-webhooks.md`.

## Reading messages

### Conversation history

```
GET /v1/messages/:clientWaNumber?limit=50
GET /v1/messages/:clientWaNumber?limit=50&before=<oldest timestamp>&beforeId=<oldest wamid>
```

Returns the newest `limit` messages (default and max 10000) in chronological order — **oldest first**. To page further back, pass the first message's `timestamp` as `before` and its `wamid` as `beforeId` (always together); repeat while `hasMore` is `true`. `status: "received"` marks an inbound (customer) message — every other status is outbound. The response also carries `conversationExpire` (when the 24-hour reply window closes) and `canMessage`. 404 when the contact does not exist.

### Search

```
GET /v1/messages/search?searchQuery=order%2012345&limit=20[&clientWaNumber=919876543210][&cursor=<ISO timestamp>]
```

`searchQuery` and `limit` are both required. Every space-separated word must appear (case-insensitive) in a message's text, caption, or file/template name; punctuation is treated as spaces. Returns `chats` (contacts whose **phone number** matches, one entry each) and `messages` (matching messages), newest first, each capped at `limit`. Pass `newCursor` back as `cursor` for the next page; stop when both lists come back empty. Contact names are not searched — look contacts up via [`heltar-contacts`](../heltar-contacts/SKILL.md).

### Single message by ID

```
GET /v1/messages?wamid=wamid.HBg...   # WhatsApp ID
GET /v1/messages?wamid=hemid.MTIz...  # platform ID for queued (async-mode) messages
```

For media messages, the response carries a permanent `awsLink` once the upload to our CDN finishes. **404 / empty `awsLink` immediately after the webhook is normal** — retry every 3-5 seconds, or use `fetch-media` for instant access.

### Mark read and typing indicator

`GET /v1/messages/mark-read-msg/:clientWaNumber` sends a read receipt for the contact's latest inbound message. Always HTTP 200 — check `data.message`: `Message marked as read!` (sent, or nothing to acknowledge), `Mark read message is disabled! ...` (turn on "Let contacts know when you've read their messages" in Settings — see [`heltar-business`](../heltar-business/SKILL.md)), or `Error while marking message as read` (WhatsApp rejected it). Sending any non-template message already marks the chat read when that setting is on.

`POST /v1/business/typing-indicator` with `{ "messageId": "<inbound wamid>", "typingIndicatorType": "text" }` sends the read receipt **and** a typing bubble; call it right before `POST /v1/messages/send`. `typingIndicatorType` ∈ `text` (default) / `image` / `video` / `audio` / `document`. Needs a Full-access key (403 `business:write` otherwise).

### WhatsApp Flow submissions

`GET /v1/messages/flow-id/:flowId` lists every inbound `nfm_reply` whose payload contains the flow ID, as `[{ clientWaNumber, interactive }]`. The answers are in `interactive.nfm_reply.response_json` — a JSON **string** you must parse (it always includes your `flow_token`). Not paginated, not ordered. Matching is a plain text match, so for flows you build yourself include the flow ID in the submitted data or in the `flow_token` you send, or submissions will not be found.

### Attach a call recording

`PUT /v1/messages/:wamid` with `{ "wamid", "awsLink", "name"? }` stores an audio recording on a call-log message (stored as type `interactive`); the audio is converted to MP3, re-hosted, and the new link returned as `data.awsLink`. This is the only message field the API can change. 204 (empty body) when no message has that wamid; any other message type returns 200 unchanged.

### Fetch raw media bytes

```
GET /v1/messages/fetch-media?url=<URL-encoded media URL from webhook>
```

Returns raw binary with the right `Content-Type`. The webhook URL expires in ~5 minutes, so download promptly. 400 `Invalid URL` for a missing/malformed `url`, 403 for Graph API URLs (only attachment URLs are accepted); WhatsApp's own status is passed through if it refuses (e.g. expired). Full example with retry strategy: `references/guides/receiving-media-from-webhooks.md`.

### Upload your own media (for outbound messages)

```
GET /v1/messages/presigned-url?file_name=product.jpg&file_type=image%2Fjpeg
```

Returns `{ signedRequest, url }`. `PUT` the raw bytes to `signedRequest` with `Content-Type` equal to `file_type` (no Authorization header; expires after 1 hour), then send `url` as the `url` in the media message body or in a template header parameter. Optional `public=true` returns the storage-host URL instead of the CDN one. Missing `file_name`/`file_type` → 400.

## Status lifecycle

`waiting` → `sent` → `delivered` → `read`, or `failed`; `received` = inbound. Campaign/template messages can additionally show `responded`, `clicked` (tapped a tracked link — see [`heltar-link-tracker`](../heltar-link-tracker/SKILL.md)), `clicked_responded`, or `expired`. Use webhooks to track in real time — never poll.

## Common errors / gotchas

| Symptom                                                            | Likely cause                                                       | Fix                                                                                                                                                       |
| ------------------------------------------------------------------ | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400 `Invalid format. Expected a phone number, ...`                 | Bad `clientWaNumber`                                               | Country-code digits (`+`, spaces, dashes are stripped), a `BD.` user ID, or a group ID                                                                    |
| 400 `Client is blocked` / `Client has not opted in` (non-template) | Contact is blocked or opted out                                    | Check `isBlocked` / `optedIn` via [`heltar-contacts`](../heltar-contacts/SKILL.md); opt-in rules live in [`heltar-business`](../heltar-business/SKILL.md) |
| Template send lands in `data.fail` with a blocked / opt-in reason  | Same — template messages are saved as failed instead of being sent | Same                                                                                                                                                      |
| 400 when `contextId` is sent with `messageType: template`          | Replies are not supported on templates                             | Drop `contextId`                                                                                                                                          |
| 200 but `wamid` starts with `hemid.`                               | Asynchronous message mode is enabled on the account                | The real `wamid` arrives via webhook; look the message up with either ID. Use `?priority=true` to skip the queue for one request                          |
| 503 on send                                                        | Send queue temporarily unavailable (async mode only)               | Retry after a few seconds                                                                                                                                 |
| Meta error 131047 "Re-engagement message"                          | 24-hour window expired on a free-form message                      | Send a template instead                                                                                                                                   |
| 404 on `GET /v1/messages?wamid=...` for media                      | CDN upload still in progress                                       | Retry after 3-5s, or use `fetch-media`                                                                                                                    |
| 403 `... required scope (business:write)` on typing indicator      | Key was created with a per-resource scope                          | Use a Full-access key                                                                                                                                     |

## Related Skills

- [`heltar-templates`](../heltar-templates/SKILL.md) — create/approve the templates you send.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — the same template to many recipients with counts and per-recipient status.
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — inbound messages, status updates, media URLs.
- [`heltar-contacts`](../heltar-contacts/SKILL.md) — blocked list, `optedIn`, per-contact bot toggle.
- [`heltar-business`](../heltar-business/SKILL.md) — account status, read-receipt and async message mode settings, opt-in/opt-out keyword rules.
- [`heltar-analytics`](../heltar-analytics/SKILL.md) — delivery / read / click analytics over time.
- [`heltar-link-tracker`](../heltar-link-tracker/SKILL.md) — the tracked links behind `clicked` statuses.
- [`heltar-schedule`](../heltar-schedule/SKILL.md) — send messages at a future time.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
- Custom-data correlation guide: [`references/guides/custom-data-in-webhooks.md`](./references/guides/custom-data-in-webhooks.md)
- Receiving media guide: [`references/guides/receiving-media-from-webhooks.md`](./references/guides/receiving-media-from-webhooks.md)
