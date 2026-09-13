---
title: Messages
description: Send and receive messages
icon: MessageSquare
order: 3
---

# Messages API

Send WhatsApp messages programmatically - text, media, templates, and interactive messages - and read, search, and manage the conversation history for any contact.

All endpoints on this page take an API key in the `Authorization: Bearer <API key>` header. Endpoints under `/v1/messages` use the `messages:read` scope for `GET` requests and `messages:write` for everything else. See [Authentication](/docs/api/authentication) for how scopes work.

| Method | Endpoint                                     | Scope            | Purpose                                                |
| ------ | -------------------------------------------- | ---------------- | ------------------------------------------------------ |
| POST   | `/v1/messages/send`                          | `messages:write` | Send one or more messages                              |
| GET    | `/v1/messages/:clientWaNumber`               | `messages:read`  | Conversation history with a contact (paginated)        |
| GET    | `/v1/messages/search`                        | `messages:read`  | Search messages and contacts by text                   |
| GET    | `/v1/messages?wamid=`                        | `messages:read`  | Fetch a single message by ID                           |
| GET    | `/v1/messages/mark-read-msg/:clientWaNumber` | `messages:read`  | Mark the latest inbound message from a contact as read |
| GET    | `/v1/messages/flow-id/:flowId`               | `messages:read`  | Responses submitted through a WhatsApp Flow            |
| PUT    | `/v1/messages/:wamid`                        | `messages:write` | Attach a recording to a call message                   |
| GET    | `/v1/messages/fetch-media`                   | `messages:read`  | Download inbound media straight from WhatsApp          |
| GET    | `/v1/messages/presigned-url`                 | `messages:read`  | Get an upload URL for media you want to send           |
| POST   | `/v1/business/typing-indicator`              | Full access      | Show a typing indicator to a contact                   |

---

## Send Messages

:::api
method: POST
endpoint: /v1/messages/send
title: Send Messages
description: Send one or more WhatsApp messages in a single request. Supports text, media, template, interactive, location, and contact messages.

## Query Parameters

- priority: boolean - Skip the send queue and wait for WhatsApp's response even when your account has asynchronous message mode enabled. Accepts `true`/`false`, `1`/`0`, `yes`/`no` (default `false`). Any other value returns a 400.

## Body Parameters

- messages: array [required] - Array of message objects to send. Each object needs `clientWaNumber` and `messageType` plus the fields for that type (see Message Types below).
- campaignId: string - Optional ID of an existing campaign to attribute the messages to.

```request
{
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "messageType": "text",
      "message": "Hello! How can I help you today?",
      "refId": "order-12345"
    }
  ]
}
```

## Response

```response
{
  "message": "All messages have been scheduled successfully! You can receive updates on their status through a webhook.",
  "data": {
    "success": {
      "0": {
        "clientWaNumber": "919876543210",
        "message": {
          "wamid": "wamid.HBgLOTE5ODc2NTQzMjEwFQIAERgSMzY5QUJDREVGMTIzNDU2Nzg5AA==",
          "clientWaNumber": "919876543210",
          "phoneNumberId": "104857612345678",
          "type": "text",
          "body": "Hello! How can I help you today?",
          "status": "waiting",
          "timestamp": "2026-01-15T10:30:00.000Z",
          "refId": "order-12345"
        }
      }
    },
    "fail": {}
  }
}
```

:::

`data.success` and `data.fail` are objects keyed by the **position of the message in your `messages` array** (`"0"`, `"1"`, ...), so you can match every result back to what you sent.

- `success[i].message` is the saved message (same shape as [Get Message by ID](#get-message-by-id)). It starts in status `waiting` and moves to `sent`, `delivered`, `read`, or `failed` through webhooks. `refId` is echoed back if you sent one.
- `fail[i]` contains `clientWaNumber`, `errorCode` (the upstream HTTP status, or `500` for a local rejection such as a blocked or opted-out contact), `errorData` (WhatsApp's error object, or a plain error string), and `message` (the message object you sent).

| HTTP status | When                       | Body                                                                                                        |
| ----------- | -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 200         | Every message was accepted | `data.success` holds every message, `data.fail` is `{}`                                                     |
| 206         | Some messages failed       | `message` reads `"<n> messages have been scheduled successfully, <m> failed. ..."`; both maps are populated |
| 4xx / 5xx   | Every message failed       | Error envelope: `errorMessage` is `"Failed to send all messages"` and `errorRaw` holds `{ success, fail }`  |
| 400         | Request body invalid       | `errorMessage` is the first validation error, e.g. `"Invalid format. Expected a phone number, ..."`         |
| 503         | Send queue unavailable     | Asynchronous mode only. `errorMessage` asks you to retry after a few seconds                                |

When every message fails, the HTTP status is the most common `errorCode` across the failures (typically WhatsApp's `400`).

> [!NOTE]
> **Asynchronous message mode.** If this setting is enabled for your account, API calls return immediately with HTTP 200 and the message `"All messages have been queued for delivery. You will receive status updates through webhook."`. Each `success[i].message` then carries a temporary the platform ID in `wamid` (`hemid.MTIzOjkx...`), `status: "waiting"`, `type`, `timestamp`, and `phoneNumberId`. The real `wamid` arrives in your webhooks, and you can look the message up with either ID via [Get Message by ID](#get-message-by-id). Pass `?priority=true` to bypass the queue for a single request.

### Send Messages Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/messages/send" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "clientWaNumber": "919876543210",
        "messageType": "text",
        "message": "Hello! How can I help you today?"
      }
    ]
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/messages/send', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    messages: [
      {
        clientWaNumber: '919876543210',
        messageType: 'text',
        message: 'Hello! How can I help you today?',
      },
    ],
  }),
});
const { data } = await response.json();
console.log(data.success, data.fail);
```

```python
import requests

