---
title: Campaigns
description: Create and manage campaigns
icon: Send
order: 6
---

# Campaigns API

Send bulk template message campaigns to thousands of contacts. Campaigns are processed in the background with full delivery tracking.

All endpoints on this page take an API key in the `Authorization: Bearer <API key>` header. `POST /v1/campaigns/send` needs the `campaigns:write` scope; the `GET` endpoints need `campaigns:read`. See [Authentication](/docs/api/authentication) for how scopes work.

| Method | Endpoint                           | Scope             | Purpose                                                 |
| ------ | ---------------------------------- | ----------------- | ------------------------------------------------------- |
| POST   | `/v1/campaigns/send`               | `campaigns:write` | Create a campaign and start sending                     |
| GET    | `/v1/campaigns`                    | `campaigns:read`  | List campaigns with their counts (paginated)            |
| GET    | `/v1/campaigns/get-one/:id`        | `campaigns:read`  | One campaign with up-to-date delivery counts            |
| GET    | `/v1/campaigns/:id`                | `campaigns:read`  | Per-recipient delivery status                           |
| GET    | `/v1/campaigns/download-stats/:id` | `campaigns:read`  | Per-recipient rows with contact names, ready for export |

> [!IMPORTANT]
> Campaigns can only use **approved templates**. Make sure your template is approved before creating a campaign.

---

:::api
method: POST
endpoint: /v1/campaigns/send
title: Send Campaign
description: Create and send a campaign immediately. The recipients are queued and sent in the background at your account's send rate.

## Body Parameters

- campaignName: string [required] - Campaign name for identification
- templateName: string [required] - Approved template name to use
- languageCode: string [required] - Template language code, for example `en` or `en_US`
- messages: array - Recipients with their template variables (see below). Required unless you send `finalPayloadFileUrl` instead
- finalPayloadFileUrl: string - HTTPS URL of an uploaded NDJSON file holding the recipients, one per line. Use this instead of `messages` for large campaigns
- recipientCount: number - Number of recipients in that file. Required with `finalPayloadFileUrl`
- campaignDesc: string - Campaign description
- templateContent: string - Template body text with its `{{n}}` placeholders. Optional: when given, it is used (with the placeholders filled from `variables`) as the text of the message stored in the conversation; otherwise the body is taken from the template itself
- templateHeader: string - Template header text with its `{{n}}` placeholders. Optional, same purpose as `templateContent` for a text header
- originalFileUrl: string - URL of the spreadsheet the recipients came from. Optional, stored on the campaign for your reference
- csvColumnConfig: object - Column mapping used when the recipients were imported from a spreadsheet in the dashboard. Optional, stored on the campaign for your reference
- source: string - Optional label for where the campaign originated. Stored and returned as `source`; defaults to `direct`

```request
{
  "campaignName": "Diwali Sale 2026",
  "campaignDesc": "Festival discount offer",
  "templateName": "promo_offer",
  "languageCode": "en",
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "variables": [
        {
          "type": "body",
          "parameters": [
            { "type": "text", "text": "John" },
            { "type": "text", "text": "20%" }
          ]
        }
      ]
    },
    {
      "clientWaNumber": "919876543211",
      "variables": [
        {
          "type": "body",
          "parameters": [
            { "type": "text", "text": "Jane" },
            { "type": "text", "text": "25%" }
          ]
        }
      ]
    }
  ]
}
```

## Response

```response
{
  "message": "Successfully started campaign - Diwali Sale 2026!",
  "data": {
    "campaign": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Diwali Sale 2026",
      "description": "Festival discount offer",
      "status": "running",
      "phoneNumberId": "104857612345678",
      "templateName": "promo_offer",
      "source": "direct",
      "statsTotal": 2,
      "statsWait": 2,
      "statsSent": 0,
      "statsDelivered": 0,
      "statsRead": 0,
      "statsResponded": 0,
      "statsClicked": 0,
      "statsClickedResponded": 0,
      "statsFailure": 0,
      "scheduleTime": "2026-08-03T10:00:00.000Z",
      "createdAt": "2026-08-03T10:00:00.000Z"
    },
    "messagesResponse": {
      "success": {
        "0": {
          "clientWaNumber": "919876543210",
          "message": {
            "clientWaNumber": "919876543210",
            "variables": [
              {
                "type": "body",
                "parameters": [
                  { "type": "text", "text": "John" },
                  { "type": "text", "text": "20%" }
                ]
              }
            ]
          }
        },
        "1": {
          "clientWaNumber": "919876543211",
          "message": {
            "clientWaNumber": "919876543211",
            "variables": [
              {
                "type": "body",
                "parameters": [
                  { "type": "text", "text": "Jane" },
                  { "type": "text", "text": "25%" }
                ]
              }
            ]
          }
        }
      },
      "fail": {}
    }
  }
}
```

