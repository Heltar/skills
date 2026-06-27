---
title: Campaigns
description: Create and manage campaigns
icon: Send
order: 6
---

# Campaigns API

Send bulk template message campaigns to thousands of contacts. Campaigns are processed in the background with full delivery tracking.

> [!IMPORTANT]
> Campaigns can only use **approved templates**. Make sure your template is approved before creating a campaign.

---

:::api
method: POST
endpoint: /v1/campaigns/send
title: Send Campaign
description: Create and send a campaign immediately. Messages are queued and sent in batches for optimal delivery.

## Body Parameters

- campaignName: string [required] - Campaign name for identification
- templateName: string [required] - Approved template name to use
- languageCode: string [required] - Template language code
- messages: array [required] - Array of recipients with personalized variables
- campaignDesc: string - Campaign description
- source: string - Campaign source (web, api, csv)

```request
{
  "campaignName": "Diwali Sale 2024",
  "campaignDesc": "Festival discount offer",
  "templateName": "promo_offer",
  "languageCode": "en",
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "variables": [
        { "type": "text", "text": "John" },
        { "type": "text", "text": "20%" }
      ]
    },
    {
      "clientWaNumber": "919876543211",
      "variables": [
        { "type": "text", "text": "Jane" },
        { "type": "text", "text": "25%" }
      ]
    }
  ],
  "source": "api"
}
```

## Response

```response
{
  "campaign": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Diwali Sale 2024",
    "status": "running",
    "templateName": "promo_offer",
    "statsTotal": 2,
    "statsSent": 2,
    "statsDelivered": 0,
    "statsRead": 0,
    "statsFailed": 0,
    "createdAt": "2024-01-15T10:00:00Z"
  },
  "messagesResponse": {
    "success": { "919876543210": {...}, "919876543211": {...} },
    "fail": {}
  }
}
```

:::

---

:::api
method: GET
endpoint: /v1/campaigns
title: List All Campaigns
description: Get all campaigns with their delivery statistics.

## Response

```response
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Diwali Sale 2024",
      "status": "sent",
      "templateName": "promo_offer",
      "statsTotal": 1000,
      "statsSent": 950,
      "statsDelivered": 920,
      "statsRead": 450,
      "statsFailed": 50,
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

:::

---

:::api
method: GET
endpoint: /v1/campaigns/:id
title: Get Campaign Stats
description: Get real-time delivery statistics for a campaign.

## Path Parameters

- id: string [required] - Campaign ID

## Response

```response
{
  "data": {
    "statsTotal": 1000,
    "statsSent": 950,
    "statsDelivered": 920,
    "statsRead": 450,
    "statsFailed": 50
  }
}
```

:::

---

:::api
method: GET
endpoint: /v1/campaigns/download-stats/:id
title: Download Campaign Stats
description: Download detailed campaign statistics as a CSV file for analysis.

## Path Parameters

- id: string [required] - Campaign ID

## Response

Returns a CSV file with per-recipient delivery status.
:::

---

## Campaign Status

| Status     | Description                   |
| ---------- | ----------------------------- |
| `draft`    | Saved but not sent            |
| `schedule` | Scheduled for future delivery |
| `running`  | Currently sending messages    |
| `sent`     | All messages sent             |

---

## Third-Party Integrations

Track campaign performance in your analytics platforms by including integration tracking IDs:

```json
{
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "variables": [...],
      "integrations": [
        { "name": "webEngage", "msgId": "unique-tracking-id" },
        { "name": "cleverTap", "msgId": "ct-123" },
        { "name": "moEngage", "msgId": "me-456" }
      ]
    }
  ]
}
```

| Platform    | Description                   |
| ----------- | ----------------------------- |
| `webEngage` | WebEngage journey tracking    |
| `cleverTap` | CleverTap campaign engagement |
| `moEngage`  | MoEngage push tracking        |

---

## Best Practices

> [!TIP]
> Follow these guidelines for successful campaigns:

- **Test first** - Send to a small group (10-20) before large campaigns
- **Personalize** - Use template variables for customer names, order IDs, etc.
- **Timing matters** - Schedule during business hours in recipient's timezone
- **Monitor delivery** - Watch for high failure rates which may indicate quality issues
- **Respect opt-outs** - Remove unsubscribed contacts before sending