response = requests.post(
    '{{API_URL}}/v1/messages/send',
    headers={
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json',
    },
    json={
        'messages': [
            {
                'clientWaNumber': '919876543210',
                'messageType': 'text',
                'message': 'Hello! How can I help you today?',
            }
        ]
    },
)
data = response.json()['data']
print(data['success'], data['fail'])
```

:::

---

## Message Types

`messageType` must be one of `text`, `media`, `template`, `interactive`, `contacts`, or `location`. The value `sms` is reserved for a future channel and currently returns a 400 (`SMS channel is not yet available`).

> [!TIP]
> All message types share common fields: `clientWaNumber` (required), `messageType` (required), and `contextId` (optional - for replies).
>
> `clientWaNumber` takes a phone number with country code (`919876543210`) or,
> for a contact who hides their number behind a WhatsApp username, the user ID
> from their incoming message (`BD.1068713429041673`). Everything works with a
> user ID except one-tap, zero-tap and copy-code authentication templates, which
> WhatsApp only delivers to a phone number.

| Field            | Type    | Applies to          | Description                                                                                                                                                                                                                                                                             |
| ---------------- | ------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `clientWaNumber` | string  | all                 | Required. Phone number with country code (`919876543210`; `+`, spaces and dashes are stripped), a WhatsApp user ID (`BD.1068713429041673`), or a WhatsApp group ID. Anything else returns a 400.                                                                                        |
| `groupId`        | string  | all                 | Alias for `clientWaNumber` when sending to a group. If both are present, `clientWaNumber` wins.                                                                                                                                                                                         |
| `messageType`    | string  | all                 | Required. One of the types listed above.                                                                                                                                                                                                                                                |
| `contextId`      | string  | all except template | `wamid` of the message you are replying to. Not accepted on `template` messages (returns a 400).                                                                                                                                                                                        |
| `refId`          | string  | all                 | Your own reference for this message. It is not stored; it is echoed back as `message.refId` in the response so you can correlate results.                                                                                                                                               |
| `isPrivate`      | boolean | all                 | `true` saves the message as a private note in the inbox conversation. Nothing is sent to the contact.                                                                                                                                                                                   |
| `integrations`   | array   | all                 | Custom data attached to the message and forwarded in webhooks. Each item is `{ "name": "metaCustomFieldHook", "customField": ... }`; see [Sending Custom Data](#sending-custom-data-with-templates). `name` may also be `webEngage`, `cleverTap`, or `moEngage` for those integrations. |

`text`, `media`, and `template` messages reject unknown fields with a 400, so send only the fields documented for that type.

### Ask for a Phone Number

A contact who hides their number behind a WhatsApp username reaches you with
only a user ID. Send this interactive message to ask them to share their phone
number; when they tap the button, their number arrives in a `contacts` message
webhook with `"origin": "contact_request"`.

```json
{
  "clientWaNumber": "BD.1068713429041673",
  "messageType": "interactive",
  "interactive": {
    "type": "request_contact_info",
    "body": {
      "text": "Share your number so we can update you about your order."
    },
    "action": { "name": "request_contact_info" }
  }
}
```

The button label cannot be customised — WhatsApp renders it in the recipient's
own language. The same button is available on utility and marketing templates
as a `REQUEST_CONTACT_INFO` button.

### Text Message

Send a simple text message to a contact.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "text",
  "message": "Hello! How can I help you?",
  "contextId": "wamid.xxx"
}
```

| Field            | Type   | Required | Description                                   |
| ---------------- | ------ | -------- | --------------------------------------------- |
| `clientWaNumber` | string | Yes      | Recipient WhatsApp number (with country code) |
| `messageType`    | string | Yes      | Must be `text`                                |
| `message`        | string | Yes      | Message content (max 4096 chars)              |
| `contextId`      | string | No       | WhatsApp message ID to reply to               |

---

### Media Message

Send images, videos, documents, audio files, or stickers.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "media",
  "mediaType": "image",
  "url": "https://example.com/image.jpg",
  "name": "product.jpg",
  "mimeType": "image/jpeg",
  "size": 245760,
  "caption": "Check out our new product!"
}
```

| Field       | Type   | Required | Description                                         |
| ----------- | ------ | -------- | --------------------------------------------------- |
| `mediaType` | string | Yes      | `image`, `video`, `audio`, `document`, or `sticker` |
| `url`       | string | Yes      | Public HTTPS URL of media file                      |
| `name`      | string | Yes      | File name with extension                            |
| `mimeType`  | string | Yes      | MIME type (e.g., `image/jpeg`, `video/mp4`)         |
| `size`      | number | No       | File size in bytes, stored with the message         |
| `caption`   | string | No       | Caption text (not supported for audio/sticker)      |

Use [Get Presigned URL for Upload](#get-presigned-url-for-upload) if you need to host the file first.

**Supported Media Types:**

| Type     | Formats                 | Max Size |
| -------- | ----------------------- | -------- |
| Image    | JPEG, PNG               | 5 MB     |
| Video    | MP4, 3GPP               | 16 MB    |
| Audio    | AAC, MP4, AMR, OGG      | 16 MB    |
| Document | PDF, DOC, XLS, PPT, TXT | 100 MB   |
| Sticker  | WebP                    | 100 KB   |

---

### Template Message

Send pre-approved message templates (required for initiating conversations outside the 24-hour window).

| Field             | Type   | Required | Description                                                                                                                           |
| ----------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `templateName`    | string | Yes      | Template name (lowercase, underscores)                                                                                                |
| `languageCode`    | string | Yes      | Language code (e.g., `en`, `hi`, `es`)                                                                                                |
| `variables`       | array  | No       | Array of component variables (see below). Defaults to `[]`; `null` is accepted.                                                       |
| `templateContent` | string | No       | Body text used to render the message in the inbox and in history. Defaults to the approved template's body, with variables filled in. |
| `templateHeader`  | string | No       | Text header used for rendering, same as above.                                                                                        |

> [!NOTE]
> Our API uses `variables` which maps to Meta's `components` structure. Each variable object has a `type` and `parameters` array. `type` is one of `header`, `body`, `button`, `limited_time_offer`, or `carousel`.

Template messages to a contact who is blocked or has opted out are not sent; they are saved as failed and reported in `data.fail` with the reason.

---

#### Body Variables

Replace `{{1}}`, `{{2}}`, etc. placeholders in the template body with actual values.

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
        { "type": "text", "text": "ORD-12345" },
        { "type": "text", "text": "$99.99" }
      ]
    }
  ]
}
```

> [!TIP]
> Parameters are matched by position: first parameter replaces `{{1}}`, second replaces `{{2}}`, and so on.

---

#### Header with Image

