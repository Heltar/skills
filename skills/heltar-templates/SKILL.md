---
name: heltar-templates
description: 'Create, update, list, retrieve, delete, and analyze WhatsApp message templates on Heltar, including the Meta template library, media-header uploads and media links, category-change history, fallback templates, and the marketing-template pause switch. Use when a user wants to submit or edit a template for Meta approval, check template status, react to recategorisation or pauses, or pull Meta send/delivery counts.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: templates, meta-approval, utility, marketing, authentication, components, buttons, library, media-upload, media-link, category-updates, fallback, pause-marketing, analytics
  uses:
    - heltar-authentication
---

# Heltar Templates

## Overview

Templates are pre-approved message bodies required to start a conversation outside the WhatsApp 24-hour customer service window. Heltar wraps Meta's template approval flow and adds the media, fallback, pause, and analytics tooling around it.

## Agent Instructions

Before creating a template, gather:

1. **Category** — `UTILITY` (transactional: order, shipping, OTP-style updates), `MARKETING` (promo, re-engagement), or `AUTHENTICATION` (OTP / 2FA).
2. **Language** — ISO code (`en`, `hi`, `en_US`, …).
3. **Components** — header (text/image/video/document/location/product), body (with `{{1}}` placeholders + example values), optional footer, optional buttons.
4. **Buttons** — quick reply (max 3), URL / phone (max 2), copy code.

> Meta approval typically takes 24–48 hours. `UTILITY` templates have higher delivery rates and lower per-message cost than `MARKETING`. Meta's pre-approved library skips most of the review wait.

Match user intent:

| User intent                                                   | Endpoint                                                                                   |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Submit a new template for Meta review                         | `POST /v1/templates`                                                                       |
| Create from Meta's pre-approved library                       | `POST /v1/templates` with `library_template_name` (+ `library_template_button_inputs`)     |
| Browse the library                                            | `GET /v1/templates/library?language=&topic=&usecase=&industry=&search=`                    |
| Edit the category / components of an existing template        | `POST /v1/templates/:templateId`                                                           |
| List all templates with status                                | `GET /v1/templates` (`?refresh=true` bypasses the cache)                                   |
| Fetch one template (every language, or one)                   | `GET /v1/templates/:templateName[?templateLang=en]` → always an array                      |
| Delete every language version                                 | `DELETE /v1/templates/:templateName`                                                       |
| Delete one language version                                   | `DELETE /v1/templates/:templateName/:templateId`                                           |
| Upload a sample file for an IMAGE / VIDEO / DOCUMENT header   | `POST /v1/business/resumable-upload` (multipart `file`, Full-access key) → `data.h` handle |
| Store the media URL used when a media-header template is sent | `POST /v1/templates/media-link`                                                            |
| Store one media URL per carousel card                         | `POST /v1/templates/bulk-media-link`                                                       |
| List stored media links                                       | `GET /v1/templates/media-link`                                                             |
| See which templates Meta recategorised, and when              | `GET /v1/templates/category-updates?startDate=&endDate=`                                   |
| List / upsert / delete fallback configs                       | `GET` / `POST /v1/templates/fallback`, `DELETE /v1/templates/fallback/:configId`           |
| Stop every MARKETING template send at once                    | `PUT /v1/business/pause-marketing-templates` (Full-access key)                             |
| Meta sent / delivered counts over a time range                | `GET /v1/templates/analytics`                                                              |

## Authentication

Bearer API key. `/v1/templates` `GET` requests need the `templates:read` scope, `POST` and `DELETE` need `templates:write`. `/v1/business/resumable-upload` and `/v1/business/pause-marketing-templates` are outside the per-resource scope picker — use a **Full access** key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Quick Start — submit a UTILITY template

```bash
curl -X POST "$API_URL/v1/templates" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "order_confirmation",
    "category": "UTILITY",
    "language": "en",
    "components": [
      { "type": "BODY",
        "text": "Hi {{1}}, your order {{2}} has been confirmed.",
        "example": { "body_text": [["John", "ORD-123"]] }
      }
    ]
  }'
```

