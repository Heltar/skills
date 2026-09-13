---
title: Webhooks
description: Receive real-time updates
icon: Webhook
order: 7
---

# Webhooks

Receive real-time notifications when messages are received, delivered, read, or fail. Webhooks eliminate the need for polling and ensure you react to events immediately.

---

:::api
method: POST
endpoint: /v1/business/webhook-url
title: Configure Webhook URL
description: Set or update the webhook endpoints where you'll receive event notifications. You can register multiple webhook URLs, each subscribing to specific event types.

## Body Parameters

- urls: array [required] - Array of webhook configuration objects
  - url: string [required] - Your HTTPS webhook endpoint URL
  - isEnabled: boolean [required] - Whether this webhook is active
  - fields: array - Event types to receive (see Webhook Types below); defaults to `["metaWebhooks"]`
  - verifyToken: string - Optional token for hub challenge verification
  - headers: object - Optional static headers used to authenticate deliveries (e.g. `{"X-My-Token": "secret"}`). Sent on every raw-payload delivery (`metaWebhooks`, `metaCustomFieldHook`); format-converted deliveries (CleverTap / WebEngage / MoEngage) do not include them

```request
{
  "urls": [
    {
      "url": "https://your-server.com/webhooks/whatsapp",
      "isEnabled": true,
      "fields": ["metaWebhooks"],
      "headers": { "X-My-Token": "your-shared-secret" }
    }
  ]
}
```

## Response

```response
{
  "message": "Successfully added or updated webhook URL",
  "data": [
    {
      "url": "https://your-server.com/webhooks/whatsapp",
      "isEnabled": true,
      "fields": ["metaWebhooks"],
      "headers": { "X-My-Token": "*************ecret" }
    }
  ]
}
```

`data` returns **all** webhooks registered for your business (not just the ones in this request). Header values are masked in responses — only the last 5 characters are shown (values of 5 characters or fewer are fully masked). When updating a webhook, resend a masked value (any value starting with `*`) to keep the stored secret unchanged; omitting `headers` entirely on an update **removes** the stored headers.

:::

> [!IMPORTANT]
> Your webhook URL must use HTTPS and be publicly accessible. Localhost URLs will not work.

---

## Webhook Types

Each webhook URL subscribes to one or more **field types** that control which events it receives and in what format.

| Field Name            | Description                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `metaWebhooks`        | Raw Meta/WhatsApp webhook payloads (statuses and inbound messages)                                                              |
| `metaCustomFieldHook` | Meta webhook payload with your custom data attached (see [Custom Data in Webhooks guide](/docs/guides/custom-data-in-webhooks)) |
| `cleverTapStatus`     | Status updates converted to CleverTap format                                                                                    |
| `cleverTapMessages`   | Inbound messages converted to CleverTap format                                                                                  |
| `webEngageStatus`     | Status updates converted to WebEngage format                                                                                    |
| `moEngage`            | Status updates and inbound messages converted to MoEngage format                                                                |

> [!TIP]
> Use `metaCustomFieldHook` if you need to correlate webhook events back to your own system's data (order IDs, campaign tags, user segments, etc.). See the [Custom Data in Webhooks guide](/docs/guides/custom-data-in-webhooks) for a full walkthrough.

---

### Webhook Verification

If you provide a `verifyToken` when configuring your webhook, Heltar will send a verification request to your URL:

```
GET https://your-server.com/webhooks/whatsapp?hub.mode=subscribe&hub.challenge=123456789&hub.verify_token=YOUR_TOKEN
```

Your server should echo the raw `hub.challenge` value (a random numeric string) to confirm ownership. If your endpoint responds with an HTTP error status, the configure call fails; an unreachable endpoint or a wrong echo is logged on our side but does not block saving — so verify your handler echoes correctly before relying on it.

---

:::api
method: DELETE
endpoint: /v1/business/webhook-url
title: Delete Webhook URL
description: Remove one registered webhook URL to stop receiving event notifications on it. Returns 404 if the URL is not registered.

## Query Parameters

- url: string [required] - The exact webhook URL to remove

## Response

```response
{
  "message": "Successfully deleted webhook URL",
  "data": []
}
```

`data` contains your remaining webhook configurations (header values masked).

:::

---

## Webhook Events

Your webhook endpoint will receive POST requests with a JSON payload for each event. The payload format depends on the **field type** your webhook is subscribed to.

### Meta Webhook Format (`metaWebhooks`)