For templates with image headers:

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "template",
  "templateName": "product_launch",
  "languageCode": "en",
  "variables": [
    {
      "type": "header",
      "parameters": [
        {
          "type": "image",
          "image": {
            "link": "https://example.com/product.jpg"
          }
        }
      ]
    },
    {
      "type": "body",
      "parameters": [
        { "type": "text", "text": "iPhone 15" },
        { "type": "text", "text": "$999" }
      ]
    }
  ]
}
```

---

#### Button with Dynamic URL

For templates with URL buttons that have dynamic suffixes:

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "template",
  "templateName": "order_tracking",
  "languageCode": "en",
  "variables": [
    {
      "type": "body",
      "parameters": [{ "type": "text", "text": "ORD-12345" }]
    },
    {
      "type": "button",
      "sub_type": "url",
      "index": 0,
      "parameters": [{ "type": "text", "text": "ORD-12345" }]
    }
  ]
}
```

> [!NOTE]
> The `index` field is 0-based and refers to the button position in the template.

---

#### Limited-Time Offer

For templates with a limited-time offer component, pass the expiry as a `limited_time_offer` variable:

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "template",
  "templateName": "flash_sale",
  "languageCode": "en",
  "variables": [
    {
      "type": "limited_time_offer",
      "parameters": [
        {
          "type": "limited_time_offer",
          "limited_time_offer": { "expiration_time_ms": 1768478400000 }
        }
      ]
    },
    {
      "type": "button",
      "sub_type": "copy_code",
      "index": 0,
      "parameters": [{ "type": "coupon_code", "coupon_code": "SAVE20" }]
    }
  ]
}
```

---

#### Carousel Template

For carousel templates, send one `carousel` variable with a `cards` array. Each card has a 0-based `card_index` and its own `variables` (`header`, `body`, `button`):

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "template",
  "templateName": "new_arrivals",
  "languageCode": "en",
  "variables": [
    {
      "type": "body",
      "parameters": [{ "type": "text", "text": "John" }]
    },
    {
      "type": "carousel",
      "cards": [
        {
          "card_index": 0,
          "variables": [
            {
              "type": "header",
              "parameters": [
                {
                  "type": "image",
                  "image": { "link": "https://example.com/shoe.jpg" }
                }
              ]
            },
            {
              "type": "button",
              "sub_type": "url",
              "index": 0,
              "parameters": [{ "type": "text", "text": "SKU-12345" }]
            }
          ]
        },
        {
          "card_index": 1,
          "variables": [
            {
              "type": "header",
              "parameters": [
                {
                  "type": "image",
                  "image": { "link": "https://example.com/bag.jpg" }
                }
              ]
            },
            {
              "type": "button",
              "sub_type": "url",
              "index": 0,
              "parameters": [{ "type": "text", "text": "SKU-12346" }]
            }
          ]
        }
      ]
    }
  ]
}
```

---

#### Sending Custom Data with Templates

You can attach custom data to any template message using the `integrations` array. This data is stored with the message and included in webhook callbacks, allowing you to correlate webhook events back to your own system.

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
```

| Field                        | Type   | Required | Description                                                         |
| ---------------------------- | ------ | -------- | ------------------------------------------------------------------- |
| `integrations`               | array  | No       | Array of integration objects for custom webhook data                |
| `integrations[].name`        | string | Yes      | Integration type. Use `metaCustomFieldHook` for custom webhook data |
| `integrations[].customField` | any    | Yes      | Your custom key-value data (object or string, auto-converted)       |

> [!TIP]
> Your business webhook must be configured with the `metaCustomFieldHook` field type to receive custom data. See the [Webhooks API](/docs/api/webhooks) and the [Custom Data in Webhooks guide](/docs/guides/custom-data-in-webhooks) for details.

---

### Interactive Messages

Set `messageType` to `interactive` and describe the message in the `interactive` object. `interactive.type` selects the layout:

| `interactive.type`         | What it sends                                                       |
| -------------------------- | ------------------------------------------------------------------- |
| `button`                   | Up to 3 quick reply buttons                                         |
| `list`                     | A dropdown list of options                                          |
| `cta_url`                  | A single call-to-action button that opens a URL                     |
| `flow`                     | A button that opens a WhatsApp Flow                                 |
| `location_request_message` | Asks the contact to share their location                            |
| `address_message`          | Asks the contact for a delivery address                             |
| `request_contact_info`     | Asks the contact to share their phone number (see above)            |
| `catalog_message`          | Opens your WhatsApp catalog                                         |
| `product`                  | A single product from your catalog                                  |
| `product_list`             | Several products from your catalog, grouped into sections           |
| `carousel`                 | 2 to 10 swipeable cards, each with an image or video and one action |

Every type takes a `body.text`, most take an optional `footer.text`, and `button`, `cta_url`, `flow`, `address_message`, and `location_request_message` also accept an optional `header`: `{ "type": "text", "text": "..." }` or `{ "type": "image" | "video" | "document" | "audio" | "sticker", "<type>": { "link": "https://..." } }`. `list` and `product_list` accept a text header only.

---

### Interactive Button Message

Send a message with up to 3 quick reply buttons.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "button",
    "body": { "text": "How would you like to proceed?" },
    "action": {
      "buttons": [
        { "type": "reply", "reply": { "id": "btn_yes", "title": "Yes" } },
        { "type": "reply", "reply": { "id": "btn_no", "title": "No" } }
      ]
    }
  }
}
```

> [!NOTE]
> Button titles can be max 20 characters. Button IDs can be max 256 characters.

---

### Interactive List Message

Send a message with a dropdown list of options (max 10 items per section, max 10 sections).

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "list",
    "body": { "text": "Select a category:" },
    "action": {
      "button": "View Options",
      "sections": [
        {
          "title": "Products",
          "rows": [
            {
              "id": "electronics",
              "title": "Electronics",
              "description": "Phones, laptops, gadgets"
            },
            {
              "id": "clothing",
              "title": "Clothing",
              "description": "Shirts, pants, accessories"
            }
          ]
        }
      ]
    }
  }
}
```

---

### Interactive URL Button Message

Send a single button that opens a link.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "cta_url",
    "header": { "type": "text", "text": "Order #12345" },
    "body": { "text": "Your order is on its way. Track it live." },
    "footer": { "text": "Heltar Store" },
    "action": {
      "name": "cta_url",
      "parameters": {
        "display_text": "Track order",
        "url": "https://example.com/track/12345"
      }
    }
  }
}
```

---

### Interactive Flow Message

