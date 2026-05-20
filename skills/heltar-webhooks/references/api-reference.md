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
  - fields: array [required] - Event types to receive (see Webhook Types below)
  - verifyToken: string - Optional token for hub challenge verification

```request
{
  "urls": [
    {
      "url": "https://your-server.com/webhooks/whatsapp",
      "isEnabled": true,
      "fields": ["metaWebhooks"]
    }
  ]
}
```

## Response

```response
{
  "code": "OK",
  "message": "Webhook URL configured successfully"
}
```

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
GET https://your-server.com/webhooks/whatsapp?hub.mode=subscribe&hub.challenge=RANDOM_STRING&hub.verify_token=YOUR_TOKEN
```

Your server must respond with the `hub.challenge` value to confirm ownership.

---

:::api
method: DELETE
endpoint: /v1/business/webhook-url
title: Delete Webhook URL
description: Remove your webhook configuration to stop receiving event notifications.

## Response

```response
{
  "code": "OK",
  "message": "Webhook URL removed"
}
```

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

```javascript
// Express.js example
const express = require('express');
const app = express();
app.use(express.json());

// Queue for async processing
const eventQueue = [];

app.post('/webhook', (req, res) => {
  const { event, data, timestamp } = req.body;

  // Respond immediately
  res.status(200).send('OK');

  // Queue for async processing
  eventQueue.push({ event, data, timestamp });
  processQueue();
});

async function processQueue() {
  while (eventQueue.length > 0) {
    const { event, data } = eventQueue.shift();

    switch (event) {
      case 'message.received':
        await handleNewMessage(data);
        break;
      case 'message.status':
        await handleStatusUpdate(data);
        break;
      case 'message.failed':
        await handleFailedMessage(data);
        break;
    }
  }
}

async function handleNewMessage(data) {
  console.log(`New message from ${data.from}: ${data.text?.body}`);
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
    data = request.json

    # Respond immediately
    event_queue.put(data)
    return 'OK', 200

def process_events():
    while True:
        data = event_queue.get()
        event = data.get('event')
        payload = data.get('data')

        if event == 'message.received':
            handle_new_message(payload)
        elif event == 'message.status':
            handle_status_update(payload)

        event_queue.task_done()

def handle_new_message(data):
    print(f"New message from {data['from']}: {data.get('text', {}).get('body')}")

# Start background processor
threading.Thread(target=process_events, daemon=True).start()

if __name__ == '__main__':
    app.run(port=3000)
```

:::

---

## Best Practices

> [!TIP]
> Follow these guidelines for reliable webhook handling:

| Practice                    | Description                                        |
| --------------------------- | -------------------------------------------------- |
| **Respond fast**            | Return 200 status within 5 seconds                 |
| **Process async**           | Queue events for background processing             |
| **Handle duplicates**       | Events may be delivered more than once             |
| **Log everything**          | Keep webhook logs for debugging                    |
| **Use idempotent handlers** | Same event processed twice should have same result |
| **Monitor failures**        | Set up alerts for webhook errors                   |

> [!WARNING]
> If your webhook consistently fails or times out, we may temporarily disable it. Ensure your endpoint is reliable and responds quickly.

---

## Testing Webhooks

During development, use tools like [ngrok](https://ngrok.com) to expose your local server:

```bash
# Install ngrok and expose your local port
ngrok http 3000

# Use the HTTPS URL from ngrok as your webhook URL
# Example: https://abc123.ngrok.io/webhook
```