:::

> [!NOTE]
> Supply **either** `messages` **or** `finalPayloadFileUrl` with `recipientCount`, not both. A request with neither returns `400` (`provide messages, or finalPayloadFileUrl with recipientCount`). Unknown fields in the body are rejected with `400`.

### Recipients

Each entry in `messages` is one recipient:

| Field            | Type   | Required | Description                                                                                                                                                                                                                                                          |
| ---------------- | ------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `clientWaNumber` | string | Yes      | Recipient's WhatsApp number with country code (`919876543210`). A `+` and spaces are accepted and stripped. Contacts who hide their number can be addressed by the user ID from their incoming message                                                               |
| `variables`      | array  | No       | Template components to fill in, in the same shape as a template message: objects with `type` (`header`, `body`, `button`, `limited_time_offer` or `carousel`) and `parameters`. See [Template Message](/docs/api/messages#template-message) for every component type |
| `integrations`   | array  | No       | Tracking IDs or custom data for third-party platforms and webhooks. See [Third-Party Integrations](#third-party-integrations)                                                                                                                                        |

The call returns once every recipient has been queued. `data.campaign` is the new campaign with all of its recipients still waiting (`statsWait` equals `statsTotal`); the counts move as messages are sent and WhatsApp reports delivery. Track them with `GET /v1/campaigns/get-one/:id` or through [webhooks](/docs/api/webhooks).

`data.messagesResponse.success` is keyed by each recipient's **position in your `messages` array** (`"0"`, `"1"`, ...) and echoes the recipient back. Because sending happens in the background, `fail` is empty here; per-recipient failures show up in `GET /v1/campaigns/:id` with a `failureReason`.

### Send Campaign Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/campaigns/send" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "campaignName": "Diwali Sale 2026",
    "templateName": "promo_offer",
    "languageCode": "en",
    "messages": [
      {
        "clientWaNumber": "919876543210",
        "variables": [
          {
            "type": "body",
            "parameters": [
              { "type": "text", "text": "John" },
              { "type": "text", "text": "20%" }
            ]
          }
        ]
      }
    ]
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/campaigns/send', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    campaignName: 'Diwali Sale 2026',
    templateName: 'promo_offer',
    languageCode: 'en',
    messages: [
      {
        clientWaNumber: '919876543210',
        variables: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: 'John' },
              { type: 'text', text: '20%' },
            ],
          },
        ],
      },
    ],
  }),
});

const { data } = await response.json();
console.log(data.campaign.id, data.campaign.status);
```

```python
import requests

response = requests.post(
    '{{API_URL}}/v1/campaigns/send',
    headers={
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json',
    },
    json={
        'campaignName': 'Diwali Sale 2026',
        'templateName': 'promo_offer',
        'languageCode': 'en',
        'messages': [
            {
                'clientWaNumber': '919876543210',
                'variables': [
                    {
                        'type': 'body',
                        'parameters': [
                            {'type': 'text', 'text': 'John'},
                            {'type': 'text', 'text': '20%'},
                        ],
                    }
                ],
            }
        ],
    },
)

