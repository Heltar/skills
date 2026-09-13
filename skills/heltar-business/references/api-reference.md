---
title: Business
description: Read your business profile and configure account-level settings
icon: Building2
order: 12
---

# Business API

Use the Business API to check the health of your WhatsApp Business account, manage opt-in and opt-out rules for your contacts, read your business details, and configure account-level settings such as the WhatsApp profile, commerce settings, link tracking, data localization and messaging behaviour.

The two most used endpoints are at the top of this page: [Account Status](#account-status) and [Opt-in and Opt-out Rules](#opt-in-and-opt-out-rules).

---

## Authentication

All endpoints on this page require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

See [Authentication](/docs/api/authentication) for full setup instructions.

> [!NOTE]
> The `/v1/business/*` endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests). The `POST /v1/journeys/events` endpoint at the end of this page is different: it is covered by the `journeys` resource in the scope picker and needs the `journeys:write` scope.

---

## Account Status

Your WhatsApp Business account has a health state maintained by Meta: whether the number can send messages, its quality rating, its messaging limit tier, whether the display name is approved, whether business verification is complete, and so on. This endpoint reads that state live from Meta and returns it in one response.

:::api
method: GET
endpoint: /v1/business/account-status
title: Get Account Status
description: Read the live health of your WhatsApp Business account from Meta. Pass the fields you want in `fields`.

## Query Parameters

- fields: string [required] - Comma-separated list of fields to read (see the field reference below). If omitted, the response `data` is empty.
- isDetailed: boolean - When `true`, `health_status.entities` includes every entity Meta reports (phone number, WhatsApp Business Account, business and app). Default `false`, which keeps only the phone-number entity.
- scope: string - Set to `org` to get the status of every business in your organisation as an array instead of a single object.

## Response

```response
{
  "message": "Successfully fetch meta acount health status!",
  "data": {
    "id": "106540352242922",
    "display_phone_number": "+91 98765 43210",
    "verified_name": "Acme Retail",
    "status": "CONNECTED",
    "quality_rating": "GREEN",
    "throughput": {
      "level": "STANDARD"
    },
    "whatsapp_business_manager_messaging_limit": "TIER_10K",
    "health_status": {
      "can_send_message": "AVAILABLE",
      "entities": [
        {
          "entity_type": "PHONE_NUMBER",
          "id": "106540352242922",
          "can_send_message": "AVAILABLE"
        }
      ]
    },
    "account_mode": "LIVE",
    "code_verification_status": "VERIFIED",
    "name_status": "APPROVED",
    "new_display_name": null,
    "new_name_status": null,
    "is_official_business_account": false,
    "is_on_biz_app": false,
    "is_pin_enabled": true,
    "is_preverified_number": false,
    "last_onboarded_time": "2025-01-10T08:30:00+0000",
    "search_visibility": "VISIBLE",
    "eligibility_for_api_business_global_search": "ELIGIBLE",
    "business_verification_status": "verified",
    "marketing_messages_lite_api_status": "ONBOARDED"
  }
}
```

:::

### Get Account Status Example

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/business/account-status?fields=status,quality_rating,throughput,health_status,whatsapp_business_manager_messaging_limit,display_phone_number,verified_name,name_status,business_verification_status" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```javascript
const fields = [
  'status',
  'quality_rating',
  'throughput',
  'health_status',
  'whatsapp_business_manager_messaging_limit',
  'display_phone_number',
  'verified_name',
  'name_status',
  'business_verification_status',
].join(',');

const response = await fetch(
  `{{API_URL}}/v1/business/account-status?fields=${fields}`,
  { headers: { Authorization: 'Bearer YOUR_API_KEY' } },
);
const { data } = await response.json();

if (data.health_status?.can_send_message !== 'AVAILABLE') {
  console.warn('Sending is limited or blocked', data.health_status);
}
```

```python
import requests

fields = ",".join([
    "status",
    "quality_rating",
    "throughput",
    "health_status",
    "whatsapp_business_manager_messaging_limit",
    "display_phone_number",
    "verified_name",
    "name_status",
    "business_verification_status",
])

response = requests.get(
    f"{{API_URL}}/v1/business/account-status",
    params={"fields": fields},
    headers={"Authorization": "Bearer YOUR_API_KEY"},
)
data = response.json()["data"]

if data.get("health_status", {}).get("can_send_message") != "AVAILABLE":
    print("Sending is limited or blocked", data.get("health_status"))
