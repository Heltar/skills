---
name: heltar-analytics
description: 'Read engagement, template delivery, conversation, pricing and cost analytics from Heltar — daily active contacts and message volume, per-template delivery funnels with message-level drill-down, Meta account analytics, and the cost breakdown that matches your invoice. Use when reporting on messaging performance or spend, building a dashboard, or reconciling a bill.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Analytics
  tags: analytics, engagement, cost, pricing, conversations, template-analytics, reporting
  uses:
    - heltar-authentication
---

# Heltar Analytics

## Overview

The Analytics API exposes the numbers behind the dashboard's analytics pages. The endpoints fall into three groups, and the group decides the date format, what the counts cover and what can go wrong:

| Group                  | Endpoints                                                             | Source                                                                                                                                                                          | Dates                                                          |
| ---------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Platform-computed      | daily engagement, template analytics by day, template message details | Messages sent through Heltar (campaigns, API, chatbot) — includes failure reasons and contact replies                                                                           | `startDate` / `endDate`, `YYYY-MM-DD`, IST calendar days       |
| Meta account analytics | conversation analytics, template analytics (Meta), pricing analytics  | Meta's own analytics for the WhatsApp Business Account, returned unchanged inside `data` — covers every message from the number, including other tools, no per-recipient detail | `startDateTimestamp` / `endDateTimestamp`, Unix seconds        |
| Cost                   | cost analytics, cost analytics by template                            | Priced the way your invoice is, so totals match the bill for the same period (INR)                                                                                              | `startDate` / `endDate`, `YYYY-MM-DD`, not before `2026-07-01` |

## Agent Instructions

Match user intent:

| User intent                                                                                              | Endpoint                                                                                                                                                  |
| -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Daily active contacts, new contacts and message volume per day                                           | `GET /v1/analytics/daily-engagement?startDate=&endDate=`                                                                                                  |
| Per-template delivery funnel (sent / delivered / read / failed / replied / clicked) per day, from Heltar | `GET /v1/templates/template-analytics-clickhouse?startDate=&endDate=`                                                                                     |
| Every message sent with one template on one day — status, failure reason, contact reply                  | `GET /v1/templates/template-details/:templateName/:date`                                                                                                  |
| Meta's conversation counts and cost by category, direction, type and country for one number              | `GET /v1/templates/conversation-analytics?startDateTimestamp=&endDateTimestamp=&granularity=&wabaNumber=`                                                 |
| Meta's daily sent / delivered / read / button-click counts for chosen template IDs                       | `GET /v1/templates/template-analytics?startDateTimestamp=&endDateTimestamp=&templateId=`                                                                  |
| Meta's billable volume (and cost, where exposed) by country, pricing category, type and tier             | `GET /v1/templates/pricing-analytics?startDateTimestamp=&endDateTimestamp=&granularity=` (`org=true` for every business)                                  |
| Exact messaging + AI cost for a period, matching the invoice                                             | `GET /v1/templates/cost-analytics?startDate=&endDate=` (`scope=org` for every business)                                                                   |
| Estimated cost per template per day, with a per-country split                                            | `GET /v1/templates/cost-analytics/templates?startDate=&endDate=`                                                                                          |
| Meta's sent / delivered counts for a business number per half-hour / day / month (not per template)      | `GET /v1/templates/analytics` — see [`heltar-templates`](../heltar-templates/SKILL.md)                                                                    |
| Stats for one campaign (counts, per-recipient status, export)                                            | `GET /v1/campaigns/get-one/:id`, `GET /v1/campaigns/:id`, `GET /v1/campaigns/download-stats/:id` — see [`heltar-campaigns`](../heltar-campaigns/SKILL.md) |

Routing rules of thumb:

- "How did template X perform" → **template analytics by day** (has failure reasons and replies), then **template message details** for the row they want to inspect. Use the Meta template analytics endpoint only when the user explicitly wants Meta's figures or needs sends made from other tools on the same number.
- "What did we spend" → **cost analytics** (exact, matches the invoice). "Which template cost the most" → **cost analytics by template** (estimate). Meta's **pricing analytics** is the account-level view and only carries `cost` when Meta bills the account directly.
- "How did campaign X do" → `heltar-campaigns`. The analytics here are per template per day, never per campaign.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

- `/v1/templates/*` analytics endpoints need the `templates:read` scope.
- `/v1/analytics/*` (daily engagement) is outside the per-resource scope picker: use a key created with the **Full access** preset, or **Read-only** for GET requests. A scoped key gets `403`.

## Quick Start

### Daily engagement for a date range

```bash
curl -X GET "$API_URL/v1/analytics/daily-engagement?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer $HELTAR_API_KEY"
```

Returns one row per day, most recent first, with zeros for quiet days: `uniqueDailyActiveUsers`, `newActiveUsers`, `totalMessages`, `campaignMessages`.

### Cost analytics for a month

```bash
curl -X GET "$API_URL/v1/templates/cost-analytics?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer $HELTAR_API_KEY"
```

Read `data.totalMessagingCost` (INR), `data.aiUsage.totalCostInr` and `data.grandTotalCost` for the headline figures; `data.volumeRows` is the day × country × category breakdown and `data.categoryBreakdown` the MARKETING / UTILITY / AUTHENTICATION split.

## Key Rules

**Dates and time zones**