Open a WhatsApp Flow (a multi-screen form) from a button. Use the flow ID from your WhatsApp Manager.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "flow",
    "header": { "type": "text", "text": "Book an appointment" },
    "body": { "text": "Pick a date and time that works for you." },
    "action": {
      "name": "flow",
      "parameters": {
        "flow_id": "1234567890123456",
        "flow_message_version": "3",
        "flow_token": "order-12345",
        "flow_cta": "Book now",
        "flow_action": "navigate",
        "mode": "published",
        "flow_action_payload": {
          "screen": "APPOINTMENT",
          "data": { "customer_name": "John" }
        }
      }
    }
  }
}
```

| Field                  | Type   | Required | Description                                                                                          |
| ---------------------- | ------ | -------- | ---------------------------------------------------------------------------------------------------- |
| `flow_id`              | string | Yes      | Flow ID (a number is accepted and converted to a string)                                             |
| `flow_message_version` | string | Yes      | Flow message version, currently `"3"`                                                                |
| `flow_token`           | string | Yes      | Your own token. WhatsApp returns it with the submitted form, so put an identifier you can match here |
| `flow_cta`             | string | Yes      | Button label                                                                                         |
| `flow_action`          | string | Yes      | `navigate` or `data_exchange`                                                                        |
| `mode`                 | string | No       | `published` (default on WhatsApp) or `draft`                                                         |
| `flow_action_payload`  | object | Yes      | `{ "screen": "<first screen id>", "data": { ... } }`; `data` is optional                             |

Submitted responses arrive in your webhook as an `interactive` message of type `nfm_reply`, and can also be listed with [Get Flow Responses](#get-flow-responses).

---

### Location Request Message

Ask the contact to share their current location. Their reply arrives as a `location` message in your webhook.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "location_request_message",
    "body": { "text": "Share your delivery location." },
    "action": { "name": "send_location" }
  }
}
```

---

### Address Message

Ask the contact for a delivery address using WhatsApp's native address form. `country` is the ISO 3166-1 alpha-2 country code; `values` pre-fills fields, `saved_addresses` offers previously used addresses, and `validation_errors` marks fields to correct.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "address_message",
    "body": { "text": "Where should we deliver Order #12345?" },
    "action": {
      "name": "address_message",
      "parameters": {
        "country": "IN",
        "values": { "name": "John Doe", "phone_number": "919876543210" },
        "saved_addresses": [
          {
            "id": "home",
            "value": {
              "name": "John Doe",
              "phone_number": "919876543210",
              "address": "12 MG Road",
              "city": "Bengaluru",
              "in_pin_code": "560001"
            }
          }
        ]
      }
    }
  }
}
```

---

### Catalog and Product Messages

Send your whole catalog, one product, or a list of products. `catalog_id` and `product_retailer_id` come from the catalog connected to your WhatsApp Business account.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "catalog_message",
    "body": { "text": "Browse our latest collection." },
    "footer": { "text": "Tap to view the catalog" },
    "action": {
      "name": "catalog_message",
      "parameters": { "thumbnail_product_retailer_id": "SKU-12345" }
    }
  }
}
```

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "product",
    "body": { "text": "Here is the item you asked about." },
    "action": {
      "catalog_id": "123456789012345",
      "product_retailer_id": "SKU-12345"
    }
  }
}
```

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "product_list",
    "header": { "type": "text", "text": "Best sellers" },
    "body": { "text": "Pick a product to see details." },
    "action": {
      "catalog_id": "123456789012345",
      "sections": [
        {
          "title": "Shoes",
          "product_items": [
            { "product_retailer_id": "SKU-12345" },
            { "product_retailer_id": "SKU-12346" }
          ]
        }
      ]
    }
  }
}
```

For `catalog_message` and `product`, `body` is optional. `product_list` requires a text `header`.

---

### Interactive Carousel Message

Send 2 to 10 swipeable cards. Each card needs a `card_index` (0-9), `"type": "cta_url"`, an image or video `header`, an optional `body`, and either a URL button or one or more quick reply buttons as its `action`.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "interactive",
  "interactive": {
    "type": "carousel",
    "body": { "text": "New arrivals this week" },
    "action": {
      "cards": [
        {
          "card_index": 0,
          "type": "cta_url",
          "header": {
            "type": "image",
            "image": { "link": "https://example.com/shoe.jpg" }
          },
          "body": { "text": "Runner X" },
          "action": {
            "name": "cta_url",
            "parameters": {
              "display_text": "View",
              "url": "https://example.com/p/runner-x"
            }
          }
        },
        {
          "card_index": 1,
          "type": "cta_url",
          "header": {
            "type": "video",
            "video": { "link": "https://example.com/bag.mp4" }
          },
          "body": { "text": "Tote Y" },
          "action": {
            "buttons": [
              {
                "type": "quick_reply",
                "quick_reply": { "id": "bag_more", "title": "Tell me more" }
              }
            ]
          }
        }
      ]
    }
  }
}
```

---

### Contacts Message

Share one or more contact cards.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "contacts",
  "contacts": [
    {
      "name": { "formatted_name": "Priya Sharma", "prefix": "Ms." },
      "phones": [{ "phone": "+91 98765 43211", "wa_id": "919876543211" }]
    }
  ]
}
```

| Field               | Type   | Required | Description                                                    |
| ------------------- | ------ | -------- | -------------------------------------------------------------- |
| `contacts`          | array  | Yes      | One or more contact cards                                      |
| `contacts[].name`   | object | Yes      | `formatted_name` (display name) and `prefix` are both required |
| `contacts[].phones` | array  | Yes      | Each entry needs `phone` (display value) and `wa_id`           |

---

### Location Message

Send a pin on the map. `name` and `address` are optional labels shown under the pin.

```json
{
  "clientWaNumber": "919876543210",
  "messageType": "location",
  "location": {
    "latitude": 28.6139,
    "longitude": 77.209,
    "name": "Heltar Store",
    "address": "Connaught Place, New Delhi"
  }
}
```

---

## Get Client Messages

:::api
method: GET
endpoint: /v1/messages/:clientWaNumber
title: Get Client Messages
description: Retrieve conversation history with a specific contact. The newest `limit` messages are returned in chronological order (oldest first). Use the `before`/`beforeId` cursor to page further back through long histories.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number of the contact

## Query Parameters

- limit: number - Maximum messages to return (default: 10000, max: 10000)
- before: string - ISO timestamp of the oldest message you already have. Returns only messages older than it.
- beforeId: string - `wamid` of that same oldest message. Send it together with `before` so messages sharing a timestamp are not skipped or repeated.

