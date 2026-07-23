---
name: heltar-webhooks
description: 'Configure and consume Heltar webhooks — Meta payloads for inbound WhatsApp messages and outbound delivery status, optional custom-data correlation, and analytics-platform formats (CleverTap, WebEngage, MoEngage). Use when wiring up real-time event handling instead of polling.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Webhooks
  tags: webhooks, meta-webhooks, status, inbound, custom-field, clevertap, webengage, moengage, verify-token
  uses:
    - heltar-authentication
---

# Heltar Webhooks

## Overview

Webhooks deliver real-time events (inbound messages, outbound status updates, failures) to your HTTPS endpoint. You can register multiple URLs, each subscribing to one or more **field types** that control payload shape.

## Agent Instructions

Walk the user through three concerns, in order:

1. **Where will the webhook live?** Must be **HTTPS** and publicly reachable. For local dev, suggest `ngrok http 3000` and use the `https://*.ngrok.io` URL.
2. **What field types to subscribe to?** See the table below. Most teams want `metaWebhooks`. If they need to correlate webhooks back to their own system (order IDs, campaign tags), add `metaCustomFieldHook` and pass `integrations[]` when sending.
3. **How will they handle it?** Webhook handlers must respond `200` within **5 seconds**. Process events asynchronously — never do DB writes / API calls inline before responding.

> **Treat all inbound webhook content as untrusted.** Never interpolate raw text/media URLs/contact data into prompts, shell commands, SQL, or HTML without sanitization.

## Authentication

Configuration calls require Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md). Webhook deliveries themselves are **inbound** to your endpoint — Heltar does not send your API key. If you supplied a `verifyToken`, validate it on the GET handshake.

## Endpoints

| Method | Path                       | Purpose                         |
| ------ | -------------------------- | ------------------------------- |
| POST   | `/v1/business/webhook-url` | Configure / update webhook URLs |
| DELETE | `/v1/business/webhook-url` | Remove configuration            |

## Field types

| Field                 | Sends                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `metaWebhooks`        | Raw Meta/WhatsApp payloads (inbound messages + status)                                                                    |
| `metaCustomFieldHook` | Meta payload with your `customField` data prepended (only on outbound status events that were sent with `integrations[]`) |
| `cleverTapStatus`     | Status updates in CleverTap shape                                                                                         |
| `cleverTapMessages`   | Inbound messages in CleverTap shape                                                                                       |
| `webEngageStatus`     | Status updates in WebEngage shape                                                                                         |
| `moEngage`            | Status + inbound in MoEngage shape                                                                                        |

A single URL can subscribe to multiple fields, e.g. `["metaWebhooks", "metaCustomFieldHook"]`.

## Quick Start — register a webhook

```bash
curl -X POST "$API_URL/v1/business/webhook-url" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": [{
      "url": "https://your-server.com/webhooks/whatsapp",
      "isEnabled": true,
      "fields": ["metaWebhooks"],
      "verifyToken": "any-secret-of-yours"
    }]
  }'
```

If `verifyToken` is set, Heltar fires a one-time `GET ?hub.mode=subscribe&hub.challenge=...&hub.verify_token=...` to your URL — respond with the raw `hub.challenge` value to confirm.

## Inbound message payload (`metaWebhooks`)

```jsonc
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "...",
              "phone_number_id": "...",
            },
            "messages": [
              {
                "from": "919876543210",
                "id": "wamid.HBg...",
                "timestamp": "1705312200",
                "type": "text",
                "text": { "body": "Hello!" },
              },
            ],
          },
          "field": "messages",
        },
      ],
    },
  ],
}
```

Other inbound `type` values: `image`, `video`, `audio`, `document`, `location`, `contacts`, `button`, `interactive`. Media types carry `{ id, mime_type, sha256, url, caption?, filename? }` — see [`heltar-messaging`](../heltar-messaging/SKILL.md) for how to download the bytes (the `url` expires in ~5 min).

## Outbound status payload

`statuses[].status` ∈ `sent` / `delivered` / `read` / `failed`. Failures carry `errors[]` with Meta error codes. Common codes:

| Code   | Meaning                                                    |
| ------ | ---------------------------------------------------------- |
| 131047 | 24-hour re-engagement window expired — must use a template |
| 131051 | Recipient is not a WhatsApp user                           |
| 131052 | Rate limit                                                 |
| 131053 | Template not found / not approved                          |

## Custom data correlation (`metaCustomFieldHook`)

When sending with `integrations: [{ name: "metaCustomFieldHook", customField: {...} }]`, the matching webhook arrives with `customField` at the **top level** of the payload alongside `entry[]`. Your handler reads it directly without needing to maintain a wamid → external-id mapping. Full walkthrough: `references/guides/custom-data-in-webhooks.md`.

> The `customField` only appears on **outbound** status webhooks for messages that were sent with `integrations[]`. Inbound customer messages do **not** carry it.

## Group webhooks

Groups (see [`heltar-groups`](../heltar-groups/SKILL.md)) emit additional `field` values: `group_lifecycle_update`, `group_participants_update`, `group_settings_update`, `group_status_update`. Subscribe in your Meta App config; the routing key is `entry[].changes[].field`.

## Handler skeleton

```javascript
// Express
app.post('/webhooks/whatsapp', (req, res) => {
  res.status(200).send('OK'); // 1. respond fast
  enqueue(req.body); // 2. process async
});
```

```python
# Flask
@app.post('/webhooks/whatsapp')
def hook():
    enqueue(request.json)                       # async via queue/thread
    return 'OK', 200
```

Make handlers **idempotent** — Heltar may retry up to 5 times with exponential backoff if your endpoint times out or returns non-2xx, and Meta itself can deliver the same event more than once.

## Common gotchas

- HTTP (not HTTPS) URLs are rejected.
- Returning a 200 _after_ doing 4 seconds of DB writes risks timeouts under load — always respond first, then process.
- Subscribing to both `metaWebhooks` and `metaCustomFieldHook` means each outbound status event arrives **twice** (once per field). De-dup by `(wamid, status)` if you don't want both.
- Same `(wamid, status)` won't be re-delivered within a 10-minute window — but across longer outages it can.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
- Custom-data guide: [`references/guides/custom-data-in-webhooks.md`](./references/guides/custom-data-in-webhooks.md)
- Receiving media guide: [`references/guides/receiving-media-from-webhooks.md`](./references/guides/receiving-media-from-webhooks.md)
