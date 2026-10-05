---
name: heltar-contacts
description: 'Create, update, list, filter, and delete WhatsApp contacts (clients) on Heltar. Manage attributes and attribute definitions, tags, agent assignment, chat open/close state, blocking, per-contact bot toggles, and the unified customer profile. Use when syncing customers, segmenting, routing chats, blocking spam, or controlling bot behavior at the contact level.'
metadata:
  author: Heltar
  version: 0.1.0
  category: CRM
  tags: contacts, clients, attributes, attribute-definitions, tags, assignment, multiassign, block, profile, opt-in, bot-toggle, chat-toggle
  uses:
    - heltar-authentication
---

# Heltar Contacts

## Overview

A "contact" (called _client_ in the API) represents one channel thread you can converse with — usually a WhatsApp number. Contacts are auto-created the first time a message is sent or received, but you can also create them proactively in bulk with custom attributes for segmentation. The **unified profile** is the person behind one or more threads (WhatsApp, RCS, web chat), with its own email, primary phone, and attributes.

## Agent Instructions

Match user intent:

| User intent                                                  | Endpoint                                                                                |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| Bulk create / upsert contacts (e.g. CSV import)              | `POST /v1/clients` (array body)                                                         |
| List / filter contacts (keyset paginated)                    | `GET /v1/clients?cursor=&limit=&tags=&isOpen=&unread=&assigned=&isBotReply=`            |
| Look up one contact                                          | `GET /v1/clients/:clientWaNumber`                                                       |
| Read one contact's attributes as parsed JSON                 | `GET /v1/clients/client-attributes/:clientWaNumber`                                     |
| Bulk delete                                                  | `DELETE /v1/clients` with `{ "clientWaNumbers": [...] }`                                |
| Update attributes / tags only                                | `PUT /v1/clients/attributes-and-tags` (array body)                                      |
| List / create / rename-retype / delete attribute definitions | `GET` / `POST` / `PUT` / `DELETE /v1/business/attributes` (Full-access key)             |
| Open or close a chat                                         | `PUT /v1/clients/chat/toggle/:clientWaNumber`                                           |
| Assign chat to one agent, or auto-assign                     | `POST /v1/clients/chat/assign` (`email`; omit it to auto-assign)                        |
| Assign chat to several agents, or unassign everyone          | `POST /v1/clients/chat/multiassign` (`emails[]`; `[]` unassigns)                        |
| Block / unblock a contact                                    | `PUT /v1/clients/chat/block/:clientWaNumber`                                            |
| List blocked contacts                                        | `GET /v1/clients/blocked`                                                               |
| Enable / disable bot for one contact                         | `PUT /v1/clients/bot/toggle/:clientWaNumber`                                            |
| Pin a specific bot to a contact / clear its bot memory       | see [`heltar-chatbots`](../heltar-chatbots/SKILL.md)                                    |
| Read the person behind a contact (all channel threads)       | `GET /v1/clients/:clientWaNumber/profile`                                               |
| Set profile email / primary phone / profile attributes       | `PUT /v1/clients/:clientWaNumber/profile`                                               |
| Stop a hidden-number contact's phone appearing in webhooks   | `DELETE /v1/clients/:clientWaNumber/contact-book` (user ID `BD.…`, not a phone number)  |
| Check marketing opt-in                                       | Read `optedIn` on any contact response — **read-only**; rules live in `heltar-business` |

> **`POST /v1/clients` is upsert**, not strict create. Sending an existing `clientWaNumber` updates the row and merges `attributes` into the existing set.

## Authentication

Bearer API key. `GET` requests need the `clients:read` scope, every other method `clients:write`. `/v1/business/attributes` is outside the per-resource scope picker — use a **Full access** key (or **Read-only** for `GET`). See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Quick Start — bulk upsert with custom attributes

```bash
curl -X POST "$API_URL/v1/clients" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "clientWaNumber": "919876543210",
      "username": "John Doe",
      "countryCode": 91,
      "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\",\"tags\":[\"vip\"]}",
      "assignTo": "agent@company.com"
    }
  ]'
```

> **`username`, `countryCode`, and `attributes` keys are all required** on every entry. Send `username: ""` to keep an existing name, `countryCode: null` to derive it from the number. `attributes` is a JSON string (a JSON object is also accepted) — use `JSON.stringify({...})` in JS. Put a `tags` array inside `attributes` to set tags. `assignTo` must be an agent's email in this business.

The companion `PUT /v1/clients/attributes-and-tags` endpoint takes `attributes` as a real **object** plus a `tags` array — different shape, different purpose: attributes are merged, `tags` **replaces** the contact's whole tag list, and name/agent are untouched.

## Important fields

| Field                    | Type                                         | Meaning                                                                                                                                    |
| ------------------------ | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `clientWaNumber`         | string                                       | International digits, no `+` (`+`, spaces, dashes are stripped). Also a `BD.…` WhatsApp user ID, `…@rcs`, `<visitorId>@web`, or a group ID |
| `attributes`             | JSON string (POST, responses) / object (PUT) | Custom data for segmentation; includes the `tags` array                                                                                    |
| `isOpen`                 | boolean                                      | Chat open in inbox                                                                                                                         |
| `isBotReply`             | boolean                                      | Bot is enabled for this contact                                                                                                            |
| `optedIn`                | boolean                                      | Marketing opt-in — **read-only**; filter on this before building campaign audiences                                                        |
| `isBlocked`              | boolean                                      | Contact is blocked                                                                                                                         |
| `businessEmployees`      | array                                        | Assigned agents as `{ id, name, email }`; empty when unassigned                                                                            |
| `unreadMessages`         | number                                       | Unread count; `-1` when the chat was manually marked unread                                                                                |
| `conversationExpire`     | ISO 8601                                     | When the 24-hour window closes — past this, only templates can initiate                                                                    |
| `latestMessageTimestamp` | ISO 8601                                     | Last activity; `null` for a contact that has never exchanged a message                                                                     |
| `masterClientId`         | string                                       | Unified profile the contact is linked to, or `null`                                                                                        |