```

:::

### Fields you can request

Every name you pass in `fields` is fetched from Meta and returned under the same key. Most fields belong to your phone number; a few belong to the WhatsApp Business Account (WABA). You can mix them freely in one request.

**Phone number fields**

| Field                                        | Type    | What it tells you                                                                                                                                                                               |
| -------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                                         | string  | Meta's ID for your business phone number.                                                                                                                                                       |
| `display_phone_number`                       | string  | Your number as shown to customers, e.g. `+91 98765 43210`.                                                                                                                                      |
| `verified_name`                              | string  | The display name currently approved for the number.                                                                                                                                             |
| `status`                                     | string  | Connection state of the number: `CONNECTED`, `DISCONNECTED`, `FLAGGED`, `RESTRICTED`, `PENDING`, `RATE_LIMITED`, `MIGRATED`, `BANNED`, `DELETED` or `UNKNOWN`.                                  |
| `quality_rating`                             | string  | Meta's quality rating for the number: `GREEN` (high), `YELLOW` (medium), `RED` (low) or `UNKNOWN`. A low rating can reduce your messaging limit.                                                |
| `throughput`                                 | object  | Contains `level`, one of `STANDARD`, `HIGH` or `NOT_APPLICABLE`. How many messages per second the number can send.                                                                              |
| `whatsapp_business_manager_messaging_limit`  | string  | Current messaging limit tier, i.e. how many unique customers you can start marketing conversations with in a rolling 24-hour window, e.g. `TIER_1K`, `TIER_10K`, `TIER_100K`, `TIER_UNLIMITED`. |
| `health_status`                              | object  | The most useful field for monitoring. See [Health status](#health-status) below.                                                                                                                |
| `account_mode`                               | string  | `LIVE` or `SANDBOX`.                                                                                                                                                                            |
| `code_verification_status`                   | string  | Whether the number completed OTP verification: `VERIFIED`, `NOT_VERIFIED` or `EXPIRED`.                                                                                                         |
| `name_status`                                | string  | Review state of the display name: `APPROVED`, `AVAILABLE_WITHOUT_REVIEW`, `PENDING_REVIEW`, `DECLINED`, `EXPIRED` or `NONE`.                                                                    |
| `new_display_name`                           | string  | A display name change that is waiting for review, if any.                                                                                                                                       |
| `new_name_status`                            | string  | Review state of `new_display_name`.                                                                                                                                                             |
| `is_official_business_account`               | boolean | `true` when the number has the green Official Business Account badge.                                                                                                                           |
| `official_business_account`                  | object  | Details of the official business account application, when there is one.                                                                                                                        |
| `is_on_biz_app`                              | boolean | `true` when the number is also used in the WhatsApp Business app (coexistence).                                                                                                                 |
| `is_pin_enabled`                             | boolean | Whether two-step verification (registration PIN) is enabled.                                                                                                                                    |
| `is_preverified_number`                      | boolean | Whether the number was pre-verified before being added.                                                                                                                                         |
| `last_onboarded_time`                        | string  | When the number was last registered with the Cloud API.                                                                                                                                         |
| `search_visibility`                          | string  | Whether the business can be found in WhatsApp search, e.g. `VISIBLE`.                                                                                                                           |
| `eligibility_for_api_business_global_search` | string  | Whether the number is eligible to appear in global business search.                                                                                                                             |
| `conversational_automation`                  | object  | Configured ice breakers, commands and welcome-message setting.                                                                                                                                  |

**WhatsApp Business Account fields**

| Field                                | Type   | What it tells you                                                                                                                              |
| ------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `business_verification_status`       | string | Meta business verification state, e.g. `verified`, `not_verified`, `pending_submission`, `pending_need_more_info`, `rejected`.                 |
| `marketing_messages_lite_api_status` | string | Whether the account is onboarded to Marketing Messages Lite, e.g. `ONBOARDED`, `ELIGIBLE`, `INELIGIBLE`.                                       |
| `subscribed_apps`                    | array  | Apps subscribed to receive webhooks for this account. Each entry contains `whatsapp_business_api_data` with the app `id`, `name` and `link`.   |
| `phone_numbers`                      | array  | Every phone number on the account with its own `id`, `display_phone_number`, `verified_name`, `quality_rating` and `code_verification_status`. |
| `solutions`                          | array  | Multi-partner solutions the account is part of, if any.                                                                                        |
| `payment_configurations`             | array  | Payment configurations set up on the account (WhatsApp Pay).                                                                                   |
| `product_catalogs`                   | array  | Product catalogs connected to the account.                                                                                                     |

The values above are Meta's own and are returned exactly as Meta reports them. Meta may add new values over time; treat unknown values as "check the dashboard" rather than failing hard.

### Health status

`health_status` is the field to poll when you want to know "can I send right now?".

```json
{
  "health_status": {
    "can_send_message": "LIMITED",
    "entities": [
      {
        "entity_type": "PHONE_NUMBER",
        "id": "106540352242922",
        "can_send_message": "LIMITED",
        "errors": [
          {
            "error_code": 141000,
            "error_description": "The phone number's messaging limit has been reached.",
            "possible_solution": "Wait for the 24-hour window to reset or raise your quality rating."
          }
        ]
      }
    ]
  }
}
```

- `can_send_message` at the top is the overall verdict: `AVAILABLE` (all good), `LIMITED` (you can send, but with restrictions) or `BLOCKED` (you cannot send).
- `entities[]` explains why. Each entity carries its own `can_send_message` and, when it is not `AVAILABLE`, an `errors[]` array with Meta's `error_code`, `error_description` and `possible_solution`.
- By default only the `PHONE_NUMBER` entity is returned. Pass `isDetailed=true` to also receive the `WABA`, `BUSINESS` and `APP` entities, which is useful when the phone number itself is fine but the account or app is restricted.

### Partial results

Each group of fields (phone number, WABA, and each WABA sub-resource) is fetched from Meta separately. If one of them fails, the fields that did load are still returned and the failures are listed in `data.partialErrors`:

```json
{
  "message": "Successfully fetch meta acount health status!",
  "data": {
    "status": "CONNECTED",
    "quality_rating": "GREEN",
    "partialErrors": [
      {
        "source": "waba_product_catalogs",
        "error": {
          "error": {
            "message": "(#100) Missing permission",
            "type": "OAuthException",
            "code": 100
          }
        }
      }
    ]
  }
}
```

`source` is `phone_number`, `waba`, or `waba_<field>` for a sub-resource such as `waba_subscribed_apps`. Only when nothing at all could be fetched does the request fail with a `400`.

### Organisation-wide status

If your organisation has several businesses (phone numbers), pass `scope=org` to get all of them in one call. With an API key, every business in the organisation is included. The response `data` becomes an array sorted by business name, and each entry is the single-business shape stamped with `business_id` and `business_name`:

```bash
curl -X GET "{{API_URL}}/v1/business/account-status?scope=org&fields=status,quality_rating,throughput,whatsapp_business_manager_messaging_limit,display_phone_number,verified_name,health_status" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json
{
  "message": "Successfully fetch meta acount health status!",
  "data": [
    {
      "business_id": 12345,
      "business_name": "Acme Retail",
      "status": "CONNECTED",
      "quality_rating": "GREEN",
      "throughput": { "level": "STANDARD" },
      "whatsapp_business_manager_messaging_limit": "TIER_10K",
      "display_phone_number": "+91 98765 43210",
      "verified_name": "Acme Retail",
      "health_status": { "can_send_message": "AVAILABLE", "entities": [] }
    },
    {
      "business_id": 12346,
      "business_name": "Acme Support",
      "error": "Access token is missing on business profile."
    }
  ]
}
```

A business whose fetch failed entirely is returned as `{ business_id, business_name, error }` so one broken account never hides the others. Each business is given up to 15 seconds to answer.

### Account Status Errors

| Status | Message                                                      | When                                                                                    |
| ------ | ------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| 400    | `Failed to fetch meta acount health status!`                 | Every requested field group failed. `errorRaw` carries the per-source errors from Meta. |
| 400    | `Business has no orgId`                                      | `scope=org` was requested but the business is not part of an organisation.              |
| 403    | `Org-wide account status is not available for this session.` | `scope=org` is not allowed for the session type making the request.                     |

---

## Opt-in and Opt-out Rules

Opt rules let your contacts unsubscribe from (and re-subscribe to) your messages by simply replying to you on WhatsApp. You define keyword rules once; from then on every inbound WhatsApp message from a contact is checked against them automatically.

Every contact starts as **opted in**. When an opted-in contact sends a message that matches your **opt-out rules**, the contact is marked opted out and your template sends to them are skipped. When an opted-out contact sends a message that matches your **opt-in rules**, they are marked opted in again. The current state is visible as `optedIn` on the [Contacts API](/docs/api/contacts).

:::api
method: PUT
endpoint: /v1/business/opt-rules
title: Set Opt-in and Opt-out Rules
description: Replace the opt-out rules, opt-in rules and optional confirmation template for your business. The whole set is replaced on every call, so always send the complete configuration.

## Body Parameters

- optOutRules: array [required] - Rules that move an opted-in contact to opted out. Each rule is `{ "condition", "value", "nextIs" }` (see below). Pass `[]` to disable keyword opt-out.
- optInRules: array [required] - Rules that move an opted-out contact back to opted in. Same shape as `optOutRules`. Pass `[]` to disable keyword opt-in.
- templatePayload: object - Optional confirmation sent to a contact right after they opt out: `{ "templateName": "...", "languageCode": "..." }`. Omit to send nothing.

```request
{
  "optOutRules": [
    { "condition": "isEqualTo", "value": "STOP", "nextIs": "OR" },
    { "condition": "isEqualTo", "value": "UNSUBSCRIBE", "nextIs": "OR" },
    { "condition": "contains", "value": "remove me", "nextIs": "OR" }
  ],
  "optInRules": [
    { "condition": "isEqualTo", "value": "START", "nextIs": "OR" },
    { "condition": "isEqualTo", "value": "SUBSCRIBE", "nextIs": "OR" }
  ],
  "templatePayload": {
    "templateName": "opt_out_confirmation",
    "languageCode": "en"
  }
}
```

## Response

```response
{
  "message": "Successfully updated opt in opt out rules!"
}
```

:::

### Set Opt Rules Example

:::code-group

```curl
curl -X PUT "{{API_URL}}/v1/business/opt-rules" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "optOutRules": [
      { "condition": "isEqualTo", "value": "STOP", "nextIs": "OR" },
      { "condition": "isEqualTo", "value": "UNSUBSCRIBE", "nextIs": "OR" },
      { "condition": "contains", "value": "remove me", "nextIs": "OR" }
    ],
    "optInRules": [
      { "condition": "isEqualTo", "value": "START", "nextIs": "OR" },
      { "condition": "isEqualTo", "value": "SUBSCRIBE", "nextIs": "OR" }
    ],
    "templatePayload": {
      "templateName": "opt_out_confirmation",
      "languageCode": "en"
    }
  }'
