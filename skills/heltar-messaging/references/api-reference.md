---
title: Messages
description: Send and receive messages
icon: MessageSquare
order: 3
---

# Messages API

Send WhatsApp messages programmatically - text, media, templates, and interactive messages.

---

## Send Messages

:::api
method: POST
endpoint: /v1/messages/send
title: Send Messages
description: Send one or more WhatsApp messages in a single request. Supports text, media, template, interactive, location, and contact messages.

## Body Parameters

- messages: array [required] - Array of message objects to send
- campaignId: string - Optional campaign ID for tracking

```request
{
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "messageType": "text",
      "message": "Hello! How can I help you today?"
    }
  ]
}
```

## Response

```response
{
  "success": {
    "919876543210": {
      "clientWaNumber": "919876543210",
      "message": {
        "wamid": "wamid.HBgLOTE5ODc2NTQzMjEw",
        "status": "sent"
      }
    }
  },
  "fail": {}
}
```

:::

---

## Message Types

> [!TIP]
> All message types share common fields: `clientWaNumber` (required), `messageType` (required), and `contextId` (optional - for replies).

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
  "caption": "Check out our new product!"
}
```

| Field       | Type   | Required | Description                                         |
| ----------- | ------ | -------- | --------------------------------------------------- |
| `mediaType` | string | Yes      | `image`, `video`, `audio`, `document`, or `sticker` |
| `url`       | string | Yes      | Public HTTPS URL of media file                      |
| `name`      | string | Yes      | File name with extension                            |
| `mimeType`  | string | Yes      | MIME type (e.g., `image/jpeg`, `video/mp4`)         |
| `caption`   | string | No       | Caption text (not supported for audio/sticker)      |

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

| Field          | Type   | Required | Description                              |
| -------------- | ------ | -------- | ---------------------------------------- |
| `templateName` | string | Yes      | Template name (lowercase, underscores)   |
| `languageCode` | string | Yes      | Language code (e.g., `en`, `hi`, `es`)   |
| `variables`    | array  | No       | Array of component variables (see below) |

> [!NOTE]
> Our API uses `variables` which maps to Meta's `components` structure. Each variable object has a `type` and `parameters` array.

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

## Get Client Messages

:::api
method: GET
endpoint: /v1/messages/:clientWaNumber
title: Get Client Messages
description: Retrieve conversation history with a specific contact. Messages are returned in reverse chronological order (newest first).

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number of the contact

## Query Parameters

- limit: number - Maximum messages to return (default: 50, max: 100)
- offset: number - Pagination offset

## Response

```response
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "wamid": "wamid.HBgLOTE5ODc...",
      "type": "text",
      "content": "Hello!",
      "status": "delivered",
      "timestamp": "2024-01-15T10:30:00Z",
      "direction": "outbound"
    }
  ]
}
```

:::

---

## Get Message by ID

:::api
method: GET
endpoint: /v1/messages?wamid=xxx
title: Get Message by ID
description: Retrieve a single message by its WhatsApp message ID (`wamid`) or Heltar message ID (`hemid`). Useful for looking up specific messages — for example, when your webhook receives a media message and you want to fetch the saved version with the hosted media URL.

## Query Parameters

- wamid: string [required] - The message ID. Supports both formats:
  - **WhatsApp message ID** — e.g., `wamid.HBgLOTE5ODc...` (assigned by WhatsApp when the message is sent/received)
  - **Heltar message ID** — e.g., `hemid.MTIzOjkx...` (assigned by Heltar for async/queued messages before WhatsApp assigns a wamid)

## Response

For a **media message** (image, video, document, audio, sticker):

```response
{
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
```

For a **text message**:

```response
{
  "wamid": "wamid.HBgLOTE5ODc...",
  "hemid": null,
  "clientWaNumber": "919876543210",
  "status": "delivered",
  "timestamp": "2024-01-15T10:30:00Z",
  "type": "text",
  "body": "Hello! How can I help you?"
}
```

:::

> [!WARNING]
> **Why you might get a 404 for media messages:** When a customer sends a media message (image, document, video, etc.), Heltar forwards the webhook to your endpoint **immediately**. However, downloading the media from WhatsApp and uploading it to our CDN takes a few seconds. So if you call this endpoint right after receiving the webhook, you may get a **404 Not Found** because the message hasn't been saved yet, or the `awsLink` field may be empty while the upload is still in progress.

> [!TIP]
> **Option 1 — Instant access (recommended):** Use `GET /v1/messages/fetch-media?url=<encoded_url>` to download the file directly from WhatsApp. The webhook already contains the media URL (see the full webhook example below in the Fetch Media section). No waiting needed.

> [!INFO]
> **Option 2 — Permanent public URL:** Retry this endpoint after 3-5 seconds. Once the media has been processed, the `awsLink` field will contain a permanent CDN URL that never expires — useful for storing or sharing the link.

---

## Fetch Media from WhatsApp

:::api
method: GET
endpoint: /v1/messages/fetch-media?url=xxx
title: Fetch Media from WhatsApp
description: Download a media file directly from WhatsApp's servers. Use this when you receive a media message via webhook and need the file immediately, without waiting for it to be processed and uploaded to our CDN.

## When to use this

When WhatsApp sends a media message webhook, the payload includes a temporary media URL like:

```
https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=1428354048768552&source=webhook&ext=...
```

This URL **requires WhatsApp authentication** to access — you cannot download it directly. This endpoint acts as a proxy: you pass the URL as a query parameter, and we fetch the file using your business's WhatsApp access token.

## Query Parameters

- url: string [required] - The media URL from the webhook payload, **URL-encoded** using `encodeURIComponent()`. This is the `url` field inside the media object (e.g., `message.image.url`, `message.document.url`, etc.)

```request
GET /v1/messages/fetch-media?url=https%3A%2F%2Flookaside.fbsbx.com%2Fwhatsapp_business%2Fattachments%2F%3Fmid%3DMEDIA_ID%26source%3Dwebhook%26ext%3DEXPIRY%26hash%3DHASH_VALUE
```

## Response

The response is the **raw binary file** with the appropriate `Content-Type` header (e.g., `image/jpeg`, `application/pdf`, `video/mp4`). This is **not a JSON response** — it returns the file directly.

:::

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
  `/v1/messages/fetch-media?url=${encodeURIComponent(mediaUrl)}`,
  { headers: { Authorization: 'Bearer <your_jwt_token>' } },
);
```

```
// cURL example
GET /v1/messages/fetch-media?url=https%3A%2F%2Flookaside.fbsbx.com%2Fwhatsapp_business%2Fattachments%2F%3Fmid%3DMEDIA_ID%26source%3Dwebhook%26ext%3DEXPIRY%26hash%3DHASH_VALUE
Authorization: Bearer <your_jwt_token>
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
description: Get a presigned S3 URL for uploading media files. Use this URL to upload your file, then use the fileUrl to send the media message.

## Query Parameters

- fileName: string [required] - Name of the file with extension (e.g., image.jpg)
- contentType: string [required] - MIME type of the file (e.g., image/jpeg)

## Response

```response
{
  "presignedUrl": "https://s3.amazonaws.com/bucket/abc123?X-Amz-Algorithm=...",
  "fileUrl": "https://cdn.example.com/media/abc123.jpg"
}
```

:::

---

## Message Status

Messages progress through these statuses:

| Status      | Description                      | Visual            |
| ----------- | -------------------------------- | ----------------- |
| `sent`      | Message sent to WhatsApp servers | Single grey tick  |
| `delivered` | Delivered to recipient's device  | Double grey ticks |
| `read`      | Read by recipient                | Double blue ticks |
| `failed`    | Failed to send                   | Error icon        |

> [!TIP]
> Use webhooks to receive real-time status updates instead of polling the API.
