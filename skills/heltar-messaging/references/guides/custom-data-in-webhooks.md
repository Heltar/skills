---
title: Custom Data in Webhooks
description: Pass custom data through template messages and receive it in webhook callbacks
icon: Webhook
order: 1
---

# Custom Data in Webhooks

Learn how to attach custom data (order IDs, campaign tags, user segments) to template messages and receive that data back in your webhook callbacks. This lets you correlate delivery statuses back to your own system without maintaining a separate mapping.

---

## Overview

The flow works in three steps:

1. **Configure** your webhook with the `metaCustomFieldHook` field type
2. **Send** a template message with custom data in the `integrations` array
3. **Receive** webhook callbacks with your custom data attached to each status update

---

## Step 1: Configure Your Webhook

Register a webhook URL with the `metaCustomFieldHook` field type:

:::code-group

```bash
curl -X POST '{{API_URL}}/v1/business/webhook-url' \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "urls": [
      {
        "url": "https://your-server.com/webhooks/whatsapp",
        "isEnabled": true,
        "fields": ["metaCustomFieldHook"]
      }
    ]
  }'
```

```javascript
const response = await fetch(`${API_URL}/v1/business/webhook-url`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    urls: [
      {
        url: 'https://your-server.com/webhooks/whatsapp',
        isEnabled: true,
        fields: ['metaCustomFieldHook'],
      },
    ],
  }),
});
```

```python
import requests

response = requests.post(
    f"{API_URL}/v1/business/webhook-url",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    },
    json={
        "urls": [
            {
                "url": "https://your-server.com/webhooks/whatsapp",
                "isEnabled": True,
                "fields": ["metaCustomFieldHook"],
            }
        ]
    },
)
```

:::

> [!TIP]
> You can subscribe to multiple field types on the same webhook URL. For example, `["metaCustomFieldHook", "metaWebhooks"]` will send you both custom-field-enriched payloads and raw Meta payloads.

---

## Step 2: Send a Template with Custom Data

When sending a template message, include an `integrations` array with your custom data:

:::code-group

```bash
curl -X POST '{{API_URL}}/v1/messages/send' \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [
      {
        "clientWaNumber": "919876543210",
        "messageType": "template",
        "templateName": "order_confirmation",
        "languageCode": "en",
        "variables": [
          {
            "type": "body",
            "parameters": [
              { "type": "text", "text": "ORD-12345" },
              { "type": "text", "text": "$99.99" }
            ]
          }
        ],
        "integrations": [
          {
            "name": "metaCustomFieldHook",
            "customField": {
              "order_id": "ORD-12345",
              "campaign": "summer_sale",
              "user_segment": "vip"
            }
          }
        ]
      }
    ]
  }'
```

```javascript
const response = await fetch(`${API_URL}/v1/messages/send`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    messages: [
      {
        clientWaNumber: '919876543210',
        messageType: 'template',
        templateName: 'order_confirmation',
        languageCode: 'en',
        variables: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: 'ORD-12345' },
              { type: 'text', text: '$99.99' },
            ],
          },
        ],
        integrations: [
          {
            name: 'metaCustomFieldHook',
            customField: {
              order_id: 'ORD-12345',
              campaign: 'summer_sale',
              user_segment: 'vip',
            },
          },
        ],
      },
    ],
  }),
});
```

```python
import requests

response = requests.post(
    f"{API_URL}/v1/messages/send",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    },
    json={
        "messages": [
            {
                "clientWaNumber": "919876543210",
                "messageType": "template",
                "templateName": "order_confirmation",
                "languageCode": "en",
                "variables": [
                    {
                        "type": "body",
                        "parameters": [
                            {"type": "text", "text": "ORD-12345"},
                            {"type": "text", "text": "$99.99"},
                        ],
                    }
                ],
                "integrations": [
                    {
                        "name": "metaCustomFieldHook",
                        "customField": {
                            "order_id": "ORD-12345",
                            "campaign": "summer_sale",
                            "user_segment": "vip",
                        },
                    }
                ],
            }
        ],
    },
)
```

:::

> [!TIP]
> The `customField` accepts any value — objects, strings, numbers, or arrays. Objects are the most common and useful format for structured tracking data.

---

## Step 3: Receive Webhook with Custom Data

When the message status changes (sent, delivered, read, or failed), your webhook receives the Meta payload with your `customField` data at the top level:

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

---

## Handling the Webhook

Here's how to extract and use the custom data in your webhook handler:

:::code-group

```javascript
// Express.js example
app.post('/webhooks/whatsapp', (req, res) => {
  // Respond immediately
  res.status(200).send('OK');

  const { customField, entry } = req.body;

  // Your custom data is at the top level
  if (customField) {
    console.log('Order ID:', customField.order_id);
    console.log('Campaign:', customField.campaign);
  }

  // Process status updates
  for (const change of entry?.[0]?.changes || []) {
    for (const status of change.value?.statuses || []) {
      console.log(`Message ${status.id}: ${status.status}`);

      // Update your system using the custom data
      if (customField?.order_id) {
        updateOrderStatus(customField.order_id, status.status);
      }
    }
  }
});
```

```python
from flask import Flask, request

app = Flask(__name__)

@app.route('/webhooks/whatsapp', methods=['POST'])
def webhook():
    data = request.json

    # Your custom data is at the top level
    custom_field = data.get('customField', {})
    if custom_field:
        print(f"Order ID: {custom_field.get('order_id')}")
        print(f"Campaign: {custom_field.get('campaign')}")

    # Process status updates
    for entry in data.get('entry', []):
        for change in entry.get('changes', []):
            for status in change.get('value', {}).get('statuses', []):
                print(f"Message {status['id']}: {status['status']}")

                # Update your system using the custom data
                if custom_field.get('order_id'):
                    update_order_status(custom_field['order_id'], status['status'])

    return 'OK', 200
```

:::

---

## Common Use Cases

| Use Case           | Example `customField`                                                |
| ------------------ | -------------------------------------------------------------------- |
| Order tracking     | `{"order_id": "ORD-12345", "store_id": "STORE-1"}`                   |
| Campaign analytics | `{"campaign_id": "camp_123", "variant": "A", "cohort": "new_users"}` |
| CRM sync           | `{"crm_contact_id": "SF-001", "deal_id": "DEAL-456"}`                |
| Support tickets    | `{"ticket_id": "TKT-789", "priority": "high"}`                       |
| User segmentation  | `{"user_segment": "vip", "ltv_tier": "gold"}`                        |

---

## Important Notes

> [!WARNING]
>
> - The `customField` is only included in webhooks for messages that were sent with the `integrations` array. Inbound customer messages will not have a `customField`.
> - If you need both raw Meta webhooks and custom field webhooks, register your URL with both field types: `["metaWebhooks", "metaCustomFieldHook"]`.
> - Webhook delivery is retried up to 5 times with exponential backoff if your endpoint fails. Ensure your handler is idempotent.
> - The same message ID + status combination will not trigger duplicate webhook calls within a 10-minute window.