```

```javascript
await fetch('{{API_URL}}/v1/business/opt-rules', {
  method: 'PUT',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    optOutRules: [
      { condition: 'isEqualTo', value: 'STOP', nextIs: 'OR' },
      { condition: 'isEqualTo', value: 'UNSUBSCRIBE', nextIs: 'OR' },
      { condition: 'contains', value: 'remove me', nextIs: 'OR' },
    ],
    optInRules: [
      { condition: 'isEqualTo', value: 'START', nextIs: 'OR' },
      { condition: 'isEqualTo', value: 'SUBSCRIBE', nextIs: 'OR' },
    ],
    templatePayload: {
      templateName: 'opt_out_confirmation',
      languageCode: 'en',
    },
  }),
});
```

```python
import requests

requests.put(
    "{{API_URL}}/v1/business/opt-rules",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={
        "optOutRules": [
            {"condition": "isEqualTo", "value": "STOP", "nextIs": "OR"},
            {"condition": "isEqualTo", "value": "UNSUBSCRIBE", "nextIs": "OR"},
            {"condition": "contains", "value": "remove me", "nextIs": "OR"},
        ],
        "optInRules": [
            {"condition": "isEqualTo", "value": "START", "nextIs": "OR"},
            {"condition": "isEqualTo", "value": "SUBSCRIBE", "nextIs": "OR"},
        ],
        "templatePayload": {
            "templateName": "opt_out_confirmation",
            "languageCode": "en",
        },
    },
)
```

:::

### Rule format

Each rule has three keys, all required:

| Key         | Type   | Allowed values                                    | Meaning                                                                              |
| ----------- | ------ | ------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `condition` | string | `isEqualTo`, `contains`, `startsWith`, `endsWith` | How the message text is compared with `value`.                                       |
| `value`     | string | Any non-empty text                                | The keyword or phrase to look for.                                                   |
| `nextIs`    | string | `AND`, `OR`                                       | How this rule's result is combined with the **next** rule. Ignored on the last rule. |

### How rules are evaluated

1. **Which text is checked.** For a text message it is the message body. For an image, video or document it is the caption. For a button or list reply it is the text of the option the contact tapped. Messages with no text (media without a caption, locations, contacts, reactions, stickers) are never evaluated.
2. **Which rule set is checked.** Only one set applies to a given message. If the contact is currently opted in, only `optOutRules` are evaluated. If the contact is currently opted out, only `optInRules` are evaluated. An opted-in contact sending "START" changes nothing, and an opted-out contact sending "STOP" changes nothing.
3. **Matching is case-insensitive and ignores surrounding whitespace.** Both the message text and every rule `value` are trimmed and lower-cased before comparison, so `STOP`, `stop` and `Stop` are the same. Punctuation is not stripped: with `isEqualTo` `STOP`, the reply `STOP.` does not match (use `startsWith` or `contains` if you want that).
4. **Rules are chained left to right with `nextIs`.** The first rule's result is the starting value. Each following rule is combined with the running result using the `nextIs` of the rule **before** it: `AND` requires both, `OR` requires either. There is no precedence between `AND` and `OR`; evaluation is strictly in order, like `((rule1 op1 rule2) op2 rule3)`.
5. **The message is the trigger.** If the final result is `true`, the contact's `optedIn` flag flips. Nothing else in the message is changed; it still appears in the inbox and still reaches your webhooks and chatbot as usual.

For the common case, keep every `nextIs` as `OR`: the contact opts out when the message matches **any** keyword. Use `AND` only when you need two conditions on the same message, for example `startsWith "stop"` AND `contains "marketing"` to catch "stop sending marketing" but not "stop, wrong number".

Worked example with mixed operators:

| #   | condition   | value         | nextIs |
| --- | ----------- | ------------- | ------ |
| 1   | `contains`  | `stop`        | `OR`   |
| 2   | `isEqualTo` | `unsubscribe` | `AND`  |
| 3   | `endsWith`  | `me`          | (last) |

This evaluates as `((rule1 OR rule2) AND rule3)`:

| Contact sends       | rule1 | rule2 | rule3 | Result                           |
| ------------------- | ----- | ----- | ----- | -------------------------------- |
| `Stop messaging me` | true  | false | true  | `(true OR false) AND true` = out |
| `unsubscribe`       | false | true  | false | `(false OR true) AND false` = in |
| `remove me`         | false | false | true  | `(false OR false) AND true` = in |

An empty `optOutRules` array means nobody can opt out by keyword. An empty `optInRules` array means an opted-out contact cannot opt back in by keyword, so only leave it empty on purpose.

### Confirmation template (`templatePayload`)

When `templatePayload` is set and an opt-out rule matches, the named template is sent to that contact immediately as a confirmation ("You have been unsubscribed. Reply START to subscribe again."). Details:

- `templateName` and `languageCode` must identify one of your approved templates. If no such template exists, nothing is sent and the opt-out still happens.
- The confirmation is sent without any variable values, so use a template with no placeholders.
- It is the one message that is still delivered to the contact after they opt out. It is sent best-effort; a delivery failure does not undo the opt-out.
- No confirmation is sent on opt-in.

### What happens to an opted-out contact

Being opted out only affects what **you** send; the contact can still message you and you still receive everything they send.

- **Campaigns and bulk template sends.** The contact is skipped. Nothing is sent to WhatsApp and nothing is charged. The skipped message is recorded with status `failed` and the failure reason `Client did not opt-in`, so it shows up in the campaign's failed count and in message webhooks like any other failure.
- **Single template sends** via `POST /v1/messages/send`. Same behaviour: the request succeeds, but the message for that contact is recorded as `failed` with reason `Client has not opted in` and is not sent.
- **Session messages** (text, media, interactive, location, contacts) via `POST /v1/messages/send` are rejected with `400 Client has not opted in`.
- **Contacts API** returns `"optedIn": false` for the contact.

The opt-out check is applied at send time, so a campaign scheduled before the contact opted out still skips them when it runs.

### How a contact opts back in

A contact returns to opted in when they send you a WhatsApp message that matches your `optInRules`. This is the only path: the `optedIn` flag cannot be set directly through the API, so make sure your opt-out confirmation tells the contact which keyword to reply with (for example "Reply START to subscribe again").

> [!TIP]
> Meta requires you to honour opt-out requests for marketing messages, and a high volume of blocks or reports lowers your quality rating (see [Account Status](#account-status)). Keep `STOP` and `UNSUBSCRIBE` in your opt-out rules at all times.

### Opt Rules Errors

| Status | Message                                                     | When                                                                                                            |
| ------ | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| 400    | Validation message from the schema                          | A rule is missing `condition`, `value` or `nextIs`, uses a value outside the allowed list, or `value` is empty. |
| 403    | `API key does not have the required scope (business:write)` | The key was created with the **Read-only** preset; use a **Full access** key.                                   |

---

## Business Details

:::api
method: GET
endpoint: /v1/business
title: Get Business Details
description: Read the profile and settings of the business the API key belongs to.

## Response

```response
{
  "message": "Successfully fetch business details!",
  "data": {
    "id": 12345,
    "name": "Acme Retail",
    "description": "Acme Retail customer support",
    "sector": "RETAIL",
    "bizAttributes": "[\"city\",\"orderId\"]",
    "bizAttributesType": "[{\"fieldKey\":\"city\",\"dataType\":\"text\"},{\"fieldKey\":\"orderId\",\"dataType\":\"text\"}]",
    "businessAccountId": "102290129340398",
    "countryCode": 91,
    "bizWhatsappNumber": "919876543210",
    "phoneNumberId": "106540352242922",
    "fbAppId": "1234567890123456",
    "catalogSheetLink": null,
    "integrations": {
      "optRules": {
        "optOutRules": [
          { "condition": "isEqualTo", "value": "STOP", "nextIs": "OR" }
        ],
        "optInRules": [
          { "condition": "isEqualTo", "value": "START", "nextIs": "OR" }
        ],
        "templatePayload": {
          "templateName": "opt_out_confirmation",
          "languageCode": "en"
        }
      },
      "isLinkTrackingEnabled": true,
      "customDomainForRedirection": "https://links.acme.com",
      "metaApiCallsPerSecond": 75,
      "pauseMarketingTemplates": false,
      "coexistence": { "enabled": false }
    },
    "webhooks": [
      {
        "url": "https://api.acme.com/webhooks/whatsapp",
        "isEnabled": true,
        "fields": ["metaWebhooks"],
        "headers": { "x-api-key": "***************a8f3c" }
      }
    ],
    "webWidgetOrigins": ["https://acme.com", "https://*.acme.com"],
    "isEmbeddedSignUp": true,
    "signUpType": "embedded",
    "isMarkReadMsg": true,
    "canViewCost": false,
    "asyncMessageMode": false,
    "activeChatbotId": "8c1f2b6e-4d2a-4b0e-9d5f-3a7c1e2f4b6d",
    "activeVoiceBotId": null,
    "orgId": 678,
    "createdAt": "2025-01-10T08:30:00.000Z",
    "updatedAt": "2026-09-01T12:00:00.000Z",
    "isFbAccessToken": true,
    "orgSettings": {}
  }
}
```

:::

### Get Business Details Example

```bash
curl -X GET "{{API_URL}}/v1/business" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Business Details Fields