## Pagination and filters

`GET /v1/clients?limit=500`. Keyset pagination — the response's `data.nextCursor` is passed back as `cursor`; iteration ends when `nextCursor` is `null`. Without filters the default and maximum `limit` are **5000**; with any filter set the default is **500** and the maximum **1000**.

Filters are AND-ed: `tags` (repeat the parameter — `?tags=vip&tags=newsletter`; ALL must match; up to 20 tags), `isOpen`, `unread=true`, `assigned`, `isBotReply`. `view=your` always returns an empty page for an API key. Filters only match contacts that have a chat. Chat-having contacts come first (newest message first), then never-messaged contacts (created via API / bot-assign) fill the remainder; the phase transition is tracked inside the cursor. Blocked contacts are removed from every page, so a page can be short while `nextCursor` is still set. An invalid filter value (`isOpen=yes`) → 400.

Full-text contact search is intentionally not supported here — use `GET /v1/clients/:clientWaNumber` for exact lookup, or the message search in [`heltar-messaging`](../heltar-messaging/SKILL.md).

## Attribute definitions

Every attribute key has a business-level definition (`fieldKey` + `dataType`): `text`, `numerical`, `dropdown` (`dropdownOptions`), or `tags` (`tagOptions`). Contact values are validated against it (`dropdown` must be one of the options, `tags` an array of known options; mismatch → 400). Unknown keys are auto-created as `text`, and unknown tag values are appended to `tagOptions` (up to 500 options of ≤120 chars). Define an attribute first with `POST /v1/business/attributes` when you need `numerical` / `dropdown` / `tags`, or `PUT` to rename or retype one that was auto-created as `text` (stored values are converted). `tags` is reserved — it cannot be created or deleted, only its `tagOptions` changed via `PUT`. Duplicate `fieldKey` on `POST` → 409. `DELETE ?attribute=` removes the key from every contact.

## Key Rules / Gotchas

- `POST /v1/clients`: if any contact fails, the response is 400 with `errorRaw.successfulClients` / `failedClients` — the valid ones are still saved. When `countryCode` is given, the number is validated against it. Numbers are de-duplicated within the request; `id` for newly created contacts is a placeholder — read the contact back for the permanent one.
- Always include the country code in `clientWaNumber`; the `+` is optional because it is stripped.
- `DELETE /v1/clients` is permanent. `notDeleted` lists numbers that still exist; a number that never existed counts as deleted.
- `PUT /v1/clients/attributes-and-tags`: each entry needs `attributes`, `tags`, or both. 200 if at least one entry succeeded (per-entry `success`/`error` in `results`); 400 with the same `results` in `errorRaw` when every entry fails.
- Toggling `isOpen: false` only changes the inbox state. To stop the bot from replying, use the bot toggle. Disabling the bot discards any flow the contact was in the middle of and is logged as a private note; it is refused (400) while a Meta AI agent is handling the chat.
- Assign: `email` must be an agent of your organisation (400 `agent@company.com not exists!`); omitting it auto-assigns to an active agent (400 `No active employee found to assign chat!` if nobody is online). Multiassign: any unknown email → 400 with `errorRaw.emails`, nothing changes.
- Block: WhatsApp accepts the block only within 24 hours of the contact's last message; otherwise it is saved and applied on their next message. While blocked: excluded from `GET /v1/clients`, template sends are recorded as failed (`Client is blocked`), other sends → 400.
- `optedIn` cannot be set through the API — `POST` ignores it, `PUT attributes-and-tags` stores it as a plain attribute, profile `PUT` rejects it. It changes only when the contact's inbound message matches your opt-out / opt-in keyword rules (`PUT /v1/business/opt-rules`, see [`heltar-business`](../heltar-business/SKILL.md)). Opted-out contacts: template sends are recorded as failed (`Client has not opted in`; `Client did not opt-in` in campaigns), other message types → 400, and bots do not reply.
- Unified profile: profile `attributes` are separate from contact attributes and not validated against definitions. `GET` never 404s (`masterClientId: null`, empty `channels` when none). On `PUT`, an `email` / `primaryPhone` already on another profile merges this contact's threads into it; unknown body fields → 400.

## Related Skills

- [`heltar-messaging`](../heltar-messaging/SKILL.md) — send to a contact, read history, search messages.
- [`heltar-campaigns`](../heltar-campaigns/SKILL.md) — build audiences from `optedIn` / `isBlocked` / tags.
- [`heltar-chatbots`](../heltar-chatbots/SKILL.md) — pin a bot to a contact, clear its session.
- [`heltar-business`](../heltar-business/SKILL.md) — opt-in/opt-out keyword rules, account status, settings.
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — inbound messages and status updates per contact.
- [`heltar-analytics`](../heltar-analytics/SKILL.md) — engagement and conversation analytics.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
