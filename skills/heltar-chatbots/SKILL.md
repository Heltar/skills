---
name: heltar-chatbots
description: "Create, configure, activate, trigger, and test Heltar chatbots — both text and voice. Use when building or updating a bot and its functions via API, exporting/importing bots, splitting traffic between live bots, proactively starting a bot conversation, assigning a bot to a contact, clearing a bot's memory, running off-WhatsApp inferences, reading bot results, or checking the AI wallet balance."
metadata:
  author: Heltar
  version: 0.1.0
  category: Automation
  tags: chatbot, voice-bot, create, update, functions, export, import, live-chatbots, talk, assign, session, process, results, ai-results, extract-pdf, wallet, openai-format
  uses:
    - heltar-authentication
---

# Heltar Chatbots

## Overview

Chatbots run automated conversations on top of the inbox. Each business has an **active text bot** and an **active voice bot**, optionally a weighted list of **live** text bots, and individual contacts can override with their own assignment. The Chatbot API lets you create and configure bots (prompt, model, functions, voice settings), export/import them, change those assignments, trigger a bot to start talking proactively, reset its memory, run an off-WhatsApp inference for testing, read the results bots collect, and check the AI wallet that pays for model usage.

## Agent Instructions

Match the user's intent to the right endpoint — these are not interchangeable:

| User intent                                                          | Endpoint                                                                       |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| "Create a bot" (AI: `systemPrompt`; flow: `flowDefinition`)          | `POST /v1/chatbots`                                                            |
| "List my bots / which ones are active?"                              | `GET /v1/chatbots` (`?createdBy=`, `?includeFunctionNames=true`)               |
| "Show one bot with its functions"                                    | `GET /v1/chatbots/:id`                                                         |
| "Change prompt / model / settings / functions / voice config"        | `PUT /v1/chatbots/:id` (see the `functionDefinitions` warning below)           |
| "Delete a bot"                                                       | `DELETE /v1/chatbots/:id`                                                      |
| "Back up a bot / copy it to another account"                         | `GET /v1/chatbots/:id/export` → `POST /v1/chatbots/import`                     |
| "Make this bot the default for the business"                         | `POST /v1/chatbots/active/bot` (`botType: text` or `voice`)                    |
| "What bot is currently active?"                                      | `GET /v1/chatbots/active/all`                                                  |
| "A/B test two prompts / split new chats between bots"                | `PUT /v1/business/live-chatbots` (**Full access** key)                         |
| "Pin a specific bot to one contact"                                  | `PUT /v1/clients/bot/assign`                                                   |
| "Reset the bot's memory for one contact"                             | `PUT /v1/clients/session/clear/:clientWaNumber`                                |
| "Have the bot start a conversation **and** send via WhatsApp"        | `POST /v1/chatbots/talk`                                                       |
| "Run inference but **don't** send to WhatsApp (testing / custom UI)" | `POST /v1/chatbots/:chatbotId/process`                                         |
| "What did the bot collect from each contact?"                        | `GET /v1/chatbots/results?chatbotId=`                                          |
| "Summarise / score / classify conversations into JSON"               | `POST /v1/chatbots/results/ai`                                                 |
| "List the functions shared across the org"                           | `GET /v1/chatbots/functions/org`                                               |
| "Test a function without the model"                                  | `POST /v1/chatbots/functions/execute`                                          |
| "Turn a PDF into text for a system prompt"                           | `POST /v1/chatbots/extract-pdf`                                                |
| "How much AI credit is left?"                                        | `GET /v1/wallet` (**Full access** or **Read-only** key)                        |
| "Show wallet top-ups"                                                | `GET /v1/wallet/:walletId/transactions` (**Full access** or **Read-only** key) |

Scopes: `/v1/chatbots/*` needs `chatbots:read` (GET) / `chatbots:write` (everything else); `/v1/clients/*` needs `clients:write`. `/v1/business/live-chatbots` and `/v1/wallet/*` sit outside the per-resource scope picker — use a key created with the **Full access** preset (**Read-only** also works for the wallet GETs).

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

The API returns immediately (`data: null`) — the bot dispatches asynchronously and sends its response to the contact via WhatsApp. If the bot had been switched off for that contact, it is switched back on. The body is strict: unknown fields return `400`.

## Selection priority for `/talk`