| Field               | Type    | Description                                                                                                                                                                                                                                                           |
| ------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | number  | Your business ID. Use it as `business_id` where an org-level operation asks for one.                                                                                                                                                                                  |
| `name`              | string  | Business name shown in the dashboard.                                                                                                                                                                                                                                 |
| `sector`            | string  | Industry the business was registered with.                                                                                                                                                                                                                            |
| `bizAttributes`     | string  | JSON-encoded array of your custom contact attribute names, in display order. Manage them on the [Contacts](/docs/api/contacts) page.                                                                                                                                  |
| `bizAttributesType` | string  | JSON-encoded array describing each attribute: `fieldKey` plus `dataType` (`text`, `numerical`, `dropdown` with `dropdownOptions`, or `tags` with `tagOptions`).                                                                                                       |
| `businessAccountId` | string  | Your WhatsApp Business Account (WABA) ID.                                                                                                                                                                                                                             |
| `phoneNumberId`     | string  | Meta's ID for your business phone number.                                                                                                                                                                                                                             |
| `bizWhatsappNumber` | string  | Your business phone number with country code.                                                                                                                                                                                                                         |
| `countryCode`       | number  | Country calling code of the business number.                                                                                                                                                                                                                          |
| `fbAppId`           | string  | Meta app ID the number is connected through.                                                                                                                                                                                                                          |
| `integrations`      | object  | Account-level settings written by the endpoints on this page: `optRules`, `isLinkTrackingEnabled`, `customDomainForRedirection`, `metaApiCallsPerSecond`, `pauseMarketingTemplates`, `coexistence`, `liveChatbots`, `chatAssignment`. Keys are present only once set. |
| `webhooks`          | array   | Your configured webhook endpoints (see [Webhooks](/docs/api/webhooks)). Header values are masked to their last 5 characters.                                                                                                                                          |
| `webWidgetOrigins`  | array   | Allowed origins for the web chat widget (see [Web Widget Origins](#web-widget-origins)).                                                                                                                                                                              |
| `isEmbeddedSignUp`  | boolean | Whether the number was connected through Meta's embedded signup.                                                                                                                                                                                                      |
| `signUpType`        | string  | How the account was onboarded, e.g. `heltar`, `embedded`, `custom`.                                                                                                                                                                                                   |
| `isMarkReadMsg`     | boolean | Whether read receipts are sent when you reply (see [Mark-read access](#mark-read-access)).                                                                                                                                                                            |
| `asyncMessageMode`  | boolean | Whether API sends are queued and acknowledged immediately (see [Async message mode](#async-message-mode)).                                                                                                                                                            |
| `canViewCost`       | boolean | Whether per-message cost is shown in the dashboard for this business.                                                                                                                                                                                                 |
| `activeChatbotId`   | string  | Chatbot currently handling new conversations, if any.                                                                                                                                                                                                                 |
| `activeVoiceBotId`  | string  | Bot that answers voice calls, if voice is enabled.                                                                                                                                                                                                                    |
| `orgId`             | number  | Organisation the business belongs to.                                                                                                                                                                                                                                 |
| `isFbAccessToken`   | boolean | `true` when a Meta access token is stored for the number. The token itself is never returned.                                                                                                                                                                         |
| `orgSettings`       | object  | Organisation-wide settings that apply to every business in the org.                                                                                                                                                                                                   |

Other internal configuration keys may also appear in `data`; you can ignore anything not listed here.

---

## WhatsApp Business Profile

The business profile is what customers see when they open your business info in WhatsApp: the about text, address, description, email, websites, category and profile picture. Both endpoints talk to Meta directly.

:::api
method: GET
endpoint: /v1/business/profile
title: Get WhatsApp Profile
description: Read the current WhatsApp business profile of your number from Meta.

## Response

```response
{
  "message": "Successfully fetch business profile details!",
  "data": [
    {
      "about": "Order support, Mon-Sat 9am to 7pm",
      "address": "12 MG Road, Bengaluru 560001",
      "description": "Acme Retail official WhatsApp support line.",
      "email": "support@acme.com",
      "profile_picture_url": "https://pps.whatsapp.net/v/t61.24694-24/...",
      "websites": ["https://acme.com", "https://shop.acme.com"],
      "vertical": "RETAIL",
      "messaging_product": "whatsapp"
    }
  ]
}
```

:::

### Get WhatsApp Profile Example

```bash
curl -X GET "{{API_URL}}/v1/business/profile" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

`data` is an array with a single profile object. `profile_picture_url` is a temporary URL issued by Meta; fetch it again when you need a fresh one.

---

:::api
method: POST
endpoint: /v1/business/profile
title: Update WhatsApp Profile
description: Update one or more fields of the WhatsApp business profile. Only the fields you send are changed.

## Body Parameters

- about: string - Short status line, 1 to 139 characters
- address: string - Business address, up to 256 characters
- description: string - Business description, up to 512 characters
- email: string - Contact email, up to 128 characters
- websites: array - Up to 2 website URLs, each up to 256 characters
- vertical: string - Business category. One of `UNDEFINED`, `OTHER`, `AUTO`, `BEAUTY`, `APPAREL`, `EDU`, `ENTERTAIN`, `EVENT_PLAN`, `FINANCE`, `GROCERY`, `GOVT`, `HOTEL`, `HEALTH`, `NONPROFIT`, `PROF_SERVICES`, `RETAIL`, `TRAVEL`, `RESTAURANT`, `NOT_A_BIZ`
- profile_picture_handle: string - Upload handle of a new profile picture. Obtain it with the media upload endpoint on the [Templates](/docs/api/templates) page

```request
{
  "about": "Order support, Mon-Sat 9am to 7pm",
  "description": "Acme Retail official WhatsApp support line.",
  "email": "support@acme.com",
  "websites": ["https://acme.com"],
  "vertical": "RETAIL"
}
```

## Response

```response
{
  "message": "Successfully updated business profile details!",
  "data": {
    "success": true
  }
}
```

:::

### Update WhatsApp Profile Example

```bash
curl -X POST "{{API_URL}}/v1/business/profile" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "about": "Order support, Mon-Sat 9am to 7pm",
    "description": "Acme Retail official WhatsApp support line.",
    "email": "support@acme.com",
    "websites": ["https://acme.com"],
    "vertical": "RETAIL"
  }'
```

### WhatsApp Profile Errors

| Status | Message                                                                                 | When                                                                                    |
| ------ | --------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 400    | `Business details are missing. So please add first business details!`                   | The number is not fully connected yet (missing app, account, token or phone number ID). |
| 400    | `Error fetching business profile details!` / `Error updating business profile details!` | Meta rejected the request. `errorRaw` carries Meta's error.                             |
| 400    | Validation message from the schema                                                      | A field is too long, `email` is not an email, or a website is not a valid URL.          |

---

## Commerce Settings

Controls whether your product catalog and shopping cart are visible to customers in WhatsApp. Both endpoints talk to Meta directly.

:::api
method: GET
endpoint: /v1/business/commerce
title: Get Commerce Settings
description: Read the catalog visibility and cart settings of your number.

## Response

```response
{
  "message": "Successfully fetch whatsapp commerce settings!",
  "data": {
    "data": [
      {
        "is_cart_enabled": true,
        "is_catalog_visible": true,
        "id": "106540352242922"
      }
    ]
  }
}
```

:::

### Get Commerce Settings Example

```bash
curl -X GET "{{API_URL}}/v1/business/commerce" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

`data` is Meta's response as-is: the settings object lives at `data.data[0]`.

---

:::api
method: POST
endpoint: /v1/business/commerce
title: Update Commerce Settings
description: Turn the catalog and cart on or off. Both flags are required on every call.

## Body Parameters

- is_cart_enabled: boolean [required] - Whether customers can add products to a cart and send you an order
- is_catalog_visible: boolean [required] - Whether your catalog is shown on your business profile

```request
{
  "is_cart_enabled": true,
  "is_catalog_visible": true
}
```

## Response

```response
{
  "message": "Successfully update whatsapp commerce settings!",
  "data": {
    "success": true
  }
}
```

:::

### Update Commerce Settings Example

```bash
curl -X POST "{{API_URL}}/v1/business/commerce" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "is_cart_enabled": true, "is_catalog_visible": true }'
```

A `400 Failed to fetch whatsapp commerce settings` / `Failed to update whatsapp commerce settings` is returned when Meta rejects the call, for example when no catalog is connected to the account.

---

## Link Tracking

When link tracking is enabled, URLs in the template messages you send are replaced with short, trackable links so you can see who clicked. You can optionally serve those links from your own domain.

:::api
method: PUT
endpoint: /v1/business/link-tracking
title: Enable or Disable Link Tracking
description: Turn click tracking for links in template messages on or off.

## Body Parameters

- isLinkTrackingEnabled: boolean [required] - `true` to shorten and track links, `false` to send URLs untouched

```request
{
  "isLinkTrackingEnabled": true
}
```

## Response

```response
{
  "message": "Successfully link tracking enabled!"
}
```

:::

### Link Tracking Example

```bash
curl -X PUT "{{API_URL}}/v1/business/link-tracking" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isLinkTrackingEnabled": true }'
```

The message reads `Successfully link tracking disabled!` when you pass `false`.

---

:::api
method: PUT
endpoint: /v1/business/custom-domain-for-redirection
title: Set Custom Domain for Tracked Links
description: Serve tracked links from your own branded domain instead of the default one. Send an empty string to go back to the default domain.

## Body Parameters

- customDomainForRedirection: string [required] - Full origin of your link domain including scheme, e.g. `https://links.acme.com`. Pass `""` to clear

```request
{
  "customDomainForRedirection": "https://links.acme.com"
}
```

## Response

```response
{
  "message": "Successfully updated custom domain for redirection!"
}
```

:::

### Custom Domain Example

```bash
curl -X PUT "{{API_URL}}/v1/business/custom-domain-for-redirection" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "customDomainForRedirection": "https://links.acme.com" }'
```

> [!IMPORTANT]
> Setting the domain here is only half the job. The domain also has to point at the link tracker (DNS plus certificate) before links on it resolve. Follow the [Custom Domain for Link Tracker](/docs/guides/link-tracker-custom-domain) guide for the full setup.

---

## Data Localization

Meta can store the conversation data of your number in a specific country. These endpoints read and change that setting on Meta; nothing is stored on our side.

:::api
method: GET
endpoint: /v1/business/data-localization-region
title: Get Data Localization Region
description: Read where Meta currently stores the data of your number.

## Response

```response
{
  "message": "Fetched data localization region.",
  "data": {
    "status": "in_country_storage_enabled",
    "dataLocalizationRegion": "IN"
  }
}
```

:::

### Get Data Localization Region Example

```bash
curl -X GET "{{API_URL}}/v1/business/data-localization-region" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

`status` is `default` (Meta's default storage, `dataLocalizationRegion` is `null`) or `in_country_storage_enabled` (data is stored in `dataLocalizationRegion`).

---

:::api
method: PUT
endpoint: /v1/business/data-localization-region
title: Set Data Localization Region
description: Pin data storage to a country, or pass `null` to return to Meta's default.

## Body Parameters

- dataLocalizationRegion: string [required] - Two-letter uppercase ISO country code, or `null` to clear. Regions Meta currently supports include `AE`, `AU`, `BH`, `BR`, `CA`, `CH`, `DE`, `GB`, `ID`, `IN`, `JP`, `KR`, `KW`, `NG`, `OM`, `PK`, `SA`, `SG`, `TH`, `TR`, `ZA`

```request
{
  "dataLocalizationRegion": "IN"
}
```

## Response

```response
{
  "message": "Data localization region set to IN.",
  "data": {
    "dataLocalizationRegion": "IN"
  }
}
```

:::

### Set Data Localization Region Example

```bash
curl -X PUT "{{API_URL}}/v1/business/data-localization-region" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "dataLocalizationRegion": "IN" }'
```

Passing `null` returns `Data localization region cleared.` with `"dataLocalizationRegion": null`. Any code is accepted as long as it is two uppercase letters; Meta returns a `400 Failed to update data localization region on Meta.` if it does not support that region.

---

## Messaging Behaviour

Three switches that change how outgoing messages are handled for the whole business.

### Mark-read access

:::api
method: PUT
endpoint: /v1/business/mark-read-access
title: Enable or Disable Read Receipts
description: Control whether a contact's messages are marked as read (blue ticks) on WhatsApp when you reply to them. Enabled by default.

## Body Parameters

- isMarkRead: boolean [required] - `true` to send read receipts when replying, `false` to never send them

```request
{
  "isMarkRead": false
}
```

## Response

```response
{
  "message": "Successfully disable mark read message!"
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/business/mark-read-access" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isMarkRead": false }'
```

When enabled, the contact's latest received message is marked as read on WhatsApp whenever you send them a session message (text, media, interactive) through the API or the inbox. When disabled, no read receipts are sent at all. The message reads `Successfully enable mark read message!` when you pass `true`.

### Async message mode

:::api
method: PUT
endpoint: /v1/business/async-message-mode
title: Enable or Disable Async Message Mode
description: Choose whether `POST /v1/messages/send` waits for WhatsApp to accept each message (sync) or queues them and returns immediately (async). Disabled by default.

## Body Parameters

- asyncMessageMode: boolean [required] - `true` to queue API sends and acknowledge immediately, `false` to wait for WhatsApp's response

```request
{
  "asyncMessageMode": true
}
```

## Response

```response
{
  "message": "Successfully enabled async message mode!"
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/business/async-message-mode" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "asyncMessageMode": true }'
```

With async mode on, API calls to `POST /v1/messages/send` return as soon as the messages are queued. Each message gets a platform message ID (`hemid`) right away; the WhatsApp message ID (`wamid`) and delivery statuses arrive later through your [webhooks](/docs/api/webhooks). This is the recommended mode for high-volume senders because your request never waits on WhatsApp. It applies to API-key requests only; messages sent from the dashboard are always sent synchronously. See the [Messages](/docs/api/messages) page for how to look a message up by `hemid`.

### Meta API calls per second

:::api
method: PUT
endpoint: /v1/business/meta-api-calls-per-second
title: Set Outgoing Rate Limit
description: Cap how many messages per second are sent to WhatsApp on behalf of this business. Applies to campaigns and queued API sends.

## Body Parameters

- metaApiCallsPerSecond: number [required] - Messages per second, from 1 to 1000. Defaults to 75 when never set

```request
{
  "metaApiCallsPerSecond": 200
}
```

## Response

```response
{
  "message": "Successfully updated meta api call api limit per sec!"
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/business/meta-api-calls-per-second" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "metaApiCallsPerSecond": 200 }'
```

Set this to match the throughput Meta has granted your number (see `throughput.level` in [Account Status](#account-status)). Setting it higher than your number's real limit does not make sends faster; WhatsApp will start rejecting messages with rate-limit errors.

---

## Web Widget Origins

The web chat widget only accepts connections from websites you have allowlisted. This endpoint replaces the allowlist.

:::api
method: PUT
endpoint: /v1/business/web-widget/origins
title: Set Web Widget Allowed Origins
description: Replace the list of website origins allowed to load the web chat widget. An empty list disables the widget.

## Body Parameters

- origins: array [required] - Up to 50 origins. Each is an exact origin (`https://acme.com`, optional port) or a wildcard subdomain pattern (`https://*.acme.com`). Scheme is part of the match, so `https://` does not allow `http://`

```request
{
  "origins": ["https://acme.com", "https://*.acme.com", "http://localhost:3000"]
}
```

## Response

```response
{
  "message": "Updated widget allowed origins",
  "data": {
    "origins": ["https://acme.com", "https://*.acme.com", "http://localhost:3000"]
  }
}
```

:::

### Web Widget Origins Example

```bash
curl -X PUT "{{API_URL}}/v1/business/web-widget/origins" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "origins": ["https://acme.com", "https://*.acme.com"] }'
```

Entries are trimmed, trailing slashes are removed and duplicates are dropped; the response shows the list exactly as stored. A wildcard pattern matches any subdomain with at least one label (`https://shop.acme.com` matches `https://*.acme.com`, `https://acme.com` does not). Host matching is case-insensitive. Requests from any origin not on the list are refused with `403`.

---

## Meta Account Operations

One-off operations against your WhatsApp Business account. You normally need these only during onboarding or when recovering from a disconnected number.

:::api
method: POST
endpoint: /v1/business/coexistence-sync
title: Request Coexistence Sync
description: Ask WhatsApp to sync data from the WhatsApp Business app when the same number is used in both the app and the API (coexistence).

## Body Parameters

- syncType: string [required] - `smb_app_state_sync` to sync contacts and current app state, or `history` to import chat history from the app

```request
{
  "syncType": "history"
}
```

## Response

```response
{
  "message": "Successfully requested coexistence sync!",
  "data": {
    "request_id": "A24EA888AE86139F9A1ECFE4463E7186"
  }
}
```

:::

### Coexistence Sync Example

```bash
curl -X POST "{{API_URL}}/v1/business/coexistence-sync" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "syncType": "history" }'
```

`data` is Meta's acknowledgement; the sync itself runs asynchronously and the imported contacts and messages appear in your inbox as WhatsApp delivers them. A `history` sync can only run if the person using the WhatsApp Business app agreed to share history; if they declined, no history arrives.

| Status | Message                                         | When                                           |
| ------ | ----------------------------------------------- | ---------------------------------------------- |
| 400    | `Coexistence is not enabled for this business!` | The number is not set up for coexistence.      |
| 400    | `Failed to request coexistence sync!`           | Meta rejected the request; `errorRaw` has why. |

---

:::api
method: POST
endpoint: /v1/business/register-phone-number
title: Register Phone Number
description: Register (or re-register) your phone number with the WhatsApp Cloud API. Use it after a number was deregistered or when Meta reports the number as not registered.

## Body Parameters

- pin: string - The 6-digit two-step verification PIN of the number. If omitted, the platform's default registration PIN is used

```request
{
  "pin": "123456"
}
```

## Response

```response
{
  "message": "Successfully register phone number!",
  "data": {
    "success": true
  }
}
```

:::

### Register Phone Number Example

```bash
curl -X POST "{{API_URL}}/v1/business/register-phone-number" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "pin": "123456" }'
```

If the number already has two-step verification enabled with a different PIN, Meta rejects the call and the response is `400 Failed to register phone number!` with Meta's error in `errorRaw`. A `pin` that is not exactly 6 digits fails validation with `400 Pin must be 6 digits long`.

---

:::api
method: POST
endpoint: /v1/business/subscribe-webhook
title: Subscribe to Meta Webhooks
description: Subscribe the platform to your WhatsApp Business Account so that Meta delivers incoming messages and status updates. Run it if messages stop arriving after a change on the Meta side. No request body.

## Response

```response
{
  "message": "Successfully subscribed to webhooks!",
  "data": {
    "success": true
  }
}
```

:::

### Subscribe Webhook Example

```bash
curl -X POST "{{API_URL}}/v1/business/subscribe-webhook" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Calling it when already subscribed is harmless. You can confirm the subscription with `fields=subscribed_apps` on [Account Status](#account-status). A `400 Business Account ID or FB Access Token is missing!` means the number is not connected yet.

---

## Journey Events

Journeys are event-driven automations: your backend posts business events such as `added_to_cart` or `checkout_complete`, and every journey that listens for that event runs its next step for that person (for example, sends a reminder template two hours later if they did not check out). Journeys are built in the code editor and declare the event names they listen to (their trigger events). See [Code Editor](/docs/api/code-editor).

> [!NOTE]
> This endpoint is covered by the `journeys` resource in the scope picker: the API key needs `journeys:write` (or the **Full access** preset).

:::api
method: POST
endpoint: /v1/journeys/events
title: Ingest Journey Event
description: Send a business event for one person. The person is identified by phone or email; every journey listening for the event runs in the background and the request returns immediately.

## Body Parameters

- event: object [required] - `{ "name": "...", "properties": { ... } }`. `name` is the event name your journeys listen for; `properties` is any JSON object your journey code can read. No other keys are allowed inside `event`
- phone: string - WhatsApp number of the person with country code, e.g. `919876543210`. Required unless `email` is given
- email: string - Email of the person. Required unless `phone` is given. Case-insensitive
- journeyId: string - UUID of one journey to target. When omitted, every journey in your organisation whose trigger events include `event.name` for this business receives the event

```request
{
  "event": {
    "name": "added_to_cart",
    "properties": {
      "orderId": "Order #12345",
      "cartValue": 2499,
      "currency": "INR",
      "items": ["SKU-1001", "SKU-2042"]
    }
  },
  "phone": "919876543210",
  "email": "priya@example.com"
}
```

## Response

```response
{
  "message": "Event accepted",
  "data": {
    "masterClientId": "3f9d2c1e-7b4a-4e8f-9a6d-2c5b8e1f4a7d",
    "journeys": ["8c1f2b6e-4d2a-4b0e-9d5f-3a7c1e2f4b6d"]
  }
}
```

:::

### Ingest Journey Event Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/journeys/events" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "name": "added_to_cart",
      "properties": { "orderId": "Order #12345", "cartValue": 2499 }
    },
    "phone": "919876543210"
  }'
```

```javascript
await fetch('{{API_URL}}/v1/journeys/events', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    event: {
      name: 'added_to_cart',
      properties: { orderId: 'Order #12345', cartValue: 2499 },
    },
    phone: '919876543210',
  }),
});
```

```python
import requests

requests.post(
    "{{API_URL}}/v1/journeys/events",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={
        "event": {
            "name": "added_to_cart",
            "properties": {"orderId": "Order #12345", "cartValue": 2499},
        },
        "phone": "919876543210",
    },
)
```

:::

### How events are processed

- **The person is resolved first.** The identifiers are matched against your organisation's contacts (across all your businesses). If nobody matches, a new person record is created from the phone and/or email, so you can send events for people who have never messaged you. `masterClientId` in the response is that person's ID. A phone is normalised before matching, so `+91 98765-43210` and `919876543210` resolve to the same person.
- **Fan-out.** Without `journeyId`, the event is delivered to every journey in your organisation whose trigger events include `event.name` for this business. With `journeyId`, only that journey receives it, and only if the event is on its trigger list for this business. `journeys` in the response lists the IDs that were triggered; an empty array means no journey is listening for that event.
- **Asynchronous.** The response is sent as soon as the event is accepted. Each journey turn (running your journey code, sending messages, scheduling waits) happens in the background. Any message a journey sends goes out from the business the event was posted to and is visible in the inbox and in your webhooks like any other message.
- **Properties are passed through.** `event.properties` reaches your journey code unchanged, so put everything the journey needs (order ID, amount, product names) in there.

### Journey Events Errors

| Status | Message                                                     | When                                                                                                   |
| ------ | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 400    | `At least one identifier (phone, email) is required`        | Neither `phone` nor `email` was given.                                                                 |
| 400    | Validation message from the schema                          | `event.name` is empty, `email` is not an email, `journeyId` is not a UUID, or an unknown key was sent. |
| 400    | `Could not resolve a contact from the given identifiers`    | The identifiers could not be turned into a person record.                                              |
| 404    | `Journey not found`                                         | `journeyId` does not exist in your business or is not a journey.                                       |
| 403    | `API key does not have the required scope (journeys:write)` | The key lacks the `journeys:write` scope.                                                              |

---

## Related

Other business-level settings live on the page of the feature they belong to:

- [Business Username](/docs/api/business-username) - claim and manage the searchable username of your number.
- [Webhooks](/docs/api/webhooks) - add, update and remove the webhook URLs that receive your events.
- [Messages](/docs/api/messages) - typing indicator, sending messages and looking messages up by `hemid` in async mode.
- [Calls](/docs/api/calls) - call settings for inbound and outbound voice calls.
- [Contacts](/docs/api/contacts) - custom attribute definitions and the `optedIn` flag on each contact.
- [Templates](/docs/api/templates) - pausing marketing templates and uploading media (including profile picture handles).
- [Chatbot](/docs/api/chatbot) - live chatbot settings and traffic split between bots.
- [Custom Domain for Link Tracker](/docs/guides/link-tracker-custom-domain) - DNS and certificate setup for branded tracked links.