Response carries `data: { id, status: "PENDING", category }` — the category can differ from what you sent when `allow_category_change` (default `true`) lets Meta reassign it. Poll `GET /v1/templates/order_confirmation?templateLang=en` (returns an array) until `status` is `APPROVED`.

## Component cheatsheet

```jsonc
[
  { "type": "HEADER", "format": "TEXT", "text": "Order Confirmed!" }, // or IMAGE/VIDEO/DOCUMENT with example.header_handle, LOCATION, PRODUCT
  {
    "type": "BODY",
    "text": "Hi {{1}}, your order {{2}}.",
    "example": { "body_text": [["John", "ORD-1"]] },
  },
  { "type": "FOOTER", "text": "Thank you!" }, // optional, max 60 chars
  {
    "type": "BUTTONS",
    "buttons": [
      { "type": "URL", "text": "Track", "url": "https://x.com/{{1}}" },
      { "type": "QUICK_REPLY", "text": "Support" },
      {
        "type": "PHONE_NUMBER",
        "text": "Call",
        "phone_number": "+919876543210",
      },
      { "type": "COPY_CODE", "example": "DISCOUNT20" },
    ],
  },
]
```

Body max 1024 chars, header text max 60. Component `type` and header `format` are case-insensitive. AUTHENTICATION templates may omit body `text` and use `add_security_recommendation` (body) and `code_expiration_minutes` (footer). Other components: `CAROUSEL` (`cards[]`, each with its own media `HEADER`, `BODY`, optional `BUTTONS`), `LIMITED_TIME_OFFER`, `CALL_PERMISSION_REQUEST` — see `references/api-reference.md`.

## Media headers

1. `POST /v1/business/resumable-upload` as `multipart/form-data` with the sample file in field `file` (one file, ≤100 MB) → `data.h`, an opaque media handle valid only as a template sample.
2. Put it in the header component: `{ "type": "HEADER", "format": "IMAGE", "example": { "header_handle": ["<h>"] } }` (same for `VIDEO`, `DOCUMENT`, and carousel card headers).
3. Once approved, store the public URL that is used at send time: `POST /v1/templates/media-link` with `{ templateId, link, fileName }`, or `POST /v1/templates/bulk-media-link` with `mediaAttachment[]` (one entry per carousel card, in order; the first doubles as the main header). Host your file with the presigned-url endpoint in [`heltar-messaging`](../heltar-messaging/SKILL.md).

WhatsApp only renders `IMAGE` headers as JPEG/PNG, `VIDEO` as MP4, and `DOCUMENT` as PDF — upload those formats for samples.

## Status values

`PENDING` (under review) · `APPROVED` (usable) · `REJECTED` (fix and resubmit; `rejected_reason` is returned) · `PAUSED` (temporarily) · `DISABLED` (permanently). List entries also carry `category`, `previous_category` when Meta recategorised, `quality_score` (`GREEN` / `YELLOW` / `RED` / `UNKNOWN`), and `last_updated_time`.

## Sending an approved template

Pass `templateName` + `languageCode` + `variables[]` to `POST /v1/messages/send`. See [`heltar-messaging`](../heltar-messaging/SKILL.md); many recipients → [`heltar-campaigns`](../heltar-campaigns/SKILL.md).

## Fallback templates and the marketing pause