1. If `chatbotId` is sent — that bot is used **and** assigned to the contact for future conversations.
2. Else if the contact already has an assigned bot — that bot is used.
3. Else — the business's bot selection applies: a weighted pick from the live chatbots, or the active bot. The chosen bot is assigned to the contact.

## `contextLocation` values

| Value            | Behavior                                                                                  |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `system`         | Appended to the system prompt. Use for directives ("the customer is VIP, escalate fast"). |
| `user` (default) | Appears as if the contact said it.                                                        |
| `assistant`      | Appears as if the bot said it.                                                            |

`eventType` (1–256 chars, default `business_event`) applies to **Meta AI bots only**: it is the event name handed to Meta's agent, and the response message becomes `"Agent event accepted — Meta AI decides what to send"`. Every other bot type ignores it.

## Create and update a bot

```jsonc
POST /v1/chatbots   // → 201 with the full chatbot object
{ "name": "Support Bot", "systemPrompt": "You are the support assistant for…", "model": "google/gemini-3.5-flash", "createdBy": "api" }
// Flow bot: { "name": "…", "type": "flow", "flowDefinition": { …as exported by the flow builder… } }
```

`type` defaults to `llm`. Create stores the core fields only — image/audio/timestamp settings, `functionDefinitions` and `voiceBot` are set afterwards with `PUT /v1/chatbots/:id`. Update merges the fields you send (`voiceBot` and `audioTranscriptionConfig` merge section by section).

> **WARNING — `PUT /v1/chatbots/:id` treats `functionDefinitions` as the complete list of the bot's functions, and omitting the field counts as an empty list.** Every organization-level function not in the list is unlinked from the bot. Before updating anything else, `GET /v1/chatbots/:id` and send its `functionDefinitions` back unchanged. Entries with `id` update that function; entries without `id` reuse an existing org function with the same `name` or create a new one.

Each function entry needs `name`, `description`, `parameters` (JSON Schema) and `executionDetails`: `api_call` (`apiUrl`, `method`, `headers`), `lambda_function` (`sourceCode`, `codeLanguage`, `env`), or `unified_function_event_handlers` (the same-named function in your Code Editor deployment — see [`heltar-code-editor`](../heltar-code-editor/SKILL.md)). `directReturn: true` sends the tool output to the contact as-is.

`GET /v1/chatbots/:id/export` returns `{ file, fileName, encryptionKey }` — keep both. `POST /v1/chatbots/import` takes `fileData` + `encryptionKey` (+ optional `newName`) and creates a new bot, matching functions by `name`.

## Activate / deactivate at business level

```jsonc
POST /v1/chatbots/active/bot
{ "chatbotId": "550e...", "botType": "text" }   // activate → data: { activeChatbotId, botType }
{ "chatbotId": null,       "botType": "text" }  // deactivate → activeChatbotId: null
```

`botType` is required: `text` or `voice` (the response key becomes `activeVoiceBotId`). Only an `llm` bot can be the voice bot.

### Live chatbots (weighted routing)

```jsonc
PUT /v1/business/live-chatbots   // Full access key
{ "liveChatbots": [ { "chatbotId": "550e...", "weight": 70 }, { "chatbotId": "7c9e...", "weight": 30 } ] }
// "liveChatbots": [] turns weighted routing off
```

Weights are `0`–`100` and relative (they need not sum to 100); `0` pauses a bot for new contacts. A contact already assigned to a live bot stays on it; the active bot remains the fallback.

## Assign / unassign a bot to one contact

```jsonc
PUT /v1/clients/bot/assign
{ "clientWaNumber": "919876543210", "chatbotId": "550e..." }   // assign → data: { clientWaNumber, assignedChatbotId }
{ "clientWaNumber": "919876543210", "chatbotId": null }        // revert → message "Chatbot assignment removed from client", assignedChatbotId: null
```

The contact is created if it does not exist yet. To enable/disable bot replies for a contact (without changing assignment), use the toggle on `PUT /v1/clients/bot/toggle/:clientWaNumber` — see [`heltar-contacts`](../heltar-contacts/SKILL.md).

## Clear a bot's memory

```
PUT /v1/clients/session/clear/:clientWaNumber
```

Resets the conversation context for that contact only; flow bots restart from the beginning. Old messages remain in the inbox; a private "Session cleared" marker is inserted in the chat timeline. Use when a bot has gone off-track.

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