## Response

```response
{
  "message": "Successfully retrieved messages",
  "data": {
    "messages": [
      {
        "wamid": "wamid.HBgLOTE5ODc...",
        "type": "text",
        "body": "Hello!",
        "status": "received",
        "timestamp": "2026-01-15T10:30:00.000Z"
      },
      {
        "wamid": "wamid.HBgLOTE5ODd...",
        "type": "template",
        "templateName": "order_update",
        "body": "Your order has shipped.",
        "status": "delivered",
        "timestamp": "2026-01-15T10:31:00.000Z"
      }
    ],
    "clientWaNumber": "919876543210",
    "conversationExpire": "2026-01-16T10:30:00.000Z",
    "hasMore": true,
    "canMessage": true
  }
}
```

:::

- `hasMore` — older messages exist beyond this page. To fetch them, call again with `before` set to the first (oldest) message's `timestamp` and `beforeId` set to its `wamid`. Repeat until `hasMore` is `false`.
- `status` is the direction discriminator: `received` marks an inbound (customer) message — treat every other value as outbound. Outbound messages progress `waiting → sent → delivered → read` (or `failed`); campaign/template messages can additionally show `responded`, `clicked`, `clicked_responded`, or `expired`. The timestamp of the newest `received` message is the last inbound customer activity.
- `conversationExpire` — when the current 24-hour reply window closes (last inbound message + 24h). `canMessage` is `true` while that window is open.

| HTTP status | `errorMessage`                               | Cause                                              |
| ----------- | -------------------------------------------- | -------------------------------------------------- |
| 400         | `before must be a valid ISO timestamp`       | `before` could not be parsed as a date             |
| 400         | `beforeId must be sent together with before` | `beforeId` was sent without `before`               |
| 404         | `919876543210 not exist!`                    | No contact with that number exists on your account |

### Get Client Messages Example

```bash
# First page (newest 50 messages)
curl "{{API_URL}}/v1/messages/919876543210?limit=50" \
  -H "Authorization: Bearer YOUR_API_KEY"

# Next page back in time, using the oldest message from the previous page
curl "{{API_URL}}/v1/messages/919876543210?limit=50&before=2026-01-15T10:30:00.000Z&beforeId=wamid.HBgLOTE5ODc..." \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Search Messages

:::api
method: GET
endpoint: /v1/messages/search
title: Search Messages
description: Full-text search across every conversation on your account. Returns matching contacts and matching messages in one call, newest first.

## Query Parameters

- searchQuery: string [required] - Text to search for. Split on spaces into words; every word must appear (case-insensitive substring match). The characters `& | ! ( ) : * ? " ' < > [ ] { } + - . / \` are treated as spaces.
- limit: number [required] - Maximum number of results in each of `chats` and `messages`.
- cursor: string - ISO timestamp. Only results older than it are returned. Pass the `newCursor` from the previous response to get the next page.
- clientWaNumber: string - Restrict the search to one contact's conversation.

## Response

```response
{
  "message": "Successfully fetched messages in 42ms",
  "data": {
    "chats": [
      {
        "wamid": "wamid.HBgLOTE5ODc2NTQzMjEw...",
        "clientWaNumber": "919876543210",
        "phoneNumberId": "104857612345678",
        "businessId": 12345,
        "timestamp": "2026-01-15 10:31:00.000",
        "status": "delivered",
        "type": "text",
        "body": "Your order #12345 has shipped.",
        "sentByName": "Priya",
        "statusTime": {
          "sent": "2026-01-15T10:31:01.000Z",
          "delivered": "2026-01-15T10:31:04.000Z"
        }
      }
    ],
    "messages": [
      {
        "wamid": "wamid.HBgLOTE5ODc2NTQzMjEx...",
        "clientWaNumber": "919876543211",
        "phoneNumberId": "104857612345678",
        "businessId": 12345,
        "timestamp": "2026-01-14 18:02:10.000",
        "status": "received",
        "type": "media",
        "caption": "Invoice for order #12345",
        "name": "invoice-12345.pdf",
        "mimeType": "application/pdf",
        "size": 58386,
        "awsLink": "https://cdn.heltar.com/media/abc123.pdf"
      }
    ],
    "newCursor": "2026-01-14T18:02:10.000Z"
  }
}
```

:::

- `chats` lists contacts whose **phone number** contains the search words, one entry per contact (their most recent message). `messages` lists every message whose **text, caption, or file/template name** contains the words. Both are ordered newest first and each is capped at `limit`.
- Every result carries the full message record: `wamid`, `clientWaNumber`, `phoneNumberId`, `businessId`, `timestamp`, `status`, `type`, `body`, `caption`, `name`, `size`, `mimeType`, `sha256`, `awsLink`, `templateName`, `langCode`, `category`, `campaignId`, `advertisementId`, `sentByName`, `failureReason`, `dimensions`, `interactive`, `context`, `reaction`, `metaData`, `integrations`, and `statusTime`. Fields that do not apply to a message type are empty or `null`. `timestamp` is a UTC `YYYY-MM-DD HH:MM:SS.mmm` string.
- `newCursor` is the timestamp of the oldest result across both lists, or `null` when nothing matched. Pass it back as `cursor` to page further; stop when both lists come back empty.
- Contact names are not searched. Look up a contact by number with [Get Contact](/docs/api/contacts) instead.

| HTTP status | `errorMessage`                                      | Cause                                                          |
| ----------- | --------------------------------------------------- | -------------------------------------------------------------- |
| 400         | `Invalid request data`                              | `searchQuery` or `limit` is missing                            |
| 400         | `Invalid cursor format`                             | `cursor` could not be parsed as a date                         |
| 400         | `Search query only contains unsupported characters` | Nothing was left to search after the reserved characters above |
| 500         | `Internal Server Error`                             | Search is temporarily unavailable or timed out. Retry later    |

### Search Messages Example

