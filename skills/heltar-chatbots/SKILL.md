---
name: heltar-chatbots
description: "Activate, trigger, assign, and test Heltar chatbots — both text and voice. Use when proactively starting a bot conversation, assigning a specific bot to a contact, clearing a bot's memory, or running test inferences without sending WhatsApp messages."
metadata:
  author: Heltar
  version: 0.1.0
  category: Automation
  tags: chatbot, voice-bot, talk, assign, session, process, openai-format
  uses:
    - heltar-authentication
---

# Heltar Chatbots

## Overview

Chatbots run automated conversations on top of the inbox. Each business has an **active text bot** and an **active voice bot**; individual contacts can override with their own assignment. The Chatbot API lets you change those assignments, trigger a bot to start talking proactively, reset its memory, or run an off-WhatsApp inference for testing.

## Agent Instructions

Match the user's intent to the right endpoint — these are not interchangeable:

| User intent                                                   | Endpoint                                                    |
| ------------------------------------------------------------- | ----------------------------------------------------------- |
| "Make this bot the default for the business"                  | `POST /v1/chatbots/active/bot` (`botType: text` or `voice`) |
| "What bot is currently active?"                               | `GET /v1/chatbots/active/all`                               |
| "Have the bot start a conversation **and** send via WhatsApp" | `POST /v1/chatbots/talk`                                    |
| "Pin a specific bot to one contact"                           | `PUT /v1/clients/bot/assign`                                |
| "Reset the bot's memory for one contact"                      | `PUT /v1/clients/session/clear/:clientWaNumber`             |
| "Run inference but **don't** send to WhatsApp (testing)"      | `POST /v1/chatbots/:chatbotId/process`                      |

For voice-bot dialing, use [`heltar-calls`](../heltar-calls/SKILL.md) — voice **calls** initiate from `/v1/calls/initiate`, not from the chatbots endpoints.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Quick Start — proactively trigger a bot

```bash
curl -X POST "$API_URL/v1/chatbots/talk" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientWaNumber": "919876543210",
    "context": "Customer just placed an order, ask about delivery preferences",
    "contextLocation": "system"
  }'
```

The API returns immediately (`data: null`) — the bot dispatches asynchronously and sends its response to the contact via WhatsApp.

## Selection priority for `/talk`

1. If `chatbotId` is sent — that bot is used **and** assigned to the contact for future conversations.
2. Else if the contact already has an assigned bot — that bot is used.
3. Else — the business's active bot (or weighted random from live chatbots) is selected and assigned.

## `contextLocation` values

| Value            | Behavior                                                                                  |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `system`         | Appended to the system prompt. Use for directives ("the customer is VIP, escalate fast"). |
| `user` (default) | Appears as if the contact said it.                                                        |
| `assistant`      | Appears as if the bot said it.                                                            |

## Activate / deactivate at business level

```jsonc
POST /v1/chatbots/active/bot
{ "chatbotId": "550e...", "botType": "text" }   // activate
{ "chatbotId": null,       "botType": "text" }  // deactivate
```

`botType` is required: `text` or `voice`.

## Assign / unassign a bot to one contact

```jsonc
PUT /v1/clients/bot/assign
{ "clientWaNumber": "919876543210", "chatbotId": "550e..." }   // assign
{ "clientWaNumber": "919876543210", "chatbotId": null }        // revert to business default
```

To enable/disable bot replies for a contact (without changing assignment), use the toggle on `PUT /v1/clients/bot/toggle/:clientWaNumber` — see [`heltar-contacts`](../heltar-contacts/SKILL.md).

## Clear a bot's memory

```
PUT /v1/clients/session/clear/:clientWaNumber
```

Resets the conversation context for that contact only. Old messages remain in the inbox; a private "Session cleared" marker is inserted in the chat timeline. Use when a bot has gone off-track.

## Test inference (off-WhatsApp)

```jsonc
POST /v1/chatbots/:chatbotId/process
{
  "messages": [{ "role": "user", "content": "What are your business hours?" }],
  "outputMessageFormat": true,
  "executeFunctions": true,
  "clientNumber": "919876543210"
}
```

Returns the bot's `assistant` reply **without** sending to WhatsApp. Useful for unit tests, evals, or hand-rolling a custom UI on top of the bot.

`messages[]` follows OpenAI's chat-completions shape — `role` ∈ `user` / `assistant` / `system` / `tool`. For `tool` messages, include `tool_call_id`.

## Common gotchas

- **`/talk` does not return the bot's reply.** It returns `data: null` immediately. The reply lands via webhook + the contact's WhatsApp. Use `/process` if you need the response synchronously.
- Setting `chatbotId` on `/talk` permanently re-assigns that bot to the contact. Don't use `/talk` as an ephemeral override — use `/process` for one-off inference.
- Voice bot ID is separate from text bot ID. Activating a chatbot under `botType: text` does **not** make it the voice bot.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