- Platform-computed and cost endpoints (daily engagement, template analytics by day, template message details, both cost endpoints) take `startDate` / `endDate` as `YYYY-MM-DD`. Both days are inclusive and are calendar days in Indian Standard Time (UTC+05:30). Both parameters are required.
- A malformed date, a date that does not exist (`2026-02-30`) or an `endDate` before `startDate` → `400`.
- Meta endpoints (conversation analytics, template analytics (Meta), pricing analytics, `/v1/templates/analytics`) take `startDateTimestamp` / `endDateTimestamp` in Unix **seconds**. The range is passed to Meta as-is, so Meta's bucket-alignment and granularity rules apply; a rejected range is `400` with Meta's error in `errorRaw`. `Date.now()` in JS is milliseconds — divide by 1000, nothing corrects it for you.
- Granularity names differ by endpoint: conversation analytics accepts `HALF_HOUR`, `DAILY`, `MONTHLY`; pricing analytics accepts `DAILY`, `MONTHLY`; `/v1/templates/analytics` accepts `HALF_HOUR`, `DAY`, `MONTH`. Meta template analytics has no granularity parameter — buckets are always one day.
- `MONTHLY` buckets come back only for complete calendar months. For the current month, or any partial month, use `DAILY`.
- Daily engagement's `date` is the IST calendar day returned as midnight UTC (`2026-08-03T00:00:00.000Z`); template analytics returns a plain `2026-08-03`.
- Daily engagement accepts at most 366 days per request (`400` beyond that); template analytics by day has no maximum range, long ranges just take longer.

**Organisation scope**

- `pricing-analytics?org=true` reports every business in the organisation; each data point gains a `business` name and `data.errors` lists numbers Meta could not be queried for.
- `cost-analytics?scope=org` adds `businessId` / `businessName` to every `volumeRows` entry, sums `aiUsage` across businesses and adds a `businesses[]` array with one summary per business.
- `cost-analytics/templates` is per business only — `scope=org` returns `400`.
- Org-wide scope requires access to every business in the organisation, otherwise `403`.

**Endpoints that proxy Meta**

- Conversation analytics, template analytics (Meta), pricing analytics and `/v1/templates/analytics` return Meta's payload unchanged inside `data`, so the field names are Meta's and there is no per-recipient detail. They do include sends from other tools connected to the same account.
- Meta template analytics (`/v1/templates/template-analytics`) only returns data for accounts that have template analytics enabled in WhatsApp Manager, and only for the period since it was enabled. `templateId` is the Meta `id` from `GET /v1/templates` (comma-separate several); results page with `limit` (default 500) and `cursor` / `nextCursor`.
- `wabaNumber` means different things: conversation analytics wants the business phone number with country code (`919876543210`); `/v1/templates/analytics` wants the phone number ID (`109876543210987`).
- Pricing analytics: only `pricing_type: "REGULAR"` rows are billable, `tier` appears on billable rows only, and `cost` is present only for accounts billed directly by Meta — accounts billed through a solution provider get volume only.

**Cost analytics**

- Pricing analytics and both cost endpoints need cost visibility enabled on the account; otherwise `404`.
- Cost periods must start on or after `2026-07-01`; an earlier `startDate` → `400`.
- Amounts are INR. AI usage is priced in USD and converted at the `usdToInrRate` in the response; `grandTotalCost = totalMessagingCost + aiUsage.totalCostInr`.
- `volumeSource` says how billable volume was counted: `standard` (from `sent` onwards) or `conservative` (from `delivered` onwards).
- `cost-analytics/templates` is an estimate built from the messages Heltar sent — Meta does not report volume per template, so it cannot be reconciled with the invoice line by line. Each `countryRows` entry is rounded on its own and may differ from the matching `rows` entry by a paisa or two.

**Funnel semantics (template analytics by day)**

- Counts are cumulative down the funnel: `deliveredCount` includes read, responded and clicked; `readCount` includes responded and clicked; `sentCount = totalCount - waitingCount - failedCount`.
- `category` is the one that applied when each message was sent, so a template whose category changed mid-range appears under both categories; `null` when the category was not known at send time.
- Drill down with template message details by passing the same `template_name` and `date`. `templateName` must be URL-encoded. `sent_by_name` is `null` for API and chatbot sends.

## Common gotchas

- Mixing up the two date conventions is the most common `400`: check which group the endpoint belongs to (see Overview) before choosing `startDate` or `startDateTimestamp`.
- `sentCount` / `deliveredCount` / `failedCount` in cost analytics come from a different ledger than the billed `volume` and can differ slightly; they are omitted when the number also sends through another tool.
- Meta template analytics returns `data` as a flat array of data points, while conversation and pricing analytics nest them under `data.<name>.data[].data_points`.

**Rate limits (API keys only)**

- Every endpoint on this page counts against a per-business budget of **60 requests per 15 minutes** for API keys; a `429` carries a `Retry-After` header (seconds). Dashboard sessions are not limited. Cache results and fetch a date range once rather than polling per day.

## Related Skills

- [`heltar-authentication`](../heltar-authentication/SKILL.md) — API keys, Full access vs scoped keys.
- [`heltar-templates`](../heltar-templates/SKILL.md) — `GET /v1/templates` for the template IDs Meta template analytics needs; `GET /v1/templates/analytics` for Meta's per-number sent / delivered counts.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — per-campaign counts, per-recipient status and export.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
