---
title: Analytics
description: Engagement, conversation, template and cost analytics
icon: BarChart
order: 13
---

# Analytics API

Read the numbers behind the dashboard's analytics pages: daily engagement, per-template delivery funnels, message-level drill-downs, Meta's own account analytics, and a cost breakdown of what you send.

| Endpoint                                                 | What it returns                                                                 |
| -------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `GET /v1/analytics/daily-engagement`                     | Active contacts, new contacts and message volume per day                        |
| `GET /v1/templates/template-analytics-clickhouse`        | Delivery funnel per template per day, computed from your messages               |
| `GET /v1/templates/template-details/:templateName/:date` | Every message sent with one template on one day, with status and failure reason |
| `GET /v1/templates/conversation-analytics`               | Meta's conversation analytics for a business number                             |
| `GET /v1/templates/template-analytics`                   | Meta's sent / delivered / read / clicked counts for chosen templates            |
| `GET /v1/templates/pricing-analytics`                    | Meta's billable volume by country, category and pricing tier                    |
| `GET /v1/templates/cost-analytics`                       | Messaging and AI cost for a period, matching your bill                          |
| `GET /v1/templates/cost-analytics/templates`             | Estimated cost per template per day                                             |

`GET /v1/templates/analytics` (Meta's message analytics for a business number) is documented on the [Templates](/docs/api/templates) page.

---

## Authentication

All analytics endpoints require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

Endpoints under `/v1/templates/` need the `templates:read` scope. See [Authentication](/docs/api/authentication) for full setup instructions.

---

## Dates and Time Zones

Two date conventions are used on this page, depending on where the data comes from.

| Convention                                | Used by                                    | Format                                                                                                                        |
| ----------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `startDate` / `endDate`                   | Endpoints computed from your sent messages | `YYYY-MM-DD`. Both days are inclusive and are calendar days in Indian Standard Time (UTC+05:30)                               |
| `startDateTimestamp` / `endDateTimestamp` | Endpoints that read from Meta              | Unix time in **seconds**. The range is passed to Meta as-is, so Meta's own rules about bucket alignment and granularity apply |

Daily engagement and cost analytics validate the range: a `startDate` or `endDate` that is not `YYYY-MM-DD`, is not a real calendar date (for example `2026-02-30`), or an `endDate` before `startDate` returns `400`. The template analytics endpoints require both parameters (`400` when either is missing) and expect the same format.

---

## Engagement

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: GET
endpoint: /v1/analytics/daily-engagement
title: Daily Engagement
description: Active contacts, new contacts and message volume for every day in a date range.

## Query Parameters

- startDate: string [required] - First day of the range, `YYYY-MM-DD`
- endDate: string [required] - Last day of the range (inclusive), `YYYY-MM-DD`. At most 366 days after `startDate`

## Response

```response
{
  "message": "Daily engagement analytics retrieved successfully",
  "data": [
    {
      "date": "2026-08-03T00:00:00.000Z",
      "uniqueDailyActiveUsers": 412,
      "newActiveUsers": 37,
      "totalMessages": 5210,
      "campaignMessages": 3900
    },
    {
      "date": "2026-08-02T00:00:00.000Z",
      "uniqueDailyActiveUsers": 388,
      "newActiveUsers": 29,
      "totalMessages": 4870,
      "campaignMessages": 3600
    },
    {
      "date": "2026-08-01T00:00:00.000Z",
      "uniqueDailyActiveUsers": 0,
      "newActiveUsers": 0,
      "totalMessages": 0,
      "campaignMessages": 0
    }
  ]
}
```

:::

Every day in the range is present, most recent first, with zeros for days that had no activity. There is no maximum range.

| Field                    | Description                                                                                                                |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `date`                   | The calendar day (IST), returned as midnight UTC of that date                                                              |
| `uniqueDailyActiveUsers` | Distinct contacts who sent you at least one message that day                                                               |
| `newActiveUsers`         | Of those, contacts that were added to your contact list on that same day, so first-time contacts                           |
| `totalMessages`          | All inbound and outbound messages that day, excluding messages that failed or are still waiting to be sent                 |
| `campaignMessages`       | Template messages sent that day (campaigns and single template sends), excluding messages that failed or are still waiting |

### Daily Engagement Example

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/analytics/daily-engagement?startDate=2026-08-01&endDate=2026-08-03" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```javascript
const params = new URLSearchParams({
  startDate: '2026-08-01',
  endDate: '2026-08-03',
});

const response = await fetch(
  `{{API_URL}}/v1/analytics/daily-engagement?${params}`,
  { headers: { Authorization: 'Bearer YOUR_API_KEY' } },
);

const { data } = await response.json();
for (const day of data) {
  console.log(day.date, day.uniqueDailyActiveUsers, day.totalMessages);
}
```

```python
import requests

response = requests.get(
    '{{API_URL}}/v1/analytics/daily-engagement',
    headers={'Authorization': 'Bearer YOUR_API_KEY'},
    params={'startDate': '2026-08-01', 'endDate': '2026-08-03'},
)

for day in response.json()['data']:
    print(day['date'], day['uniqueDailyActiveUsers'], day['totalMessages'])
```

:::

---

## Template Analytics

These endpoints are computed from the messages sent through the platform for you, so they cover every template send that went through it (campaigns, API sends, chatbot sends) and include failure reasons and contact replies.

:::api
method: GET
endpoint: /v1/templates/template-analytics-clickhouse
title: Template Analytics by Day
description: Delivery funnel for every template, grouped by template, category and day.

## Query Parameters

- startDate: string [required] - First day of the range, `YYYY-MM-DD`
- endDate: string [required] - Last day of the range (inclusive), `YYYY-MM-DD`

## Response

```response
{
  "message": "Template analytics retrieved successfully",
  "data": [
    {
      "template_name": "festive_offer",
      "category": "MARKETING",
      "date": "2026-08-03",
      "totalCount": 3970,
      "waitingCount": 0,
      "sentCount": 3950,
      "deliveredCount": 3900,
      "readCount": 2410,
      "failedCount": 20,
      "respondedCount": 210,
      "clickedCount": 388,
      "clickedRespondedCount": 96
    },
    {
      "template_name": "order_confirmation",
      "category": "UTILITY",
      "date": "2026-08-03",
      "totalCount": 1200,
      "waitingCount": 10,
      "sentCount": 1170,
      "deliveredCount": 1120,
      "readCount": 840,
      "failedCount": 20,
      "respondedCount": 65,
      "clickedCount": 40,
      "clickedRespondedCount": 12
    }
  ]
}
```

:::

One row per template, category and day, ordered by day (most recent first) and then by template name. The category is the one that applied when each message was sent, so a template whose category changed mid-range is reported under the old category before the change and the new one after it. `category` is `null` when the category was not known at send time.

The counts form a funnel, so each step includes everything further down it:

| Field                   | Description                                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| `totalCount`            | Messages sent with this template that day                                                      |
| `waitingCount`          | Still queued, not yet handed to WhatsApp                                                       |
| `failedCount`           | Failed or expired                                                                              |
| `sentCount`             | Accepted by WhatsApp: `totalCount - waitingCount - failedCount`                                |
| `deliveredCount`        | Reached the recipient's phone (also counts read, responded and clicked messages)               |
| `readCount`             | Opened by the recipient (also counts responded and clicked messages)                           |
| `respondedCount`        | The contact replied to the message (includes messages that were both clicked and replied to)   |
| `clickedCount`          | The contact tapped a tracked link in the message (includes messages that were also replied to) |
| `clickedRespondedCount` | Both clicked and replied to                                                                    |

There is no maximum range; a multi-month range works, it just takes longer.

> [!NOTE]
> If this endpoint returns `503`, the analytics store is temporarily unavailable (or not enabled on a self-hosted deployment). Retry after a few seconds.

### Template Analytics by Day Example

```bash
curl -X GET "{{API_URL}}/v1/templates/template-analytics-clickhouse?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/templates/template-details/:templateName/:date
title: Template Message Details
description: Every message sent with one template on one day, with its current status, failure reason and the contact's reply.

## Path Parameters

- templateName: string [required] - Template name, URL-encoded
- date: string [required] - The day to inspect, `YYYY-MM-DD` (IST calendar day)

## Response

```response
{
  "message": "Template details retrieved successfully",
  "data": [
    {
      "wamid": "wamid.HBgLOTE5ODc2NTQzMjEwFQIAERgSNkY3QjA5RjQ4QzMxMkQ5NzY5AA==",
      "client_wa_number": "919876543210",
      "status": "responded",
      "failure_reason": null,
      "timestamp": "2026-08-03 10:15:42",
      "sent_by_name": "Priya",
      "response_text": "Yes, please confirm my order"
    },
    {
      "wamid": "wamid.HBgLOTE5ODc2NTQzMjExFQIAERgSMTVDQjQ0N0E5MEFCMzE5QjhCAA==",
      "client_wa_number": "919876543211",
      "status": "failed",
      "failure_reason": "(#131026) Message undeliverable",
      "timestamp": "2026-08-03 09:58:07",
      "sent_by_name": null,
      "response_text": null
    }
  ]
}
```

:::

Messages are returned most recent first. This is the drill-down behind a row of **Template Analytics by Day**: pass the same `template_name` and `date`.

| Field              | Description                                                                                                                    |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `wamid`            | WhatsApp message ID                                                                                                            |
| `client_wa_number` | Recipient's WhatsApp number (or user ID for contacts who hide their number)                                                    |
| `status`           | Current status: `waiting`, `sent`, `delivered`, `read`, `responded`, `clicked`, `clicked_responded`, `failed` or `expired`     |
| `failure_reason`   | WhatsApp's error text for failed messages, otherwise `null`                                                                    |
| `timestamp`        | When the message was sent                                                                                                      |
| `sent_by_name`     | Name of the team member who sent it, or `null` when no team member was attached to the send (for example the API or a chatbot) |
| `response_text`    | The contact's reply to this message, or `null` if they have not replied                                                        |

Returns `503` when the analytics store is temporarily unavailable.

### Template Message Details Example

```bash
curl -X GET "{{API_URL}}/v1/templates/template-details/order_confirmation/2026-08-03" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Meta Account Analytics

The next three endpoints read from Meta's analytics for your WhatsApp Business Account and return Meta's response unchanged inside `data`, so the field names are Meta's. They cover every message sent from the number, including messages sent through other tools connected to the same account, but they carry no per-recipient detail.

If Meta rejects the request (an unsupported range or granularity, a number that is not on your account, an expired connection), the API responds with `400` and the message `Failed to fetch ... analytics`; Meta's own error is included in `errorRaw`.

`GET /v1/templates/analytics` returns Meta's sent and delivered message counts per number and time bucket. It takes the same `startDateTimestamp`, `endDateTimestamp`, `granularity` and `wabaNumber` parameters as the conversation analytics endpoint below (with `granularity` values `HALF_HOUR`, `DAY` or `MONTH`) and is documented on the [Templates](/docs/api/templates) page.

:::api
method: GET
endpoint: /v1/templates/conversation-analytics
title: Conversation Analytics
description: Meta's conversation counts and cost for a business number, broken down by category, direction, type and country.

## Query Parameters

- startDateTimestamp: number [required] - Start of the range, Unix seconds
- endDateTimestamp: number [required] - End of the range, Unix seconds
- granularity: string [required] - Bucket size: `HALF_HOUR`, `DAILY` or `MONTHLY`
- wabaNumber: string [required] - The business phone number to report on, with country code, for example `919876543210`

## Response

```response
{
  "message": "Successfully fetched analytics!",
  "data": {
    "conversation_analytics": {
      "data": [
        {
          "data_points": [
            {
              "start": 1785715200,
              "end": 1785801600,
              "conversation": 1240,
              "cost": 967.2,
              "conversation_category": "MARKETING",
              "conversation_direction": "BUSINESS_INITIATED",
              "conversation_type": "REGULAR",
              "country": "IN",
              "phone_number": "919876543210"
            },
            {
              "start": 1785715200,
              "end": 1785801600,
              "conversation": 310,
              "cost": 0,
              "conversation_category": "SERVICE",
              "conversation_direction": "USER_INITIATED",
              "conversation_type": "FREE_TIER",
              "country": "IN",
              "phone_number": "919876543210"
            }
          ]
        }
      ]
    },
    "id": "102290129340398"
  }
}
```

:::

Each data point is one time bucket for one combination of conversation category, direction, type and country on the given number. `start` and `end` are Unix seconds.

### Conversation Analytics Example

```bash
curl -X GET "{{API_URL}}/v1/templates/conversation-analytics?startDateTimestamp=1785542400&endDateTimestamp=1785888000&granularity=DAILY&wabaNumber=919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/templates/template-analytics
title: Template Analytics (Meta)
description: Meta's daily sent, delivered, read and button-click counts for the templates you choose.

## Query Parameters

- startDateTimestamp: number [required] - Start of the range, Unix seconds
- endDateTimestamp: number [required] - End of the range, Unix seconds
- templateId: string [required] - Meta template ID, or several separated by commas. This is the `id` returned by `GET /v1/templates`
- limit: number - Data points per page (default 500)
- cursor: string - `nextCursor` from the previous page

## Response

```response
{
  "message": "Successfully fetched analytics!",
  "data": [
    {
      "template_id": "1234567890",
      "start": 1785715200,
      "end": 1785801600,
      "sent": 1200,
      "delivered": 1120,
      "read": 840,
      "clicked": [
        {
          "type": "quick_reply_button",
          "button_content": "Confirm order",
          "count": 40
        }
      ]
    },
    {
      "template_id": "1234567890",
      "start": 1785801600,
      "end": 1785888000,
      "sent": 980,
      "delivered": 931,
      "read": 702,
      "clicked": []
    }
  ],
  "nextCursor": null
}
```

:::

Buckets are always one day. `data` holds the data points directly, one per template per day; `clicked` lists each button with its tap count. When there are more data points than `limit`, `nextCursor` is set: pass it back as `cursor` to get the next page.

> [!NOTE]
> Meta only returns template analytics for accounts that have template analytics enabled in WhatsApp Manager, and only for the period since it was enabled.

### Template Analytics (Meta) Example

```bash
curl -X GET "{{API_URL}}/v1/templates/template-analytics?startDateTimestamp=1785542400&endDateTimestamp=1785888000&templateId=1234567890,1234567891" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/templates/pricing-analytics
title: Pricing Analytics
description: Meta's billable message volume (and cost, where Meta exposes it) by number, country, pricing category, pricing type and tier.

## Query Parameters

- startDateTimestamp: number [required] - Start of the range, Unix seconds
- endDateTimestamp: number [required] - End of the range, Unix seconds
- granularity: string [required] - Bucket size: `DAILY` or `MONTHLY`
- org: string - Set to `true` to report on every business in your organisation instead of the current one

## Response

```response
{
  "message": "Successfully fetched pricing analytics!",
  "data": {
    "pricing_analytics": {
      "data": [
        {
          "data_points": [
            {
              "start": 1785715200,
              "end": 1785801600,
              "phone_number": "919876543210",
              "country": "IN",
              "pricing_category": "MARKETING",
              "pricing_type": "REGULAR",
              "tier": "0:MAX",
              "volume": 3900,
              "cost": 3042
            },
            {
              "start": 1785715200,
              "end": 1785801600,
              "phone_number": "919876543210",
              "country": "IN",
              "pricing_category": "SERVICE",
              "pricing_type": "FREE_CUSTOMER_SERVICE",
              "volume": 310
            }
          ]
        }
      ]
    },
    "id": "102290129340398"
  }
}
```

:::

Only `pricing_type: "REGULAR"` rows are billable; other pricing types (such as `FREE_CUSTOMER_SERVICE` or `FREE_ENTRY_POINT`) are free volume. `tier` is present on billable rows only. `cost` is present only when Meta exposes it for your account (accounts billed directly by Meta); for accounts billed through a solution provider the response carries volume only.

With `org=true`, `data_points` contains the rows of every business in your organisation, each tagged with a `business` field holding the business name, and `data.errors` lists any business whose numbers Meta could not be queried for (`{ "business": "Acme Retail", "phone": "919876543210" }`). Org-wide reporting requires access to every business in the organisation and returns `403` otherwise.

> [!TIP]
> `MONTHLY` buckets are only returned for complete calendar months. For the current month, or any partial month, use `DAILY`.

This endpoint is only available on accounts with cost visibility enabled; it responds with `404` otherwise.

### Pricing Analytics Example

```bash
curl -X GET "{{API_URL}}/v1/templates/pricing-analytics?startDateTimestamp=1785542400&endDateTimestamp=1785888000&granularity=DAILY" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Cost Analytics

Cost analytics prices your messaging the same way your invoice does, so the totals here match your bill for the same period. Amounts are in INR. AI (chatbot model) usage is reported alongside it, priced in USD and converted at the rate shown in the response.

Both endpoints are only available on accounts with cost visibility enabled; they respond with `404` otherwise. Periods must start on or after **2026-07-01**; an earlier `startDate` returns `400`.

:::api
method: GET
endpoint: /v1/templates/cost-analytics
title: Cost Analytics
description: Day-wise billable volume and cost by country and category, AI usage, and the grand total for a period.

## Query Parameters

- startDate: string [required] - First day of the period, `YYYY-MM-DD` (not before `2026-07-01`)
- endDate: string [required] - Last day of the period (inclusive), `YYYY-MM-DD`
- scope: string - `business` (default) for the current business, or `org` for every business in your organisation

## Response

```response
{
  "message": "Cost analytics retrieved successfully",
  "data": {
    "volumeRows": [
      {
        "date": "2026-08-03",
        "countryCode": 91,
        "isoCode": "IN",
        "category": "MARKETING",
        "volume": 3900,
        "unitPrice": 0.78,
        "cost": 3042,
        "sentCount": 3950,
        "deliveredCount": 3900,
        "failedCount": 20
      },
      {
        "date": "2026-08-03",
        "countryCode": 91,
        "isoCode": "IN",
        "category": "UTILITY",
        "volume": 1200,
        "unitPrice": 0.115,
        "cost": 138,
        "sentCount": 1170,
        "deliveredCount": 1120,
        "failedCount": 20
      }
    ],
    "totalMessagingCost": 3180,
    "categoryBreakdown": {
      "MARKETING": { "messages": 3900, "cost": 3042 },
      "UTILITY": { "messages": 1200, "cost": 138 },
      "AUTHENTICATION": { "messages": 0, "cost": 0 }
    },
    "volumeSource": "standard",
    "aiUsage": {
      "rows": [
        {
          "model": "gemini-2.5-flash",
          "promptTokens": 182000,
          "completionTokens": 24000,
          "cachedTokens": 60000,
          "totalTokens": 206000,
          "totalCostUsd": 0.42
        }
      ],
      "dailyRows": [
        {
          "date": "2026-08-03",
          "model": "gemini-2.5-flash",
          "promptTokens": 182000,
          "completionTokens": 24000,
          "cachedTokens": 60000,
          "totalTokens": 206000,
          "totalCostUsd": 0.42
        }
      ],
      "totalTokens": 206000,
      "totalCostUsd": 0.42,
      "totalCostInr": 36.54,
      "usdToInrRate": 87
    },
    "grandTotalCost": 3216.54
  }
}
```

:::

**Messaging.** `volumeRows` has one row per day, country and category, most recent day first and highest cost first within a day. `volume`, `unitPrice` and `cost` are the billed figures. `sentCount`, `deliveredCount` and `failedCount` are the platform's own delivery counts for the same group (cumulative, so `sentCount` includes delivered messages); they come from a different ledger than the billed volume and can differ from it slightly. They are omitted when the platform has no record of the group, which happens when the number also sends through another tool. A row can also show counts with `volume: 0` for a day where nothing was billable, for example when every message failed.

`volumeSource` tells you how billable volume was counted for your account: `standard` counts messages from `sent` onwards, `conservative` counts messages from `delivered` onwards.

**AI usage.** `aiUsage.rows` is one row per model for the whole period and `aiUsage.dailyRows` the same split by day; `model` is `null` for usage recorded without a model name. `totalCostInr` is `totalCostUsd` converted at `usdToInrRate`.

**Total.** `grandTotalCost` is `totalMessagingCost + aiUsage.totalCostInr`, in INR.

**Organisation scope.** With `scope=org` every `volumeRows` entry carries `businessId` and `businessName`, `aiUsage` is summed across businesses, and the response gains a `businesses` array with one summary per business:

```json
{
  "businessId": 12345,
  "name": "Acme Retail",
  "phone": "+919876543210",
  "categoryBreakdown": {
    "MARKETING": { "messages": 3900, "cost": 3042 },
    "UTILITY": { "messages": 1200, "cost": 138 },
    "AUTHENTICATION": { "messages": 0, "cost": 0 }
  },
  "billableMessages": 5100,
  "totalMessagingCost": 3180,
  "aiCostInr": 36.54,
  "grandTotalCost": 3216.54
}
```

Org scope requires access to every business in the organisation and returns `403` otherwise.

### Cost Analytics Example

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/templates/cost-analytics?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```javascript
const params = new URLSearchParams({
  startDate: '2026-08-01',
  endDate: '2026-08-31',
});

const response = await fetch(
  `{{API_URL}}/v1/templates/cost-analytics?${params}`,
  { headers: { Authorization: 'Bearer YOUR_API_KEY' } },
);

const { data } = await response.json();
console.log('Messaging (INR):', data.totalMessagingCost);
console.log('Grand total (INR):', data.grandTotalCost);
```

```python
import requests

response = requests.get(
    '{{API_URL}}/v1/templates/cost-analytics',
    headers={'Authorization': 'Bearer YOUR_API_KEY'},
    params={'startDate': '2026-08-01', 'endDate': '2026-08-31'},
)

data = response.json()['data']
print('Messaging (INR):', data['totalMessagingCost'])
print('Grand total (INR):', data['grandTotalCost'])
```

:::

---

:::api
method: GET
endpoint: /v1/templates/cost-analytics/templates
title: Cost Analytics by Template
description: Estimated cost per template per day, with a per-country breakdown.

## Query Parameters

- startDate: string [required] - First day of the period, `YYYY-MM-DD` (not before `2026-07-01`)
- endDate: string [required] - Last day of the period (inclusive), `YYYY-MM-DD`

## Response

```response
{
  "message": "Template cost analytics retrieved successfully",
  "data": {
    "rows": [
      {
        "date": "2026-08-03",
        "templateName": "festive_offer",
        "category": "MARKETING",
        "sentCount": 3950,
        "deliveredCount": 3900,
        "failedCount": 20,
        "billableCount": 3950,
        "estimatedCost": 3081
      },
      {
        "date": "2026-08-03",
        "templateName": "order_confirmation",
        "category": "UTILITY",
        "sentCount": 1170,
        "deliveredCount": 1120,
        "failedCount": 20,
        "billableCount": 1170,
        "estimatedCost": 134.55
      }
    ],
    "countryRows": [
      {
        "date": "2026-08-03",
        "templateName": "festive_offer",
        "category": "MARKETING",
        "isoCode": "IN",
        "unitPrice": 0.78,
        "sentCount": 3950,
        "deliveredCount": 3900,
        "failedCount": 20,
        "billableCount": 3950,
        "estimatedCost": 3081
      },
      {
        "date": "2026-08-03",
        "templateName": "order_confirmation",
        "category": "UTILITY",
        "isoCode": "IN",
        "unitPrice": 0.115,
        "sentCount": 1170,
        "deliveredCount": 1120,
        "failedCount": 20,
        "billableCount": 1170,
        "estimatedCost": 134.55
      }
    ],
    "totalEstimatedCost": 3215.55
  }
}
```

:::

`rows` has one entry per template, category and day; `countryRows` splits the same groups by recipient country and adds the `unitPrice` that applied. `billableCount` is the number of messages your account's billing rule counts as billable, and `estimatedCost` is that count priced at the current rates.

> [!IMPORTANT]
> This view is an estimate built from the messages the platform sent. Meta does not report volume per template, so it cannot be reconciled with your invoice line by line; use `GET /v1/templates/cost-analytics` for the exact figures. Because each `countryRows` entry is rounded on its own, summing them can differ from the matching `rows` entry by a paisa or two.

This endpoint is per business only: `scope=org` returns `400`. It returns `503` when the analytics store is temporarily unavailable.

### Cost Analytics by Template Example

```bash
curl -X GET "{{API_URL}}/v1/templates/cost-analytics/templates?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Errors

| Status | When                                                                                                                                                                                                                                                  |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | A missing or malformed `startDate` / `endDate`, an `endDate` before `startDate`, a cost analytics period starting before `2026-07-01`, `scope=org` on the per-template cost endpoint, or a request that Meta rejected (Meta's error is in `errorRaw`) |
| 401    | Missing, invalid, expired or revoked API key                                                                                                                                                                                                          |
| 403    | The API key does not cover this endpoint (`templates:read` for `/v1/templates/*`, a Full access or Read-only key for `/v1/analytics/*`), or org-wide scope was requested without access to every business in the organisation                         |
| 404    | Pricing or cost analytics requested on an account without cost visibility enabled                                                                                                                                                                     |
| 429    | Rate limit reached: API keys may call the analytics endpoints 60 times per 15 minutes per business. Wait for the `Retry-After` header before retrying                                                                                                 |
| 503    | The analytics store is temporarily unavailable. Retry after a few seconds                                                                                                                                                                             |
