---
title: Chatbot
description: Activate, trigger, and test chatbot conversations
icon: Bot
order: 9
---

# Chatbot API

Activate chatbots, trigger conversations, and test bot responses programmatically.

---

## Set Active Bot

:::api
method: POST
endpoint: /v1/chatbots/active/bot
title: Set Active Bot
description: Assign or unassign a chatbot as the active text or voice bot for your business. Pass `chatbotId` as `null` to deactivate.

## Body Parameters

- chatbotId: string - Chatbot UUID to activate, or `null` to deactivate
- botType: string [required] - `text` or `voice`

```request
{
  "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
  "botType": "text"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Active text bot set successfully",
  "data": {
    "activeChatbotId": "550e8400-e29b-41d4-a716-446655440000",
    "botType": "text"
  }
}
```

:::

> [!TIP]
> To unassign/deactivate, send `"chatbotId": null` with the desired `botType`.

---

## Get Active Bots

:::api
method: GET
endpoint: /v1/chatbots/active/all
title: Get Active Bots
description: Get the currently active text and voice bots for your business.

## Response

```response
{
  "code": "OK",
  "message": "Active bots retrieved successfully",
  "data": {
    "activeChatbotId": "550e8400-e29b-41d4-a716-446655440000",
    "activeChatbot": { "id": "...", "name": "Support Bot", "model": "gpt-4o" },
    "activeVoiceBotId": null,
    "activeVoiceBot": null
  }
}
```

:::

---

## Trigger Chatbot Talk

:::api
method: POST
endpoint: /v1/chatbots/talk
title: Trigger Chatbot Talk
description: Trigger the chatbot to start a conversation with a specific contact. The bot picks up existing chat history as context and sends its response via WhatsApp. The API returns immediately — the bot processes and sends messages asynchronously.

## Body Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)
- chatbotId: string - UUID of a specific chatbot to use. If not provided, the business's active chatbot is used.
- context: string - Extra context to append to the conversation. Works like follow-up prompts — gives the bot additional instructions or information.
- contextLocation: string - Where to append the context. One of `system`, `user`, or `assistant`. Defaults to `user`.

### Context Location Options

| Value       | Behavior                                                                                 |
| ----------- | ---------------------------------------------------------------------------------------- |
| `system`    | Appended to the system prompt — use for bot instructions/directives                      |
| `user`      | Added as a user message at the end of chat history — appears as if the client said it    |
| `assistant` | Added as an assistant message at the end of chat history — appears as if the bot said it |

```request
{
  "clientWaNumber": "919876543210",
  "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
  "context": "Customer just placed an order, ask them about delivery preferences",
  "contextLocation": "system"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Chatbot conversation triggered successfully",
  "data": null
}
```

:::

> [!TIP]
> The `context` parameter is optional but useful for giving the bot situational awareness. For example, append a system context like "The customer has been inactive for 3 days, gently follow up" to guide the bot's response.

> [!IMPORTANT]
> **Chatbot selection priority:**
>
> 1. If `chatbotId` is provided — that bot is used **and assigned** to the contact for future conversations
> 2. If `chatbotId` is not provided — the contact's currently assigned bot is used
> 3. If no bot is assigned to the contact — the business's active bot (or weighted random from live chatbots) is selected and assigned

---

## Assign Chatbot to Contact

:::api
method: PUT
endpoint: /v1/clients/bot/assign
title: Assign Chatbot to Contact
description: Assign a specific chatbot to a contact, or unassign by passing `null`. When assigned, this chatbot will handle conversations for the contact instead of the business's default active bot.

## Body Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)
- chatbotId: string [required] - Chatbot UUID to assign, or `null` to unassign

```request
{
  "clientWaNumber": "919876543210",
  "chatbotId": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Chatbot assigned successfully",
  "data": null
}
```

:::

> [!TIP]
> To unassign a chatbot from a contact (revert to default active bot), send `"chatbotId": null`.

---

## Clear Bot Session

:::api
method: PUT
endpoint: /v1/clients/session/clear/:clientWaNumber
title: Clear Bot Session
description: Resets the chatbot's conversation memory for a specific contact. After clearing, the bot will no longer reference any messages sent before the clear point — it starts with a fresh context. A private "session cleared" marker message is saved in the chat history to indicate when the reset happened.

## Path Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)

```request
PUT /v1/clients/session/clear/919876543210
```

## Response

```response
{
  "code": "OK",
  "message": "Session cleared successfully",
  "data": {
    "sessionClearedAt": "2026-03-31T10:30:00.000Z",
    "message": {
      "wamid": "wamid.HBg...",
      "clientWaNumber": "919876543210",
      "body": "Session cleared at 2026-03-31T10:30:00.000Z",
      "timestamp": "2026-03-31T10:30:00.000Z",
      "status": "waiting",
      "type": "text",
      "metaData": {
        "isPrivate": true,
        "isSessionClear": true
      }
    }
  }
}
```

:::

> [!TIP]
> Use this when a contact's conversation has gone off-track or when you want the bot to start fresh without old context influencing its responses.

> [!NOTE]
> The session clear does not delete any messages — it only changes which messages the bot considers as context. All chat history remains visible in the inbox. A "Bot session cleared" indicator will appear in the chat timeline.

---

## Process Conversation

:::api
method: POST
endpoint: /v1/chatbots/:chatbotId/process
title: Process Conversation
description: Send messages to a chatbot and get its response. Unlike the Talk endpoint, this does NOT send messages via WhatsApp — it only returns the chatbot's response. Useful for testing or building custom integrations.

## Path Parameters

- chatbotId: string [required] - Chatbot UUID

## Body Parameters

- messages: array [required] - Array of conversation messages in OpenAI format
- outputMessageFormat: boolean - Return response in structured JSON message format (default: false)
- clientNumber: string - Client's WhatsApp number (added to system prompt for context)
- executeFunctions: boolean - Execute tool/function calls if the bot triggers them (default: false)

### Message Format

Each message in the array should have:

| Field          | Type   | Required | Description                                           |
| -------------- | ------ | -------- | ----------------------------------------------------- |
| `role`         | string | Yes      | `user`, `assistant`, `system`, or `tool`              |
| `content`      | string | Yes\*    | Message content (\*optional for assistant with tools) |
| `tool_calls`   | array  | No       | Tool calls (for assistant messages)                   |
| `tool_call_id` | string | No       | Required for `tool` role messages                     |

```request
{
  "messages": [
    {
      "role": "user",
      "content": "What are your business hours?"
    }
  ],
  "outputMessageFormat": true,
  "executeFunctions": true,
  "clientNumber": "919876543210"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Chatbot response generated successfully",
  "data": {
    "messages": [
      {
        "role": "assistant",
        "content": "{\"message\": {\"type\": \"text\", \"text\": \"Our business hours are 9 AM to 6 PM, Monday to Friday.\"}}"
      }
    ],
    "isComplete": true
  }
}
```

:::