```bash
curl "{{API_URL}}/v1/messages/search?searchQuery=order%2012345&limit=20" \
  -H "Authorization: Bearer YOUR_API_KEY"

# Only inside one conversation, next page
curl "{{API_URL}}/v1/messages/search?searchQuery=invoice&limit=20&clientWaNumber=919876543210&cursor=2026-01-14T18:02:10.000Z" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Get Message by ID

:::api
method: GET
endpoint: /v1/messages?wamid=xxx
title: Get Message by ID
description: Retrieve a single message by its WhatsApp message ID (`wamid`) or platform message ID (`hemid`). Useful for looking up specific messages — for example, when your webhook receives a media message and you want to fetch the saved version with the hosted media URL.

## Query Parameters

- wamid: string [required] - The message ID. Supports both formats:
  - **WhatsApp message ID** — e.g., `wamid.HBgLOTE5ODc...` (assigned by WhatsApp when the message is sent/received)
  - **platform message ID** — e.g., `hemid.MTIzOjkx...` (assigned by the platform for async/queued messages before WhatsApp assigns a wamid)

## Response

For a **media message** (image, video, document, audio, sticker):

```response
{
  "message": "Successfully retrieved message",
  "data": {
    "wamid": "wamid.HBgMOTE4NjA2NDA1NjQx...",
    "hemid": null,
    "clientWaNumber": "918606405641",
    "status": "received",
    "timestamp": "2026-03-16T13:32:32.000Z",
    "type": "media",
    "name": "photo.jpg",
    "caption": "",
    "mimeType": "image/jpeg",
    "size": 58386,
    "sha256": "FghN0jxjw+skZm+GifvSMTWYjjlnDWKlUpKY1YhJnxM=",
    "awsLink": "https://cdn.heltar.com/media/abc123.jpg",
    "dimensions": { "width": 1080, "height": 1920 }
  }
}
```

For a **text message**:

```response
{
  "message": "Successfully retrieved message",
  "data": {
    "wamid": "wamid.HBgLOTE5ODc...",
    "hemid": null,
    "clientWaNumber": "919876543210",
    "status": "delivered",
    "timestamp": "2024-01-15T10:30:00Z",
    "type": "text",
    "body": "Hello! How can I help you?"
  }
}
```

:::

| HTTP status | `errorMessage`                      | Cause                                              |
| ----------- | ----------------------------------- | -------------------------------------------------- |
| 400         | `wamid query parameter is required` | No `wamid` in the query string                     |
| 404         | `Message not found`                 | No message with that ID (see the media note below) |

### Get Message by ID Example

```bash
curl "{{API_URL}}/v1/messages?wamid=wamid.HBgLOTE5ODc..." \
  -H "Authorization: Bearer YOUR_API_KEY"
```

> [!WARNING]
> **Why you might get a 404 for media messages:** When a customer sends a media message (image, document, video, etc.), the platform forwards the webhook to your endpoint **immediately**. However, downloading the media from WhatsApp and uploading it to our CDN takes a few seconds. So if you call this endpoint right after receiving the webhook, you may get a **404 Not Found** because the message hasn't been saved yet, or the `awsLink` field may be empty while the upload is still in progress.

> [!TIP]
> **Option 1 — Instant access (recommended):** Use `GET /v1/messages/fetch-media?url=<encoded_url>` to download the file directly from WhatsApp. The webhook already contains the media URL (see the full webhook example below in the Fetch Media section). No waiting needed.

> [!INFO]
> **Option 2 — Permanent public URL:** Retry this endpoint after 3-5 seconds. Once the media has been processed, the `awsLink` field will contain a permanent CDN URL that never expires — useful for storing or sharing the link.

---

## Mark Messages as Read

:::api
method: GET
endpoint: /v1/messages/mark-read-msg/:clientWaNumber
title: Mark Messages as Read
description: Send a read receipt (blue ticks) to a contact for their most recent inbound message. WhatsApp treats this as reading the whole conversation up to that message.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number (or user ID) of the contact

## Response

```response
{
  "message": "Successfully send read status!",
  "data": {
    "message": "Message marked as read!"
  }
}
```

:::

The HTTP status is always 200; check `data.message` for the outcome:

| `data.message`                                                      | Meaning                                                                                                                         |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `Message marked as read!`                                           | The read receipt was sent, or the contact has no inbound message to acknowledge (nothing to do)                                 |
| `Mark read message is disabled! Please enable it from the settings` | The "Let contacts know when you've read their messages" setting is off in your dashboard. Turn it on and retry                  |
| `Error while marking message as read`                               | WhatsApp rejected the read receipt (for example, the message is too old or the number is not a WhatsApp user). Nothing was sent |

> [!NOTE]
> Sending any non-template message through [Send Messages](#send-messages) already marks the conversation as read when the setting is enabled, so you only need this endpoint when you want to show blue ticks without replying. To combine a read receipt with a typing bubble, use the [Typing indicator](#typing-indicator) endpoint instead.

### Mark Messages as Read Example

```bash
curl "{{API_URL}}/v1/messages/mark-read-msg/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Get Flow Responses

:::api
method: GET
endpoint: /v1/messages/flow-id/:flowId
title: Get Flow Responses
description: List the form submissions your contacts sent back through a WhatsApp Flow. Returns every inbound interactive message on your account whose payload contains the given flow ID.

## Path Parameters

- flowId: string [required] - The WhatsApp Flow ID (the `flow_id` you send in an interactive `flow` message)

## Response

```response
{
  "message": "Successfully fetched form responses",
  "data": [
    {
      "clientWaNumber": "919876543210",
      "interactive": {
        "type": "nfm_reply",
        "nfm_reply": {
          "name": "flow",
          "body": "Sent",
          "response_json": "{\"flow_token\":\"order-12345\",\"flow_id\":\"1234567890123456\",\"full_name\":\"John Doe\",\"preferred_slot\":\"morning\"}"
        }
      }
    }
  ]
}
```

:::

- Each item has only two fields: `clientWaNumber` (who submitted the form) and `interactive` (the reply as received from WhatsApp). The submitted answers are in `interactive.nfm_reply.response_json`, a JSON **string** you need to parse. WhatsApp always includes your `flow_token` in it; the other keys are whatever the flow's final screen submits.
- Matching is a plain text match of `flowId` against the stored reply, so a submission is found only if the flow ID appears somewhere in it. Forms built in the dashboard include `flow_id` in every submission automatically. For flows you build yourself, either add `flow_id` to the data submitted by the flow's final screen or include the flow ID in the `flow_token` you send.
- Results are not paginated and are not ordered; the full list is returned on every call. Sending this endpoint an ID that matches nothing returns `"data": []`.

### Get Flow Responses Example

