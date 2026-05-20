---
name: heltar-contacts
description: 'Create, update, list, and delete WhatsApp contacts (clients) on Heltar. Manage attributes, tags, agent assignment, chat open/close state, and per-contact bot toggles. Use when syncing customers, segmenting, routing chats, or controlling bot behavior at the contact level.'
metadata:
  author: Heltar
  version: 0.1.0
  category: CRM
  tags: contacts, clients, attributes, tags, assignment, opt-in, bot-toggle, chat-toggle
  uses:
    - heltar-authentication
---

# Heltar Contacts

## Overview

A "contact" (called _client_ in the API) represents one WhatsApp number you can converse with. Contacts are auto-created the first time a message is sent or received, but you can also create them proactively in bulk with custom attributes for segmentation.

## Agent Instructions

Match user intent:

| User intent                                     | Endpoint                                                                            |
| ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| Bulk create / upsert contacts (e.g. CSV import) | `POST /v1/clients` (array body)                                                     |
| List all contacts                               | `GET /v1/clients?limit=&offset=&search=`                                            |
| Look up one contact                             | `GET /v1/clients/:clientWaNumber`                                                   |
| Bulk delete                                     | `DELETE /v1/clients` (array body)                                                   |
| Update attributes / tags only                   | `PUT /v1/clients/attributes-and-tags`                                               |
| Open or close a chat                            | `PUT /v1/clients/chat/toggle/:clientWaNumber`                                       |
| Assign chat to an agent                         | `POST /v1/clients/chat/assign`                                                      |
| Enable / disable bot for one contact            | `PUT /v1/clients/bot/toggle/:clientWaNumber`                                        |
| Pin a specific bot to a contact                 | `PUT /v1/clients/bot/assign` (see [`heltar-chatbots`](../heltar-chatbots/SKILL.md)) |

> **`POST /v1/clients` is upsert**, not strict create. Sending an existing `clientWaNumber` updates the row.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

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
      "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\"}",
      "assignTo": "agent@company.com"
    }
  ]'
```

> **`attributes` is a JSON string**, not an object — exactly one level of stringification. Use `JSON.stringify({...})` in JS.

The companion `PUT /v1/clients/attributes-and-tags` endpoint takes attributes as a real **object** plus a `tags` array — different shape, different purpose (partial update without touching name/agent).

## Important fields

| Field                    | Type                              | Meaning                                                                  |
| ------------------------ | --------------------------------- | ------------------------------------------------------------------------ |
| `clientWaNumber`         | string                            | International digits, no `+`                                             |
| `attributes`             | JSON string (POST) / object (PUT) | Custom data for segmentation                                             |
| `isOpen`                 | boolean                           | Chat open in inbox                                                       |
| `isBotReply`             | boolean                           | Bot is enabled for this contact                                          |
| `optedIn`                | boolean                           | Marketing opt-in — **filter on this** before building campaign audiences |
| `conversationExpire`     | ISO 8601                          | When the 24-hour window closes — past this, only templates can initiate  |
| `unreadMessages`         | number                            | Unread count                                                             |
| `latestMessageTimestamp` | ISO 8601                          | Last activity                                                            |

## Pagination

`GET /v1/clients?limit=50&offset=0&search=john`. `limit` max 100. `search` matches name or number.

## Common gotchas

- Forgetting to stringify `attributes` on `POST /v1/clients` → 400.
- Using `+91…` instead of `91…` → contact created with the wrong number, future messages fail.
- Toggling `isOpen: false` doesn't pause webhooks — it just collapses the chat in the inbox UI. To stop the bot from replying, also toggle `isBotReply: false`.
- Bulk delete is permanent and cascades the conversation history.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
