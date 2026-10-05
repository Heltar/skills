---
title: Receiving Media from Webhooks
description: How to download images, videos, documents, and audio files sent by customers
icon: FileText
order: 2
---

# Receiving Media from Webhooks

When a customer sends an image, video, document, or audio message, your webhook receives a notification with the media metadata. This guide covers how to download the actual media file.

---

## What You Receive in the Webhook

When a customer sends media, the webhook payload includes a media object with metadata:

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
                "type": "image",
                "image": {
                  "id": "MEDIA_ID",
                  "mime_type": "image/jpeg",
                  "sha256": "FghN0jxjw+skZm+...",
                  "caption": "Check this out"
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

**Media fields by type:**

| Type       | Fields                                                        |
| ---------- | ------------------------------------------------------------- |
| `image`    | `id`, `mime_type`, `sha256`, `caption` (optional)             |
| `video`    | `id`, `mime_type`, `sha256`, `caption` (optional)             |
| `audio`    | `id`, `mime_type`, `sha256`                                   |
| `document` | `id`, `mime_type`, `sha256`, `filename`, `caption` (optional) |
| `sticker`  | `id`, `mime_type`, `sha256`, `animated` (optional)            |

---

## How to Get the Media File

There are two approaches to download the actual file:

### Approach 1: Fetch by Message ID

Use the WhatsApp message ID (`wamid`) from the webhook to fetch the full message via the Heltar API. The response includes a permanent CDN link to the file.

```
GET {{API_URL}}/v1/messages?wamid=wamid.HBgLOTE5ODc...
```

:::code-group

```bash
curl -X GET '{{API_URL}}/v1/messages?wamid=wamid.HBgLOTE5ODc...' \
  -H 'Authorization: Bearer YOUR_API_KEY'
```

```javascript
const wamid = webhook.entry[0].changes[0].value.messages[0].id;

async function getMediaUrl(wamid, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = await fetch(
      `${API_URL}/v1/messages?wamid=${encodeURIComponent(wamid)}`,
      { headers: { Authorization: `Bearer ${apiKey}` } },
    );
    const data = await response.json();

    if (data.awsLink) {
      return data.awsLink; // Permanent CDN URL
    }

    // Media upload takes a few seconds, retry
    await new Promise(r => setTimeout(r, 5000));
  }
  throw new Error('Media not yet available');
}
```

```python
import time
import requests

def get_media_url(wamid, max_retries=3):
    for i in range(max_retries):
        response = requests.get(
            f"{API_URL}/v1/messages",
            params={"wamid": wamid},
            headers={"Authorization": f"Bearer {api_key}"},
        )
        data = response.json()

        if data.get("awsLink"):
            return data["awsLink"]  # Permanent CDN URL

        # Media upload takes a few seconds, retry
        time.sleep(5)

    raise Exception("Media not yet available")
```

:::

**Response:**

```json
{
  "wamid": "wamid.HBgLOTE5ODc...",
  "clientWaNumber": "919876543210",
  "status": "received",
  "timestamp": "2026-01-15T10:30:00.000Z",
  "type": "media",
  "name": "photo.jpg",
  "caption": "Check this out",
  "mimeType": "image/jpeg",
  "size": 58386,
  "sha256": "FghN0jxjw+skZm+...",
  "awsLink": "https://cdn.heltar.com/media/abc123.jpg",
  "dimensions": { "width": 1080, "height": 1920 }
}
```

The `awsLink` is a **permanent URL** that you can store, cache, or share.

> [!IMPORTANT]
> Media takes a few seconds to download and upload to our CDN after the webhook fires. If `awsLink` is empty, retry after 5 seconds. 2-3 retries at 5-second intervals is usually enough.

---

### Approach 2: Use the Temporary URL from the Webhook

Meta includes a temporary direct download URL in the webhook payload. You can use this URL with the fetch-media endpoint to download the file immediately:

```
GET {{API_URL}}/v1/messages/fetch-media?url=<encoded_url>
```

:::code-group

```bash
# URL-encode the media URL from the webhook
MEDIA_URL="https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=MEDIA_ID..."
curl -X GET "{{API_URL}}/v1/messages/fetch-media?url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$MEDIA_URL'))")" \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  --output downloaded_file.jpg
```

```javascript
const mediaUrl = webhook.entry[0].changes[0].value.messages[0].image.url;

const response = await fetch(
  `${API_URL}/v1/messages/fetch-media?url=${encodeURIComponent(mediaUrl)}`,
  { headers: { Authorization: `Bearer ${apiKey}` } },
);
const blob = await response.blob();
```

```python
import requests

media_url = webhook["entry"][0]["changes"][0]["value"]["messages"][0]["image"]["url"]

response = requests.get(
    f"{API_URL}/v1/messages/fetch-media",
    params={"url": media_url},
    headers={"Authorization": f"Bearer {api_key}"},
)
file_bytes = response.content
```

:::

This endpoint returns the **raw binary file** (not JSON) with the correct `Content-Type` header.

> [!WARNING]
> The temporary media URL from the webhook expires in approximately **5 minutes**. If you need the file after that window, use Approach 1 (fetch by message ID) instead.

---

## Comparison

| Approach                        | Pros                                                           | Cons                                           |
| ------------------------------- | -------------------------------------------------------------- | ---------------------------------------------- |
| **Fetch by Message ID**         | Permanent URL, cacheable, includes metadata (dimensions, size) | Needs 2-3 retries with 5s delay                |
| **Temporary URL (fetch-media)** | Instant file access, no waiting                                | URL expires in ~5 min, returns raw binary only |

---

## Complete Webhook Handler Example

:::code-group

```javascript
app.post('/webhooks/whatsapp', async (req, res) => {
  res.status(200).send('OK');

  const changes = req.body.entry?.[0]?.changes?.[0]?.value;
  if (!changes?.messages) return;

  for (const message of changes.messages) {
    const mediaType = ['image', 'video', 'audio', 'document', 'sticker'].find(
      t => message[t],
    );

    if (mediaType) {
      const media = message[mediaType];
      console.log(`Received ${mediaType} from ${message.from}`);
      console.log(`MIME: ${media.mime_type}`);

      // Get permanent CDN link (with retries)
      const cdnUrl = await getMediaUrl(message.id);
      console.log(`CDN URL: ${cdnUrl}`);

      // Store in your database
      await saveMedia({
        wamid: message.id,
        from: message.from,
        type: mediaType,
        url: cdnUrl,
        caption: media.caption,
        filename: media.filename,
      });
    }
  }
});
```

```python
@app.route('/webhooks/whatsapp', methods=['POST'])
def webhook():
    data = request.json

    changes = data.get("entry", [{}])[0].get("changes", [{}])[0].get("value", {})
    messages = changes.get("messages", [])

    for message in messages:
        media_type = next(
            (t for t in ["image", "video", "audio", "document", "sticker"]
             if t in message),
            None
        )

        if media_type:
            media = message[media_type]
            print(f"Received {media_type} from {message['from']}")

            # Get permanent CDN link (with retries)
            cdn_url = get_media_url(message["id"])

            # Store in your database
            save_media(
                wamid=message["id"],
                sender=message["from"],
                media_type=media_type,
                url=cdn_url,
                caption=media.get("caption"),
                filename=media.get("filename"),
            )

    return "OK", 200
```

:::