```bash
curl "{{API_URL}}/v1/messages/flow-id/1234567890123456" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Attach a Recording to a Call Message

:::api
method: PUT
endpoint: /v1/messages/:wamid
title: Attach a Recording to a Call Message
description: Store an audio recording against a call message so it plays inline in the inbox. The audio is fetched from `awsLink`, converted to MP3, re-hosted, and the new link is saved on the message.

## Path Parameters

- wamid: string [required] - ID of the call message. Send the same value in the body; the body value is the one used to look up the message.

## Body Parameters

- wamid: string [required] - ID of the call message to update
- awsLink: string [required] - Public URL of the audio file (for example the `url` returned after uploading through Get Presigned URL for Upload)
- name: string - Original file name, used to name the converted file

```request
{
  "wamid": "wamid.HBgLOTE5ODc2NTQzMjEw...",
  "awsLink": "https://cdn.example.com/media/abc123-call-recording.webm",
  "name": "call-recording-2026-01-15.webm"
}
```

## Response

```response
{
  "message": "Successfully updated message!",
  "data": {
    "wamid": "wamid.HBgLOTE5ODc2NTQzMjEw...",
    "clientWaNumber": "919876543210",
    "type": "interactive",
    "status": "received",
    "timestamp": "2026-01-15T10:30:00.000Z",
    "body": "Voice call",
    "interactive": { "type": "call" },
    "awsLink": "https://cdn.example.com/media/xyz789-call-recording.mp3"
  }
}
```

:::

This is the only field of a message that can be changed through the API. Message text, status, and other fields are read-only.

- Only messages of type `interactive` (which is how call log messages are stored) are updated. For any other message type the request still returns 200 with the unchanged message in `data`, and nothing is saved.
- If the audio cannot be fetched or converted, the original `awsLink` is stored as-is instead of the MP3 link.
- The saved link is `data.awsLink` in the response. The inbox is updated in real time so the recording appears without a refresh.

| HTTP status | Body                                                        | Cause                                            |
| ----------- | ----------------------------------------------------------- | ------------------------------------------------ |
| 204         | Empty                                                       | No message with the given `wamid` exists         |
| 400         | `errorMessage` is the validation error (e.g. `Invalid url`) | `awsLink` is not a valid URL or `wamid` is empty |

### Attach a Recording Example

```bash
curl -X PUT "{{API_URL}}/v1/messages/wamid.HBgLOTE5ODc2NTQzMjEw..." \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "wamid": "wamid.HBgLOTE5ODc2NTQzMjEw...",
    "awsLink": "https://cdn.example.com/media/abc123-call-recording.webm",
    "name": "call-recording-2026-01-15.webm"
  }'
```

---

## Fetch Media from WhatsApp

:::api
method: GET
endpoint: /v1/messages/fetch-media?url=xxx
title: Fetch Media from WhatsApp
description: Download a media file directly from WhatsApp's servers. Use this when you receive a media message via webhook and need the file immediately, without waiting for it to be processed and uploaded to our CDN.

## Query Parameters

- url: string [required] - The media URL from the webhook payload, **URL-encoded** using `encodeURIComponent()`. This is the `url` field inside the media object (e.g., `message.image.url`, `message.document.url`, etc.)

```request
GET /v1/messages/fetch-media?url=https%3A%2F%2Flookaside.fbsbx.com%2Fwhatsapp_business%2Fattachments%2F%3Fmid%3DMEDIA_ID%26source%3Dwebhook%26ext%3DEXPIRY%26hash%3DHASH_VALUE
```

## Response

The response is the **raw binary file** with the appropriate `Content-Type` header (e.g., `image/jpeg`, `application/pdf`, `video/mp4`). This is **not a JSON response** — it returns the file directly.

:::

### When to use this

When WhatsApp sends a media message webhook, the payload includes a temporary media URL like:

```
https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=1428354048768552&source=webhook&ext=...
```

This URL **requires WhatsApp authentication** to access — you cannot download it directly. This endpoint acts as a proxy: you pass the URL as a query parameter, and we fetch the file using your business's WhatsApp access token.

| HTTP status | Body                                               | Cause                                                                                      |
| ----------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| 400         | `{ "error": "Invalid URL" }`                       | `url` is missing or not a valid URL                                                        |
| 403         | `{ "error": "graph.facebook.com is not allowed" }` | Only media attachment URLs are accepted; Graph API URLs are refused                        |
| other       | WhatsApp's error body                              | WhatsApp refused the download (for example, the URL expired). Its status is passed through |

### Fetch Media Example

```bash
curl "{{API_URL}}/v1/messages/fetch-media?url=https%3A%2F%2Flookaside.fbsbx.com%2Fwhatsapp_business%2Fattachments%2F%3Fmid%3DMEDIA_ID%26source%3Dwebhook%26ext%3DEXPIRY%26hash%3DHASH_VALUE" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  --output invoice.pdf
```

### How to use Fetch Media

**Step 1.** When a customer sends a media message, you receive a webhook like this. The media URL you need is inside the message object:

**Image webhook:**

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "YOUR_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "contacts": [
              {
                "profile": { "name": "Customer Name" },
                "wa_id": "919123456789"
              }
            ],
            "messages": [
              {
                "from": "919123456789",
                "id": "wamid.ABCDEFxxxxxxxx",
                "timestamp": "1700000000",
                "type": "image",
                "image": {
                  "mime_type": "image/jpeg",
                  "sha256": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
                  "id": "MEDIA_ID",
                  "url": "https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=MEDIA_ID&source=webhook&ext=EXPIRY&hash=HASH_VALUE"
                }
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

**Document webhook:**

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "YOUR_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "919876543210",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "contacts": [
              {
                "profile": { "name": "Customer Name" },
                "wa_id": "919123456789"
              }
            ],
            "messages": [
              {
                "from": "919123456789",
                "id": "wamid.ABCDEFxxxxxxxx",
                "timestamp": "1700000000",
                "type": "document",
                "document": {
                  "filename": "Invoice.pdf",
                  "mime_type": "application/pdf",
                  "sha256": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
                  "id": "MEDIA_ID",
                  "url": "https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=MEDIA_ID&source=webhook&ext=EXPIRY&hash=HASH_VALUE"
                }
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

The media URL is at `entry[0].changes[0].value.messages[0].<type>.url` where `<type>` is `image`, `document`, `video`, `audio`, or `sticker`. Each media type has `id`, `mime_type`, `sha256`, and `url` fields. `document` also includes `filename`.

**Step 2.** URL-encode the media URL using `encodeURIComponent()` and pass it as a query parameter:

```javascript
// JavaScript example
const mediaUrl = webhook.entry[0].changes[0].value.messages[0].image.url;
const response = await fetch(
  `{{API_URL}}/v1/messages/fetch-media?url=${encodeURIComponent(mediaUrl)}`,
  { headers: { Authorization: 'Bearer YOUR_API_KEY' } },
);
```

```
// cURL example
GET /v1/messages/fetch-media?url=https%3A%2F%2Flookaside.fbsbx.com%2Fwhatsapp_business%2Fattachments%2F%3Fmid%3DMEDIA_ID%26source%3Dwebhook%26ext%3DEXPIRY%26hash%3DHASH_VALUE
Authorization: Bearer YOUR_API_KEY
```

**Step 3.** The response will be the raw binary file with the correct `Content-Type` header. Save it to disk or process it as needed.

> [!NOTE]
> The webhook media URL is **temporary** (valid for ~5 minutes). Make sure to download the media soon after receiving the webhook. If the URL has expired, you can use the `Get Message by ID` endpoint to get the permanent `awsLink` from our CDN instead.

> [!TIP]
> **Choosing between this endpoint and `awsLink`:**
>
> - Use **Fetch Media** when you need the file **immediately** after receiving the webhook (within seconds).
> - Use **Get Message by ID** (`awsLink` field) when you're okay waiting a few seconds for our CDN-hosted permanent URL. The `awsLink` is a permanent link that never expires.

---

## Get Presigned URL for Upload

:::api
method: GET
endpoint: /v1/messages/presigned-url
title: Get Presigned URL for Upload
description: Get a temporary upload URL for a media file you want to send. Upload the file to `signedRequest` with an HTTP PUT, then use `url` as the media `url` when sending the message.

## Query Parameters

- file_name: string [required] - Name of the file with extension (e.g., `image.jpg`). A random prefix is added so names never collide.
- file_type: string [required] - MIME type of the file (e.g., `image/jpeg`). Must match the `Content-Type` you send with the upload.
- public: boolean - Optional. When `true`, `url` points at the storage host directly instead of the CDN.

## Response

```response
{
  "message": "Successfully created signed url!",
  "data": {
    "signedRequest": "https://s3.amazonaws.com/bucket/V1StGXR8_Z5jdHi6B-myTimage.jpg?X-Amz-Expires=3600&X-Amz-Signature=...",
    "url": "https://cdn.example.com/V1StGXR8_Z5jdHi6B-myTimage.jpg"
  }
}
```

:::

- `signedRequest` accepts a single `PUT` with the raw file bytes and a `Content-Type` header equal to `file_type`. It expires after **1 hour**.
- `url` is the permanent public address of the file once the upload finishes. Use it as `url` in a [media message](#media-message) or in a template header parameter.

| HTTP status | `errorMessage`                          | Cause                                 |
| ----------- | --------------------------------------- | ------------------------------------- |
| 400         | `File type and file name are required!` | `file_name` or `file_type` is missing |

### Upload and Send Example

```bash
# 1. Ask for an upload URL
curl "{{API_URL}}/v1/messages/presigned-url?file_name=product.jpg&file_type=image%2Fjpeg" \
  -H "Authorization: Bearer YOUR_API_KEY"

