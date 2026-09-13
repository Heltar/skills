---
name: heltar-link-tracker
description: 'Create short, trackable links on Heltar, one at a time or in bulk, and list every tracked link in the account, with static or dynamic redirects and optional branded domains. Use when shortening URLs for WhatsApp messages or template buttons, attributing clicks to a recipient or campaign, or auditing existing short links.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Integrations
  tags: link-tracker, short-links, tracked-links, click-tracking, redirect, custom-domain, bulk
  uses:
    - heltar-authentication
---

# Heltar Link Tracker

## Overview

Turn any URL into a short, trackable link. Put the short link in a template button, a message body, or anywhere else; every click by a real visitor is recorded with browser, operating system, device type, referrer and IP-derived location.

The same short links are generated automatically when you send a template whose URL button uses a link tracker URL type. The endpoints here let you create and list links yourself, outside of a template send.

## Agent Instructions

Match user intent:

| User intent                                                             | Endpoint                                                                                                                    |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Shorten one URL                                                         | `POST /v1/link-tracker/create`                                                                                              |
| Shorten many URLs in one request (one per order / recipient)            | `POST /v1/link-tracker/create-bulk`                                                                                         |
| List every tracked link (API-created and template-generated)            | `GET /v1/link-tracker`                                                                                                      |
| Turn automatic shortening in template sends on or off                   | `PUT /v1/business/link-tracking` — see [`heltar-business`](../heltar-business/SKILL.md)                                     |
| Serve short links from a branded domain (`https://links.yourbrand.com`) | `PUT /v1/business/custom-domain-for-redirection` + [custom domain guide](./references/guides/link-tracker-custom-domain.md) |
| See click counts / analytics for a link                                 | No API: dashboard **Integrations -> Link Tracker** (select a link)                                                          |

Decide up front:

1. **`static` or `dynamic` redirect?** `static` (default) is a plain HTTP redirect; the visitor lands on the destination URL. `dynamic` serves the destination from the short URL so the short URL stays in the address bar.
2. **Single or bulk?** Single create is idempotent per destination (re-sending the same URL returns the existing code); bulk always mints a new code per entry.
3. **Need attribution?** Append `/<identifier>/<group>` to the short URL (e.g. `/aB3xY9kQ/919876543210/summer-sale`) to record who clicked and which campaign it belonged to.

For full request / response shapes read `references/api-reference.md` instead of pasting it.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

`/v1/link-tracker/*` is **outside the per-resource scope picker**: use a key created with the **Full access** preset, or **Read-only** for `GET /v1/link-tracker`. A key that does not cover the endpoint gets `403`.

## Quick Start — create one link

```bash
curl -X POST "$API_URL/v1/link-tracker/create" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "destinationLink": "https://www.example.com/offers/summer-sale",
    "hashLength": 8
  }'
```

The response carries `data.dataHash` (e.g. `aB3xY9kQ`). Build the short URL by appending it to your tracker domain: `$API_URL/aB3xY9kQ` by default, or `https://links.yourbrand.com/aB3xY9kQ` on a custom domain.

## Quick Start — create links in bulk

```bash
curl -X POST "$API_URL/v1/link-tracker/create-bulk" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "destinationLinks": [
      "https://www.example.com/orders/12345",
      "https://www.example.com/orders/12346"
    ],
    "hashLength": 8
  }'
```

`data[]` keeps the order of `destinationLinks`; each entry has `mainUrl`, `hash` and a ready-made `redirectLink`.

## Key Rules

- **`hashLength` is required** on both create endpoints (a number, or a numeric string). It is the length of the generated code, letters and digits only; `8` to `12` is a good range. Missing or non-numeric → `400`. If the generated code collides with an existing one you get `409`: retry, or use a longer `hashLength`.
- **`redirectType`**: `static` (default) = HTTP redirect to the destination. `dynamic` = the platform fetches the destination on the visitor's behalf and serves that response from the short URL; if the destination itself redirects, the visitor is forwarded there. Anything other than these two values → `400`. In bulk it applies to every link in the request.
- **Single create is idempotent per destination.** If a link already exists for the same `destinationLink` in your account, the existing short code is returned and no new link is created; `hashLength` and `redirectType` are ignored in that case. **Bulk create never reuses** an existing link; every entry gets a new code.
- `destinationLink` / each `destinationLinks[]` entry must be a **full URL with a scheme** (`https://…`), otherwise `400`. Do not point a tracked link at another tracked link.
- The bulk `redirectLink` is built on the host you sent the request to. On a custom domain, swap the host yourself (`https://links.yourbrand.com/<hash>`).
- **Attribution path segments** are optional: `/<code>/<identifier>/<group>`. The first segment is stored as the click identifier (e.g. the recipient's phone number), the second as its group (e.g. a campaign ID). Links generated during a template send get these values from the message automatically.
- **Only real visitors count.** Link previews, search crawlers, scripted HTTP clients and `HEAD` requests are still redirected but not recorded, so WhatsApp's own preview does not inflate numbers.
- **No click analytics in the list endpoint.** `GET /v1/link-tracker` is paginated: `limit` (default 100, max 500) and `cursor` (the `nextCursor` of the previous page, an id); it returns `{ links, nextCursor }` newest first with `id`, `hash`, `destinationLink`, `redirectType`, `businessId`, `messageWamid` and `createdAt` — no filters, no click counts. Stop paging when `nextCursor` is `null`. API keys get 60 calls per 15 minutes on this endpoint. Per-link click analytics live in the dashboard under **Integrations -> Link Tracker**.
- **Links created through this API are not tied to a message** (`messageWamid` is `null`), so clicking them never changes a message status. Links generated for a template message are tied to it: the first click moves the message to `clicked` (or `clicked_responded` if the contact had already replied) and is counted in campaign stats as `statsClicked` / `statsClickedResponded`. Later clicks are recorded but do not change the status again.
- **The link tracking toggle lives on the Business page** (`PUT /v1/business/link-tracking`, or **Settings -> Template Link Tracker** in the dashboard). It only decides whether template sends shorten URLs; the endpoints here and the redirects themselves work regardless of that toggle.
- **Custom domain** needs both the business setting (`PUT /v1/business/custom-domain-for-redirection`) and DNS + certificate pointing at the link tracker. Follow [`references/guides/link-tracker-custom-domain.md`](./references/guides/link-tracker-custom-domain.md).
- Opening a short URL whose code does not exist returns `404`. `401` = missing / invalid / expired / revoked key.

## Related Skills

- [`heltar-authentication`](../heltar-authentication/SKILL.md) — API keys and the Full access / Read-only presets.
- [`heltar-business`](../heltar-business/SKILL.md) — link tracking toggle and custom domain setting.
- [`heltar-templates`](../heltar-templates/SKILL.md) — URL buttons that get shortened automatically when link tracking is on.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — `statsClicked` / `statsClickedResponded` in campaign statistics.
- [`heltar-messaging`](../heltar-messaging/SKILL.md) — the `clicked` / `clicked_responded` message statuses.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
- Custom domain setup: [`references/guides/link-tracker-custom-domain.md`](./references/guides/link-tracker-custom-domain.md)