Returns `{ messages[], isComplete, isDirectReturn? }` **without** sending to WhatsApp or touching the contact's chat history. `messages[]` holds everything generated in the call: the assistant replies and, when functions were executed, the `tool` messages with their results. Useful for unit tests, evals, or hand-rolling a custom UI on top of the bot.

- With `outputMessageFormat: true` the assistant `content` is a **JSON string** (parse it) shaped `{ "message": [ … ] }`, one item per WhatsApp message: `{ "messageType": "text", "message" }`, `{ "messageType": "button", "body", "buttons": [] }` or `{ "messageType": "cta_url", "body", "button": { "text", "url" } }`. Bots with `hasTimeout` add a `followUp` object; bots with `enableReply` add `replyToIndex` per item.
- With `executeFunctions: false` (default) the model makes one turn; a function call comes back as an assistant message with `tool_calls` and empty content — run it yourself, append that assistant message plus a `tool` message (`tool_call_id`), and call again.
- With `executeFunctions: true` only functions that have `executionDetails` are offered; they run server-side until a final reply (`isComplete: true`) or a `directReturn` function ends the turn.

`messages[]` follows OpenAI's chat-completions shape — `role` ∈ `user` / `assistant` / `system` / `tool`; `content` is a string or parts (`text`, `image_url`). Your own `system` message replaces the bot's prompt.

## Results, functions and utilities

- `GET /v1/chatbots/results?chatbotId=` — one row per contact × bot, newest first (max 50,000), stored fields flattened to dot keys (`order.id`). Flow bots fill rows themselves; for AI bots run `POST /v1/chatbots/results/ai` with `clientWaNumbers[]` (`botResultId` to store onto a row) and an `outputFormat` JSON Schema (`strict: true` → list every property in `required`, `additionalProperties: false`). A contact that failed returns `"error": "Failed to process"`.
- `GET /v1/chatbots/functions/org` lists org-level functions; `POST /v1/chatbots/functions/execute` runs one (`functionId`, `parameters`) without the model — `api_call` functions are not supported here; pass `sourceCode` to try ad-hoc Python.
- `POST /v1/chatbots/extract-pdf` takes `fileData` as a `data:application/pdf;base64,…` URI (≤ 50 MB) and returns `{ text }` — a failed extraction still returns `200` with empty `text`.
- `GET /v1/wallet` → `{ id, balance, availableBalance, currency, walletType }` (decimal strings; `data: null` when no wallet). `GET /v1/wallet/:walletId/transactions?limit=&offset=` lists top-ups and adjustments only — usage is deducted from the balance directly.

## Common gotchas

- **`/talk` does not return the bot's reply.** It returns `data: null` immediately. The reply lands via webhook + the contact's WhatsApp. Use `/process` if you need the response synchronously.
- Setting `chatbotId` on `/talk` permanently re-assigns that bot to the contact. Don't use `/talk` as an ephemeral override — use `/process` for one-off inference.
- Voice bot ID is separate from text bot ID. Activating a chatbot under `botType: text` does **not** make it the voice bot, and only `llm` bots can be voice bots.
- Updating a bot without echoing `functionDefinitions` silently unlinks all of its functions (see the warning above).
- `includeTimestampInContext` and `contextTimestampTimezone` must be sent together on update.
- `/process`, `results/ai`, `extract-pdf` and live conversations bill model usage to the org's AI wallet; a prepaid wallet under **$5** stops bots replying and makes `/process` fail with `500`.
- `GET` / `PUT` / `DELETE /v1/chatbots/:id` return `500` (not `404`) when the ID is not accessible to your business — verify the UUID before assuming an outage.
- `POST /v1/chatbots/import` names the bot `<original> (Imported)` unless you pass `newName`; exported types other than `llm` / `flow` are imported as `llm`.

## Related Skills

- [`heltar-calls`](../heltar-calls/SKILL.md) — dial the voice bot.
- [`heltar-contacts`](../heltar-contacts/SKILL.md) — per-contact bot on/off toggle.
- [`heltar-code-editor`](../heltar-code-editor/SKILL.md) — deploy the code that `unified_function_event_handlers` functions call.
- `heltar-business` — the other `/v1/business/*` account settings.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