# 2. Upload the file to data.signedRequest (no Authorization header)
curl -X PUT "https://s3.amazonaws.com/bucket/V1StGXR8_Z5jdHi6B-myTproduct.jpg?X-Amz-Algorithm=..." \
  -H "Content-Type: image/jpeg" \
  --upload-file ./product.jpg

# 3. Send the message using data.url
curl -X POST "{{API_URL}}/v1/messages/send" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "clientWaNumber": "919876543210",
        "messageType": "media",
        "mediaType": "image",
        "url": "https://cdn.example.com/V1StGXR8_Z5jdHi6B-myTproduct.jpg",
        "name": "product.jpg",
        "mimeType": "image/jpeg",
        "caption": "Check out our new product!"
      }
    ]
  }'
```

---

## Typing indicator

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: POST
endpoint: /v1/business/typing-indicator
title: Send Typing Indicator
description: Mark an inbound message as read and show a "typing..." bubble to the contact while you prepare a reply. WhatsApp hides the indicator when your reply arrives, or after a short time.

## Body Parameters

- messageId: string [required] - `wamid` of the most recent message received from the contact. The indicator is shown in that conversation.
- typingIndicatorType: string - `text` (default), `image`, `video`, `audio`, or `document`. Any other value returns a 400.

```request
{
  "messageId": "wamid.HBgLOTE5ODc2NTQzMjEw...",
  "typingIndicatorType": "text"
}
```

## Response

```response
{
  "message": "Successfully sent typing indicator!"
}
```

:::

- The read receipt is sent together with the indicator, so the contact sees blue ticks and then the typing bubble.
- Use the `wamid` of a message received from the contact, and send it right before you call [Send Messages](#send-messages).

| HTTP status | `errorMessage`                                                              | Cause                                                                                                     |
| ----------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 400         | `Message ID is required`                                                    | `messageId` is missing or empty                                                                           |
| 400         | `Typing indicator type must be one of: text, image, video, audio, document` | Unsupported `typingIndicatorType`                                                                         |
| 400         | `Failed to send typing indicator!`                                          | WhatsApp rejected the request; `errorRaw` holds WhatsApp's error (for example, an unknown or outbound ID) |
| 403         | `API key does not have the required scope (business:write)`                 | The key was created with a per-resource scope. Use a Full access key                                      |

### Typing Indicator Example

```bash
curl -X POST "{{API_URL}}/v1/business/typing-indicator" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "wamid.HBgLOTE5ODc2NTQzMjEw...",
    "typingIndicatorType": "text"
  }'
```

---

## Message Status

Messages progress through these statuses:

| Status      | Description                                             | Visual            |
| ----------- | ------------------------------------------------------- | ----------------- |
| `waiting`   | Accepted by the platform, not yet confirmed by WhatsApp | -                 |
| `sent`      | Message sent to WhatsApp servers                        | Single grey tick  |
| `delivered` | Delivered to recipient's device                         | Double grey ticks |
| `read`      | Read by recipient                                       | Double blue ticks |
| `failed`    | Failed to send                                          | Error icon        |
| `received`  | Inbound message from the contact                        | -                 |

> [!TIP]
> Use webhooks to receive real-time status updates instead of polling the API.