If your webhook uses the `metaWebhooks` field type, you receive raw Meta/WhatsApp payloads:

#### Message Received

Triggered when a customer sends you a message.

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "messages": [
              {
                "from": "919876543210",
                "id": "wamid.HBgLOTE5ODc...",
                "timestamp": "1705312200",
                "type": "text",
                "text": { "body": "Hello, I need help with my order!" }
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

> [!IMPORTANT]
> **Contacts who hide their phone number.** A WhatsApp user can pick a username
> and keep their number private. Their messages arrive with **no `from` field** —
> only `from_user_id`, WhatsApp's user ID for that person on your business
> account (for example `BD.1068713429041673`), alongside
> `contacts[].user_id` and `contacts[].profile.username`.
>
> Read the sender as `from ?? from_user_id`, and pass that same value back as
> `clientWaNumber` to reply. Delivery and read webhooks follow the same rule:
> `recipient_id` may be absent, and `recipient_user_id` is always there.

**Incoming Message Types:**

| Type          | Description                 | Data Structure                                                |
| ------------- | --------------------------- | ------------------------------------------------------------- |
| `text`        | Plain text message          | `{ text: { body: "..." } }`                                   |
| `image`       | Photo with optional caption | `{ image: { id, mime_type, sha256, caption? } }`              |
| `video`       | Video with optional caption | `{ video: { id, mime_type, sha256, caption? } }`              |
| `audio`       | Voice message or audio file | `{ audio: { id, mime_type, sha256 } }`                        |
| `document`    | PDF, DOC, or other files    | `{ document: { id, mime_type, sha256, filename, caption? } }` |
| `location`    | Shared location             | `{ location: { latitude, longitude, name?, address? } }`      |
| `contacts`    | Shared contact card         | `{ contacts: [{ name, phones, ... }] }`                       |
| `button`      | Quick reply button response | `{ button: { text, payload } }`                               |
| `interactive` | List or button selection    | `{ interactive: { type, button_reply?, list_reply? } }`       |

---

#### Message Status Update

Triggered when your outbound message status changes.

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "statuses": [
              {
                "id": "wamid.HBgLOTE5ODc...",
                "status": "delivered",
                "timestamp": "1705312260",
                "recipient_id": "919876543210"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

**Status Progression:**

| Status      | Description      | What it means                        |
| ----------- | ---------------- | ------------------------------------ |
| `sent`      | Sent to WhatsApp | Message accepted by WhatsApp servers |
| `delivered` | Delivered        | Message reached recipient's phone    |
| `read`      | Read             | Recipient opened the message         |
| `failed`    | Failed           | Message could not be delivered       |

---

#### Message Failed

Triggered when a message fails with detailed error information.

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "statuses": [
              {
                "id": "wamid.HBgLOTE5ODc...",
                "status": "failed",
                "timestamp": "1705312320",
                "recipient_id": "919876543210",
                "errors": [
                  {
                    "code": 131047,
                    "title": "Re-engagement message",
                    "message": "More than 24 hours have passed since the customer last replied"
                  }
                ]
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

**Common Error Codes:**

| Code   | Title                  | Description                            |
| ------ | ---------------------- | -------------------------------------- |
| 131047 | Re-engagement required | 24-hour window expired, use template   |
| 131051 | Recipient not found    | Invalid WhatsApp number                |
| 131052 | Rate limit             | Too many messages too quickly          |
| 131053 | Template not found     | Template doesn't exist or not approved |

---

### Custom Field Webhook Format (`metaCustomFieldHook`)

If your webhook uses the `metaCustomFieldHook` field type and you pass custom data via the `integrations` array when sending messages, your webhook receives the Meta payload with your custom data prepended:

```json
{
  "customField": {
    "order_id": "ORD-12345",
    "campaign": "summer_sale",
    "user_segment": "vip"
  },
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "statuses": [
              {
                "id": "wamid.HBgLOTE5ODc...",
                "status": "delivered",
                "timestamp": "1705312260",
                "recipient_id": "919876543210"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

> [!NOTE]
> The `customField` object contains exactly the data you passed in the `integrations` array when sending the message. See the [Messages API](/docs/api/messages#sending-custom-data-with-templates) for how to include custom data, or the [Custom Data in Webhooks guide](/docs/guides/custom-data-in-webhooks) for a complete walkthrough.

---

## Handling Webhooks

### Quick Response Pattern

Your webhook should respond quickly (within 5 seconds) to avoid timeouts. Process events asynchronously.

:::code-group

There is no event-name envelope: deliveries are the raw payloads shown above. Inbound customer messages arrive in `value.messages[]`, outbound status changes (including failures) in `value.statuses[]` — discriminate on which array is present.

```javascript
// Express.js example
const express = require('express');
const app = express();
app.use(express.json());

// Queue for async processing
const eventQueue = [];

app.post('/webhook', (req, res) => {
  // Respond immediately
  res.status(200).send('OK');

  // Queue for async processing
  eventQueue.push(req.body);
  processQueue();
});

async function processQueue() {
  while (eventQueue.length > 0) {
    const payload = eventQueue.shift();
    for (const entry of payload.entry ?? []) {
      for (const change of entry.changes ?? []) {
        const value = change.value ?? {};
        for (const message of value.messages ?? []) {
          await handleNewMessage(message); // inbound customer message
        }
        for (const status of value.statuses ?? []) {
          if (status.status === 'failed') await handleFailedMessage(status);
          else await handleStatusUpdate(status);
        }
      }
    }
  }
}

async function handleNewMessage(message) {
  console.log(`New message from ${message.from}: ${message.text?.body}`);
  // Your logic: save to DB, trigger bot, notify agent, etc.
}

app.listen(3000);
```

```python
from flask import Flask, request
import threading
import queue

app = Flask(__name__)
event_queue = queue.Queue()

@app.route('/webhook', methods=['POST'])
def webhook():
    # Respond immediately
    event_queue.put(request.json)
    return 'OK', 200

def process_events():
    while True:
        payload = event_queue.get()
        for entry in payload.get('entry', []):
            for change in entry.get('changes', []):
                value = change.get('value', {})
                for message in value.get('messages', []):
                    handle_new_message(message)  # inbound customer message
                for status in value.get('statuses', []):
                    handle_status_update(status)

        event_queue.task_done()

def handle_new_message(message):
    print(f"New message from {message['from']}: {message.get('text', {}).get('body')}")

# Start background processor
threading.Thread(target=process_events, daemon=True).start()

if __name__ == '__main__':
    app.run(port=3000)
```

:::

---

## Delivery & Retries

- **Request headers.** Every delivery is a `POST` with `Content-Type: application/json`, an `X-Request-Timestamp` header (ISO 8601, set when the delivery attempt is made), and — on raw-payload field types (`metaWebhooks`, `metaCustomFieldHook`) — any custom `headers` you registered. There is no signature header — authenticate deliveries with your own static header.
- **Timeout.** Each delivery attempt times out after **10 seconds**. Respond `200` as fast as possible (well under 5s) and process asynchronously.
- **What is retried.** Only network errors, timeouts, and `5xx` responses are retried. A `4xx` response is treated as permanently rejected — it is **not** retried.
- **Retry schedule.** Up to **5 retries** with randomized, increasing delays: roughly **1–5 minutes** for the first retry, growing to **4–5 hours** for the last. A retried event can therefore arrive long after — and out of order with — newer events. Order by the payload's own timestamps, never by arrival time.
- **Duplicates.** The same event is suppressed within a ~10-minute window, but redelivery beyond that is possible (and Meta itself can redeliver) — make handlers idempotent (dedupe on the message id / `(wamid, status)` pair).
- **Auto-disable.** Consecutive failed deliveries (the counter resets on any success) trigger a warning email after ~10 failures; at ~100 the webhook is **automatically disabled** and you're notified. Re-enable it with the configure endpoint above once your endpoint is healthy.

---

## Best Practices

> [!TIP]
> Follow these guidelines for reliable webhook handling:

| Practice                    | Description                                        |
| --------------------------- | -------------------------------------------------- |
| **Respond fast**            | Return 200 status within 5 seconds                 |
| **Process async**           | Queue events for background processing             |
| **Handle duplicates**       | Events may be delivered more than once             |
| **Use idempotent handlers** | Same event processed twice should have same result |
| **Tolerate reordering**     | Order by payload timestamps, not arrival time      |
| **Monitor failures**        | Sustained failures auto-disable the webhook        |

---

## Testing Webhooks

During development, use tools like [ngrok](https://ngrok.com) to expose your local server:

```bash
# Install ngrok and expose your local port
ngrok http 3000

# Use the HTTPS URL from ngrok as your webhook URL
# Example: https://abc123.ngrok.io/webhook
```