campaign = response.json()['data']['campaign']
print(campaign['id'], campaign['status'])
```

:::

---

## Large campaigns

Sending a few lakh recipients inside `messages` makes the request body very
large. Upload the recipients as a file instead and send its URL: the request
stays a couple of KB whatever the campaign's size, and there is no recipient
count at which it stops working.

The file is **NDJSON**: one JSON object per line, each line exactly what a
`messages` entry would have been:

```
{"clientWaNumber":"919876543210","variables":[{"type":"body","parameters":[{"type":"text","text":"John"}]}]}
{"clientWaNumber":"919876543211","variables":[{"type":"body","parameters":[{"type":"text","text":"Jane"}]}]}
```

Upload it wherever the API can read it over HTTPS, then send:

```json
{
  "campaignName": "Diwali Sale 2026",
  "templateName": "promo_offer",
  "languageCode": "en",
  "finalPayloadFileUrl": "https://your-storage.example.com/diwali-recipients.ndjson",
  "recipientCount": 200000
}
```

`recipientCount` is a ceiling, not a hint: if the file turns out to hold more
recipients than you declared, only the first `recipientCount` of them are sent.
Fewer is fine; the campaign simply sends what the file holds. A missing or zero
`recipientCount` returns `400`.

Each line must be a single recipient and no line may exceed 1,000,000
characters. A file written as one big JSON array is a single line and will be
rejected with nothing sent; write one recipient per line instead. Lines that
are not valid JSON are skipped.

The response carries the `campaign` object as usual. `messagesResponse` comes
back empty (`{ "success": {}, "fail": {} }`) for this form: the recipients are
already in the file you supplied, so they are not echoed. Track delivery with
`GET /v1/campaigns/get-one/{campaignId}` as normal.

The call returns once every recipient in the file has been queued, so a very
large file keeps the request open a little longer. Sending then continues in the
background at your account's send rate, so `statsSent` climbs over the following
minutes rather than being final when the call returns.

---

:::api
method: GET
endpoint: /v1/campaigns
title: List All Campaigns
description: Get your campaigns, newest first, with their delivery counts. Paginated with a cursor.

## Query Parameters

- startDate: string - Only campaigns created on or after this day, `YYYY-MM-DD` (IST). Must be sent together with `endDate`
- endDate: string - Only campaigns created on or before this day (inclusive), `YYYY-MM-DD` (IST). Must be sent together with `startDate`
- limit: number - Campaigns per page, 1 to 10000 (default 1000)
- cursor: string - `nextCursor` from the previous page

## Response

```response
{
  "message": "Successfully retrieved campaign list",
  "data": {
    "campaigns": [
      {
        "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "name": "Weekend Flash Sale",
        "description": "",
        "status": "schedule",
        "phoneNumberId": "104857612345678",
        "templateName": "flash_sale",
        "source": "direct",
        "statsTotal": 5000,
        "statsWait": 5000,
        "statsSent": 0,
        "statsDelivered": 0,
        "statsRead": 0,
        "statsResponded": 0,
        "statsClicked": 0,
        "statsClickedResponded": 0,
        "statsFailure": 0,
        "scheduleTime": "2026-08-09T04:30:00.000Z",
        "createdAt": "2026-08-03T11:20:00.000Z"
      },
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Diwali Sale 2026",
        "description": "Festival discount offer",
        "status": "sent",
        "phoneNumberId": "104857612345678",
        "templateName": "promo_offer",
        "source": "direct",
        "statsTotal": 1000,
        "statsWait": 0,
        "statsSent": 950,
        "statsDelivered": 920,
        "statsRead": 450,
        "statsResponded": 61,
        "statsClicked": 88,
        "statsClickedResponded": 14,
        "statsFailure": 50,
        "scheduleTime": "2026-08-03T10:00:00.000Z",
        "createdAt": "2026-08-03T10:00:00.000Z"
      }
    ],
    "nextCursor": "MTc4NTc1MTIwMDAwMHw1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDA"
  }
}
```

:::

Campaigns are ordered by creation time, newest first. `nextCursor` is set when the page is full (it holds exactly `limit` campaigns); pass it back as `cursor` to fetch the next page. It is `null` on the last page.

Campaigns that are scheduled but have not started yet (status `schedule`, from the [Schedule API](/docs/api/schedule) or the dashboard) are listed at the top of the first page only, with every recipient counted in `statsWait` and their planned start in `scheduleTime`.

`startDate` and `endDate` filter on the day the campaign was created; both must be given, or neither. A date that is not `YYYY-MM-DD`, an `endDate` before `startDate`, or a `limit` outside 1 to 10000 returns `400`.

Campaigns created from a spreadsheet in the dashboard also carry `originalFileUrl` and `csvColumnConfig`. See [Campaign Fields](#campaign-fields) for what each count means.

### List All Campaigns Example

```bash
curl -X GET "{{API_URL}}/v1/campaigns?startDate=2026-08-01&endDate=2026-08-31&limit=100" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/campaigns/get-one/:id
title: Get Campaign
description: One campaign with its up-to-date delivery counts.

## Path Parameters

- id: string [required] - Campaign ID

## Response

```response
{
  "message": "Successfully retrieved campaign Stats.",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Diwali Sale 2026",
    "description": "Festival discount offer",
    "status": "running",
    "phoneNumberId": "104857612345678",
    "templateName": "promo_offer",
    "source": "direct",
    "statsTotal": 1000,
    "statsWait": 120,
    "statsSent": 850,
    "statsDelivered": 810,
    "statsRead": 390,
    "statsResponded": 44,
    "statsClicked": 71,
    "statsClickedResponded": 9,
    "statsFailure": 30,
    "scheduleTime": "2026-08-03T10:00:00.000Z",
    "createdAt": "2026-08-03T10:00:00.000Z"
  }
}
```

:::

This is the cheapest way to poll a campaign's progress: it returns just the counts, not the recipient list. Counts are refreshed from the latest message statuses on every call for campaigns sent in the last 90 days; older campaigns return their final stored counts, which no longer change.

