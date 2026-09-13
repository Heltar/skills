---
name: heltar-business
description: 'Check the health of a WhatsApp Business account on Heltar (connection status, quality rating, messaging limit, can-send verdict), set opt-in / opt-out keyword rules such as STOP and START, and read or change account-level settings: business details, WhatsApp profile, commerce, link tracking, custom link domain, data localization, read receipts, async send mode, outgoing rate limit, web widget origins, coexistence sync, phone registration, webhook subscription and journey events. Use when a user asks whether their number can send, why sends are limited, how contacts unsubscribe and what happens to them, or how to configure their account.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Account
  tags: business, account-status, health, quality-rating, messaging-limit, opt-in, opt-out, unsubscribe, profile, settings, commerce, link-tracking, custom-domain, data-localization, async-mode, rate-limit, web-widget-origins, coexistence, journeys
  uses:
    - heltar-authentication
---

# Heltar Business

## Overview

The Business API is the account-level surface: the live health of your WhatsApp Business account as Meta reports it, the keyword rules that let contacts opt out of (and back into) your messages, your business details, and the per-business switches that change how messages are sent (link tracking, read receipts, async mode, outgoing rate limit, and so on).

The two most used endpoints are **Account Status** and **Opt-in / Opt-out Rules**. Everything else is configuration you set once.

## Agent Instructions

Match user intent:

| User intent                                                                                                            | Endpoint                                                |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| "Can my number send right now?" / check connection status, quality rating, messaging limit tier, display name approval | `GET /v1/business/account-status?fields=…`              |
| Same, for every business in the organisation in one call                                                               | `GET /v1/business/account-status?scope=org&fields=…`    |
| Let contacts unsubscribe / re-subscribe by replying a keyword (STOP / START), send an opt-out confirmation             | `PUT /v1/business/opt-rules`                            |
| Read current opt rules, business ID, WABA ID, phone number ID, webhooks, other settings                                | `GET /v1/business`                                      |
| Read the WhatsApp business profile (about, address, email, websites, category, picture)                                | `GET /v1/business/profile`                              |
| Update the WhatsApp business profile                                                                                   | `POST /v1/business/profile`                             |
| Read catalog / cart visibility                                                                                         | `GET /v1/business/commerce`                             |
| Turn the catalog and cart on or off                                                                                    | `POST /v1/business/commerce`                            |
| Turn automatic link tracking in template sends on or off                                                               | `PUT /v1/business/link-tracking`                        |
| Serve tracked links from a branded domain                                                                              | `PUT /v1/business/custom-domain-for-redirection`        |
| Where does Meta store my conversation data                                                                             | `GET /v1/business/data-localization-region`             |
| Pin data storage to a country, or return to Meta's default                                                             | `PUT /v1/business/data-localization-region`             |
| Stop / start sending read receipts (blue ticks) when replying                                                          | `PUT /v1/business/mark-read-access`                     |
| Make API sends queue and return immediately (async mode)                                                               | `PUT /v1/business/async-message-mode`                   |
| Cap messages per second sent to WhatsApp for campaigns and queued sends                                                | `PUT /v1/business/meta-api-calls-per-second`            |
| Allowlist the websites that may load the web chat widget                                                               | `PUT /v1/business/web-widget/origins`                   |
| Import contacts or chat history from the WhatsApp Business app (coexistence)                                           | `POST /v1/business/coexistence-sync`                    |
| Re-register a deregistered number with the Cloud API                                                                   | `POST /v1/business/register-phone-number`               |
| Messages stopped arriving after a change on the Meta side                                                              | `POST /v1/business/subscribe-webhook`                   |
| Fire a business event (`added_to_cart`, `checkout_complete`) into journeys                                             | `POST /v1/journeys/events`                              |
| Claim a searchable username / manage webhook URLs / call settings / pause marketing templates                          | Not on this page: see [Related Skills](#related-skills) |

For the two most common questions, answer in this order:

1. **"Can I send / why are my sends limited or failing?"** Call account status with at least `status,quality_rating,throughput,health_status,whatsapp_business_manager_messaging_limit`. Read `health_status.can_send_message` first (`AVAILABLE`, `LIMITED`, `BLOCKED`), then `health_status.entities[].errors[]` for Meta's `error_description` and `possible_solution`. If the phone number entity looks fine but sends still fail, repeat with `isDetailed=true` to see the WABA, business and app entities.
2. **"How do I let people unsubscribe?"** Set the rules with `PUT /v1/business/opt-rules`, confirm them with `GET /v1/business` (`data.integrations.optRules`), and explain what happens to opted-out contacts (see Key Rules). The `optedIn` flag itself is read on the [Contacts API](../heltar-contacts/SKILL.md).

Generate minimal examples; for full request/response shapes and every field, read `references/api-reference.md` instead of pasting it.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

- `/v1/business/*` endpoints are **outside the per-resource scope picker**: use a key created with the **Full access** preset, or **Read-only** for the `GET` endpoints. A Read-only key on a write endpoint returns `403 API key does not have the required scope (business:write)`.
- `POST /v1/journeys/events` is different: it is covered by the `journeys` resource and needs the `journeys:write` scope (or Full access).

## Quick Start — check account health

```bash
curl -X GET "$API_URL/v1/business/account-status?fields=status,quality_rating,throughput,health_status,whatsapp_business_manager_messaging_limit,display_phone_number,verified_name,name_status,business_verification_status" \
  -H "Authorization: Bearer $HELTAR_API_KEY"
```

Read the response like this:

| Field                                       | Healthy value | Meaning                                                                                                                             |
| ------------------------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `health_status.can_send_message`            | `AVAILABLE`   | Overall verdict. `LIMITED` = can send with restrictions, `BLOCKED` = cannot send. `entities[].errors[]` says why.                   |
| `status`                                    | `CONNECTED`   | Also `DISCONNECTED`, `FLAGGED`, `RESTRICTED`, `PENDING`, `RATE_LIMITED`, `MIGRATED`, `BANNED`, `DELETED`, `UNKNOWN`.                |
| `quality_rating`                            | `GREEN`       | `YELLOW` (medium), `RED` (low) or `UNKNOWN`. A low rating can reduce the messaging limit.                                           |
| `whatsapp_business_manager_messaging_limit` | tier          | Unique customers you can start marketing conversations with per rolling 24 h: `TIER_1K`, `TIER_10K`, `TIER_100K`, `TIER_UNLIMITED`. |
| `throughput.level`                          | `STANDARD`    | Messages per second Meta allows: `STANDARD`, `HIGH` or `NOT_APPLICABLE`.                                                            |
| `name_status`                               | `APPROVED`    | Display name review state. `business_verification_status` is the Meta business verification state.                                  |

Add `&scope=org` to get an array with one entry per business (each stamped with `business_id` and `business_name`), and `&isDetailed=true` to include the WABA, business and app entities under `health_status.entities`.

## Quick Start — set STOP / START opt rules

```bash
curl -X PUT "$API_URL/v1/business/opt-rules" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
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

From then on every inbound WhatsApp message from a contact is checked against these rules. `templatePayload` is optional; omit it to send no confirmation.

## Key Rules

### Account status

- `fields` is **required**. It is a comma-separated list; if you omit it, `data` comes back empty. Phone-number fields and WABA fields (`business_verification_status`, `marketing_messages_lite_api_status`, `subscribed_apps`, `phone_numbers`, …) can be mixed in one request.
- Values are Meta's own and are returned exactly as reported. Meta may add new values; treat an unknown value as "check the dashboard" rather than failing hard.
- Field groups are fetched separately. If one group fails, the rest is still returned and the failures are listed in `data.partialErrors[]` (`source` is `phone_number`, `waba` or `waba_<field>`). Only when nothing at all could be fetched does the request fail with `400 Failed to fetch meta acount health status!`.
- `scope=org` needs the business to belong to an organisation (`400 Business has no orgId` otherwise) and is not available for every session type (`403`). A business whose fetch failed entirely comes back as `{ business_id, business_name, error }`; each business gets up to 15 seconds.
- To confirm the platform is subscribed to your account's webhooks, request `fields=subscribed_apps`.

### Opt-in / opt-out rules

- `optOutRules` and `optInRules` are both **required** arrays and the whole set is **replaced on every call**, so always send the complete configuration. `[]` disables that direction: an empty `optInRules` means an opted-out contact can never opt back in by keyword, so only do that on purpose.
- Every rule needs all three keys: `condition` (`isEqualTo`, `contains`, `startsWith`, `endsWith`), a non-empty `value`, and `nextIs` (`AND` or `OR`, ignored on the last rule). Anything else is a `400`.
- **Case-insensitive and trimmed.** Message text and rule values are trimmed and lower-cased before comparison, so `STOP`, `stop` and `Stop` match. Punctuation is **not** stripped: `isEqualTo` `STOP` does not match `STOP.`; use `startsWith` or `contains` for that.
- **`nextIs` chains left to right with no precedence**: `((rule1 op1 rule2) op2 rule3)`, where each rule is combined with the running result using the `nextIs` of the rule before it. For "match any keyword" keep every `nextIs` as `OR`; use `AND` only for two conditions on the same message (e.g. `startsWith "stop"` AND `contains "marketing"`).
- **Only one rule set applies per message.** Opted-in contact: only `optOutRules` are evaluated. Opted-out contact: only `optInRules`. An opted-in contact sending `START` changes nothing, and an opted-out contact sending `STOP` changes nothing.
- **Which text is checked:** the body of a text message, the caption of an image / video / document, or the label of the tapped button / list option. Media without a caption, locations, contacts, reactions and stickers are never evaluated.
- A match only flips the contact's `optedIn` flag. The message itself still appears in the inbox and still reaches your webhooks and chatbot.
- **Confirmation template** (`templatePayload`): sent immediately after an opt-out match, never on opt-in. `templateName` + `languageCode` must identify one of your approved templates; it is sent without variable values, so use a template with no placeholders. If the template does not exist nothing is sent but the opt-out still happens. Delivery is best-effort and a failure does not undo the opt-out. It is the one message still delivered after opt-out.
- **What happens to an opted-out contact** (applies at send time, so a campaign scheduled earlier still skips them):
  - Campaigns and bulk template sends: the contact is **skipped**, nothing goes to WhatsApp and nothing is charged. The skipped message is recorded as `failed` with reason `Client did not opt-in`, so it appears in the campaign's failed count and in message webhooks like any other failure.
  - Single template send via `POST /v1/messages/send`: the request succeeds but the message is recorded as `failed` with reason `Client has not opted in` and is not sent.
  - Session messages (text, media, interactive, location, contacts) via `POST /v1/messages/send`: rejected with `400 Client has not opted in`.
  - The Contacts API returns `"optedIn": false`. The contact can still message you and you still receive everything they send.
- **Opting back in is keyword-only.** The `optedIn` flag cannot be set through the API; the contact must send a message matching `optInRules`. Make the opt-out confirmation say which keyword to reply with ("Reply START to subscribe again").
- Meta requires you to honour opt-out requests for marketing messages, and blocks / reports lower your quality rating. Keep `STOP` and `UNSUBSCRIBE` in `optOutRules` at all times.

### Business details and profile

- `GET /v1/business` returns `id` (your business ID, used as `business_id` in org-level operations), `businessAccountId` (WABA ID), `phoneNumberId`, `bizWhatsappNumber`, and `integrations` (only keys that have been set: `optRules`, `isLinkTrackingEnabled`, `customDomainForRedirection`, `metaApiCallsPerSecond`, `pauseMarketingTemplates`, `coexistence`, …). `bizAttributes` / `bizAttributesType` are JSON-encoded strings. Webhook header values are masked to their last 5 characters and the Meta access token is never returned (`isFbAccessToken` only says whether one is stored).
- `GET /v1/business/profile` returns `data` as a **one-element array**; `profile_picture_url` is a temporary Meta URL, fetch again when you need a fresh one.
- `POST /v1/business/profile` changes only the fields you send. Limits: `about` 1–139 chars, `address` ≤ 256, `description` ≤ 512, `email` ≤ 128, `websites` ≤ 2 URLs of ≤ 256 chars, `vertical` from the fixed category list. `profile_picture_handle` comes from the media upload endpoint on the [Templates](../heltar-templates/SKILL.md) page. `400 Business details are missing…` means the number is not fully connected yet.

### Commerce, link tracking, data localization

- Commerce: `is_cart_enabled` and `is_catalog_visible` are **both required** on every `POST`. The `GET` response is Meta's payload as-is; the settings object is at `data.data[0]`. A `400` on either call usually means no catalog is connected.
- `PUT /v1/business/link-tracking` only decides whether template sends shorten URLs. Creating links yourself is on [`heltar-link-tracker`](../heltar-link-tracker/SKILL.md).
- `customDomainForRedirection` is a full origin with scheme (`https://links.acme.com`); `""` clears it. Setting it is half the job: the domain also needs DNS and a certificate pointing at the link tracker — follow the [Custom Domain for Link Tracker guide](../heltar-link-tracker/references/guides/link-tracker-custom-domain.md).
- Data localization: `dataLocalizationRegion` is a two-letter uppercase ISO code or `null` to clear. `GET` returns `status` `default` (region `null`) or `in_country_storage_enabled`. Any two uppercase letters pass validation; Meta returns `400 Failed to update data localization region on Meta.` for a region it does not support.

### Messaging behaviour

- **Read receipts** (`isMarkRead`, required): enabled by default. When on, the contact's latest received message is marked read whenever you send them a session message from the API or inbox; when off, no read receipts are sent at all.
- **Async message mode** (`asyncMessageMode`, required): disabled by default. When on, `POST /v1/messages/send` returns as soon as messages are queued with a platform `hemid` per message; the `wamid` and delivery statuses arrive later through webhooks. Applies to API-key requests only; dashboard sends stay synchronous. Recommended for high-volume senders. Look messages up by `hemid` via [`heltar-messaging`](../heltar-messaging/SKILL.md).
- **Outgoing rate limit** (`metaApiCallsPerSecond`, required): 1–1000, default 75 when never set; applies to campaigns and queued API sends. Match it to `throughput.level` from account status; setting it above the number's real limit does not speed anything up, WhatsApp starts rejecting with rate-limit errors.

### Web widget origins, Meta account operations, journeys

- `origins` (required) replaces the whole allowlist: up to 50 entries, each an exact origin (`https://acme.com`, optional port) or a wildcard subdomain pattern (`https://*.acme.com`). Scheme is part of the match (`https://` does not allow `http://`), the wildcard needs at least one label (`https://acme.com` does not match `https://*.acme.com`), hosts match case-insensitively, entries are trimmed / de-duplicated / stripped of trailing slashes. An empty list disables the widget; a non-listed origin gets `403`. Embedding is covered by [`heltar-web-widget`](../heltar-web-widget/SKILL.md).
- Coexistence sync: `syncType` is `smb_app_state_sync` (contacts + current app state) or `history` (chat history). The sync runs asynchronously and history only arrives if the WhatsApp Business app user agreed to share it. `400 Coexistence is not enabled for this business!` if the number is not set up for coexistence.
- Register phone number: `pin` is optional and must be exactly 6 digits (`400 Pin must be 6 digits long`); omitted means the platform's default PIN. If two-step verification is on with a different PIN, Meta rejects it (`400 Failed to register phone number!`, details in `errorRaw`).
- Subscribe webhook: no body, harmless to repeat. `400 Business Account ID or FB Access Token is missing!` means the number is not connected yet.
- Journey events: `event` is `{ "name", "properties" }` and **no other keys** are allowed inside it. `phone` (digits with country code, normalised before matching) or `email` (case-insensitive) is required. An unknown person is created, so you can post events for people who never messaged you; `masterClientId` in the response is that person. Without `journeyId` the event fans out to every journey in the organisation listening for `event.name` for this business; with it, only that journey (`404 Journey not found` if it is not yours). `journeys: []` in the response means nothing is listening. Processing is asynchronous; `properties` reach the journey code unchanged. Journeys are built in the code editor, see [`heltar-code-editor`](../heltar-code-editor/SKILL.md).

## Related Skills

- [`heltar-authentication`](../heltar-authentication/SKILL.md) — API keys and the Full access / Read-only presets.
- [`heltar-contacts`](../heltar-contacts/SKILL.md) — the `optedIn` flag on each contact and custom attribute definitions.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — opted-out recipients show up as `failed` in campaign stats.
- [`heltar-messaging`](../heltar-messaging/SKILL.md) — `hemid` lookup in async mode, session sends rejected for opted-out contacts.
- [`heltar-templates`](../heltar-templates/SKILL.md) — the confirmation template must be approved; media upload for profile picture handles; pausing marketing templates.
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — add / update / remove webhook URLs; where async statuses arrive.
- [`heltar-link-tracker`](../heltar-link-tracker/SKILL.md) — create and list tracked links; custom domain guide.
- [`heltar-web-widget`](../heltar-web-widget/SKILL.md) — embed the widget once origins are allowlisted.
- [`heltar-code-editor`](../heltar-code-editor/SKILL.md) — journeys are built there and declare their trigger events.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