- A fallback config is keyed on `sourceTemplateName` + `sourceLanguageCode` + `triggerCondition` — `PAUSED` (source is paused by Meta) or `UTILITY_TO_MARKETING` (source's current category is `MARKETING`, typically after recategorisation). `POST /v1/templates/fallback` with the same key updates the existing config. The fallback is sent in the same language with the same parameters, so it must match the source's variable signature (header format and variable count, body variable count, buttons, carousel cards) or the save fails with `Templates are not compatible: ...`. A `UTILITY_TO_MARKETING` fallback must itself be `UTILITY`. One substitution per send, no loops, `isEnabled: false` keeps the config but ignores it.
- `PUT /v1/business/pause-marketing-templates` with `{ "pauseMarketingTemplates": true }` blocks every `MARKETING` (and `MARKETING_LITE`) template send — from the API, campaigns, and the inbox. Blocked messages are recorded as cancelled (`Marketing templates are paused for this business`); the category is re-checked with Meta on every send so recategorised templates are caught too. `UTILITY` / `AUTHENTICATION` templates, free-form messages, and UTILITY fallbacks are unaffected — fallback is resolved before the pause check.

## Analytics

```
GET /v1/templates/analytics?startDateTimestamp=1754006400&endDateTimestamp=1756684800&granularity=DAY&wabaNumber=109876543210987
```

All four query params are required: UNIX timestamps in **seconds**, `granularity` ∈ `HALF_HOUR` / `DAY` / `MONTH`, `wabaNumber` = the phone number ID. Returns Meta's payload unchanged — `data.analytics.data_points[{ start, end, sent, delivered }]` for the whole account, not per template. Meta rejects too-wide ranges for the granularity (400 `Failed to fetch analytics`, details in `errorRaw`). For per-template delivery / read / click, conversation, and cost breakdowns use [`heltar-analytics`](../heltar-analytics/SKILL.md).

## Key Rules / Gotchas

- `name` is lowercase with underscores, 1–512 chars; `language` 2–5 chars; `category` case-insensitive. `components` must contain a `BODY` unless `library_template_name` is set.
- Submitting a body without an `example.body_text` entry covering every `{{N}}` placeholder → 400. Buttons: max 3 `QUICK_REPLY`, max 2 `URL` / `PHONE_NUMBER`.
- Meta rejections come back as 400 `Failed to create template` / `Failed to update template` / `Failed to delete template` with Meta's error in `errorRaw`. `Business details are missing...` means the WhatsApp Business Account is not fully connected yet.
- `GET /v1/templates/:templateName` never 404s — an unknown name returns 200 with `data: []`. A template that exists in several languages appears once per language in lists.
- `POST /v1/templates/:templateId` replaces the **whole** component list; editing an approved template sends it back to review, and Meta limits how often a template can be edited. Media headers need a fresh `header_handle` — the display URL from the list is not accepted.
- A deleted template name cannot be reused for 30 days, and messages already queued with it fail. Reusing a name with a different category or language is a separate template, not an edit — use a new name (`order_confirmation_v2`) and migrate.
- `GET /v1/templates` is served from the platform's cache; pass `refresh=true` to re-fetch from Meta. If the account is not connected, it returns 200 with `"Please setup account first"` and empty `data`.
- Library: `topic` / `usecase` / `industry` are upper-cased for you; results are capped at 500 and limited to templates whose variables are numbered placeholders. Supply URL / phone button values via `library_template_button_inputs`.
- Category updates: `startDate` / `endDate` are `YYYY-MM-DD`, interpreted in IST, both inclusive; covers every WhatsApp Business Account in your organisation, newest first.
- Resumable upload: 403 `Business does not have a Facebook App ID...` → add the App ID in your WhatsApp API setup. File name ≤255 chars, no path separators or `< > : " ? *`; bytes must match the declared MIME type.
- Fallback save requires both templates to exist in `sourceLanguageCode` (404 otherwise); source and fallback cannot be the same (400).

## Related Skills

- [`heltar-messaging`](../heltar-messaging/SKILL.md) — send an approved template; presigned-url for hosting header media.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — send one template to many recipients.
- [`heltar-analytics`](../heltar-analytics/SKILL.md) — per-template delivery, read, click, conversation, and cost analytics.
- [`heltar-business`](../heltar-business/SKILL.md) — account status and WhatsApp API setup (Facebook App ID, connection state).
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — delivery status of sent template messages.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