The `id` of a scheduled campaign that has not started yet is accepted too and returns status `schedule` with every recipient in `statsWait`.

Campaigns created from a spreadsheet in the dashboard may also include `originalFileUrl`, `csvColumnConfig`, `columnMapper`, `finalPayloadFileUrl` and `payload`. Returns `404` when no campaign has that ID.

### Get Campaign Example

```bash
curl -X GET "{{API_URL}}/v1/campaigns/get-one/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/campaigns/:id
title: Get Campaign Recipient Status
description: The current delivery status of every recipient in a campaign.

## Path Parameters

- id: string [required] - Campaign ID

## Response

```response
{
  "message": "Successfully retrieved campaign Stats.",
  "data": {
    "messages": [
      {
        "status": "read",
        "clientWaNumber": "919876543210",
        "failureReason": null,
        "timestamp": "2026-08-03T10:00:04.000Z"
      },
      {
        "status": "failed",
        "clientWaNumber": "919876543211",
        "failureReason": "(#131026) Message undeliverable",
        "timestamp": "2026-08-03T10:00:05.000Z"
      }
    ]
  }
}
```

:::

One entry per recipient, oldest send first. `status` is the recipient's current message status (see [Message Statuses](#message-statuses)); `failureReason` carries WhatsApp's error text for failed messages and is `null` otherwise; `timestamp` is when the message was sent.

For a scheduled campaign that has not started yet, every recipient is returned with status `waiting` and no `failureReason` or `timestamp`.

The response holds every recipient, so for a campaign with hundreds of thousands of recipients it is large. Use `GET /v1/campaigns/get-one/:id` when you only need the counts. Returns `404` when no campaign has that ID.

### Get Campaign Recipient Status Example

```bash
curl -X GET "{{API_URL}}/v1/campaigns/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/campaigns/download-stats/:id
title: Download Campaign Stats
description: Per-recipient rows with the contact's name and reply, plus cumulative status counts, ready to write out as a spreadsheet.

## Path Parameters

- id: string [required] - Campaign ID

## Response

```response
{
  "message": "Successfully retrieved campaign Stats.",
  "data": {
    "statusCounts": {
      "waiting": 0,
      "failed": 1,
      "sent": 2,
      "delivered": 2,
      "read": 2,
      "responded": 1,
      "clicked": 0,
      "clicked_responded": 0,
      "total": 3
    },
    "campaignStats": [
      {
        "name": "Jane Doe",
        "clientWaNumber": "919876543211",
        "status": "failed",
        "respondedMsg": "",
        "failureReason": "(#131026) Message undeliverable",
        "timestamp": "2026-08-03T10:00:05.000Z"
      },
      {
        "name": "919876543212",
        "clientWaNumber": "919876543212",
        "status": "read",
        "respondedMsg": "",
        "failureReason": "",
        "timestamp": "2026-08-03T10:00:06.000Z"
      },
      {
        "name": "John Smith",
        "clientWaNumber": "919876543210",
        "status": "responded",
        "respondedMsg": "Yes, I am interested",
        "failureReason": "",
        "timestamp": "2026-08-03T10:00:04.000Z"
      }
    ]
  }
}
```

:::

The response is JSON; it is the data behind the dashboard's **Export** button, so each `campaignStats` entry maps to one spreadsheet row.

- `campaignStats` has one row per recipient, sorted by `status`. `name` is the contact's saved name, or the number when the contact has no name. `respondedMsg` is the contact's reply to the campaign message, and `failureReason` WhatsApp's error text; both are empty strings when not applicable.
- `statusCounts` is a cumulative funnel: a message that was read is counted under `sent`, `delivered` and `read`; a `clicked_responded` message under every step. `total` is the number of recipients.

Returns `404` when no campaign with that ID belongs to your business. Scheduled campaigns that have not started yet are not available here.

### Download Campaign Stats Example

```bash
curl -X GET "{{API_URL}}/v1/campaigns/download-stats/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Campaign Fields

Every endpoint that returns a campaign uses the same shape:

| Field                   | Type   | Description                                                                                             |
| ----------------------- | ------ | ------------------------------------------------------------------------------------------------------- |
| `id`                    | string | Campaign ID                                                                                             |
| `name`                  | string | Campaign name                                                                                           |
| `description`           | string | Campaign description (empty string when none)                                                           |
| `status`                | string | See [Campaign Status](#campaign-status)                                                                 |
| `phoneNumberId`         | string | WhatsApp phone number ID the campaign was sent from                                                     |
| `templateName`          | string | Template used                                                                                           |
| `source`                | string | Where the campaign originated: `direct` (default) or `integration`, or the label you passed in `source` |
| `statsTotal`            | number | Number of recipients                                                                                    |
| `statsWait`             | number | Recipients still queued, not yet handed to WhatsApp                                                     |
| `statsSent`             | number | Accepted by WhatsApp (includes every recipient further down the funnel)                                 |
| `statsDelivered`        | number | Delivered to the recipient's phone (includes read, responded and clicked)                               |
| `statsRead`             | number | Read by the recipient (includes responded and clicked)                                                  |
| `statsResponded`        | number | Recipients who replied (includes `statsClickedResponded`)                                               |
| `statsClicked`          | number | Recipients who tapped a tracked link in the message (includes `statsClickedResponded`)                  |
| `statsClickedResponded` | number | Recipients who both clicked and replied                                                                 |
| `statsFailure`          | number | Recipients whose message failed or expired                                                              |
| `scheduleTime`          | string | For a scheduled campaign, when it is due to start; otherwise the time sending began                     |
| `createdAt`             | string | When the campaign was created                                                                           |

---

## Campaign Status

| Status     | Description                     |
| ---------- | ------------------------------- |
| `draft`    | Saved but not sent              |
| `schedule` | Scheduled for future delivery   |
| `running`  | Currently sending messages      |
| `sent`     | All messages handed to WhatsApp |
| `paused`   | Sending is paused               |

---

## Message Statuses

Each recipient's message moves through these statuses. They are the values in `GET /v1/campaigns/:id` and `GET /v1/campaigns/download-stats/:id`.

| Status              | Description                                        |
| ------------------- | -------------------------------------------------- |
| `waiting`           | Queued, not yet handed to WhatsApp                 |
| `sent`              | Accepted by WhatsApp                               |
| `delivered`         | Delivered to the recipient's phone                 |
| `read`              | Read by the recipient                              |
| `responded`         | The recipient replied                              |
| `clicked`           | The recipient tapped a tracked link in the message |
| `clicked_responded` | The recipient both clicked and replied             |
| `failed`            | WhatsApp could not deliver it; see `failureReason` |
| `expired`           | Not delivered; counted with failed messages        |

---

## Third-Party Integrations

Track campaign performance in your analytics platforms, or attach your own data to each message, by including an `integrations` array on a recipient:

```json
{
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "variables": [...],
      "integrations": [
        { "name": "webEngage", "msgId": "unique-tracking-id" },
        { "name": "cleverTap", "msgId": "ct-123" },
        { "name": "moEngage", "msgId": "me-456" },
        { "name": "metaCustomFieldHook", "customField": { "order_id": "ORD-12345" } }
      ]
    }
  ]
}
```

| Platform              | Description                                                                                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `webEngage`           | WebEngage journey tracking                                                                                                                                                    |
| `cleverTap`           | CleverTap campaign engagement                                                                                                                                                 |
| `moEngage`            | MoEngage push tracking                                                                                                                                                        |
| `metaCustomFieldHook` | Your own key-value data, stored with the message and echoed in your webhooks. See [Sending Custom Data with Templates](/docs/api/messages#sending-custom-data-with-templates) |

`msgId` is the message's ID in that platform; one is generated for you when it is omitted. `customField` accepts an object or a string.

---

## Errors

| Status | When                                                                                                                                                                                                                                                                |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | Missing `campaignName`, `templateName` or `languageCode`; neither `messages` nor `finalPayloadFileUrl` given; `finalPayloadFileUrl` without a positive `recipientCount`; an invalid `clientWaNumber`; an unknown field in the body; an invalid list query parameter |
| 401    | Missing, invalid, expired or revoked API key                                                                                                                                                                                                                        |
| 403    | The API key does not have the required scope (`campaigns:write` to send, `campaigns:read` to read)                                                                                                                                                                  |
| 404    | No campaign with that ID, or (for `GET /v1/campaigns`) the business has no WhatsApp number connected                                                                                                                                                                |
| 503    | The send queue is temporarily unavailable. Retry after a few seconds. The campaign may already have been created before the failure, so check `GET /v1/campaigns` before resending to avoid messaging the same contacts twice                                       |

---

## Best Practices

> [!TIP]
> Follow these guidelines for successful campaigns:

- **Test first** - Send to a small group (10-20) before large campaigns
- **Personalize** - Use template variables for customer names, order IDs, etc.
- **Timing matters** - Schedule during business hours in recipient's timezone
- **Monitor delivery** - Watch for high failure rates which may indicate quality issues
- **Respect opt-outs** - Remove unsubscribed contacts before sending
