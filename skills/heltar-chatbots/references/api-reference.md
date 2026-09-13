---
title: Chatbot
description: Create, configure, activate, trigger, and test chatbots
icon: Bot
order: 9
---

# Chatbot API

Create and configure chatbots, choose which bots answer your WhatsApp and web-chat conversations, trigger a bot to reach out to a contact, and test bot responses without sending anything.

| Area                  | Endpoints                                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Manage chatbots       | `POST /v1/chatbots`, `GET /v1/chatbots`, `GET /v1/chatbots/:id`, `PUT /v1/chatbots/:id`, `DELETE /v1/chatbots/:id` |
| Export and import     | `GET /v1/chatbots/:id/export`, `POST /v1/chatbots/import`                                                          |
| Active bots           | `POST /v1/chatbots/active/bot`, `GET /v1/chatbots/active/all`, `PUT /v1/business/live-chatbots`                    |
| Per-contact control   | `PUT /v1/clients/bot/assign`, `PUT /v1/clients/session/clear/:clientWaNumber`                                      |
| Conversations         | `POST /v1/chatbots/talk`, `POST /v1/chatbots/:chatbotId/process`                                                   |
| Results               | `GET /v1/chatbots/results`, `POST /v1/chatbots/results/ai`                                                         |
| Functions             | `GET /v1/chatbots/functions/org`, `POST /v1/chatbots/functions/execute`                                            |
| Utilities and billing | `POST /v1/chatbots/extract-pdf`, `GET /v1/wallet`, `GET /v1/wallet/:walletId/transactions`                         |

---

## Authentication

All endpoints on this page require an API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

See [Authentication](/docs/api/authentication) for setup instructions and the scope model.

| Path prefix                  | Scope needed                                                      |
| ---------------------------- | ----------------------------------------------------------------- |
| `/v1/chatbots/*`             | `chatbots:read` for GET requests, `chatbots:write` for all others |
| `/v1/clients/*`              | `clients:read` for GET requests, `clients:write` for all others   |
| `/v1/business/live-chatbots` | Outside the scope picker: **Full access** preset                  |
| `/v1/wallet/*`               | Outside the scope picker: **Full access** or **Read-only** preset |

A call the key is not scoped for returns `403 Forbidden`.

### Response format

Every successful response is a JSON object with a `message` and a `data` field. Errors return the HTTP status shown in the tables below with a body of the form `{ "errorType": "...", "errorMessage": "...", "errorsValidation": null, "errorRaw": null }`. Validation failures (`400`) put the first failing field and reason in `errorMessage`.

---

## The chatbot object

Every chatbot endpoint that returns a bot returns the same object. Fields marked with a default are filled in when you create a bot without them.

### Top-level fields

| Field                       | Type           | Default                                                   | Description                                                                                                                                              |
| --------------------------- | -------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                        | string         | generated UUID                                            | Chatbot identifier                                                                                                                                       |
| `name`                      | string         | required                                                  | Display name                                                                                                                                             |
| `type`                      | string         | `llm`                                                     | `llm`, `flow`, `static_flowbot`, `journey`, `meta_ai` (see below)                                                                                        |
| `systemPrompt`              | string         | required for `llm`                                        | Instructions for the model                                                                                                                               |
| `model`                     | string         | `google/gemini-3.5-flash`                                 | Any model ID shown in the dashboard model picker, for example `google/gemini-3.5-flash`, `google/gemini-3.1-pro-preview`, `gpt-5-mini`, `gpt-5.5`        |
| `contextLength`             | number         | `10`                                                      | Number of recent messages sent to the model as context                                                                                                   |
| `temperature`               | number         | `0.7`                                                     | Sampling temperature                                                                                                                                     |
| `maxTokens`                 | number         | `1024`                                                    | Maximum tokens per reply                                                                                                                                 |
| `reasoningEffort`           | string         | `none`                                                    | `default`, `none`, `minimal`, `low`, `medium`, `high`, `xhigh`. Only values the chosen model supports are applied; others fall back to the model default |
| `verbosity`                 | string         | `medium`                                                  | `low`, `medium`, `high`                                                                                                                                  |
| `sendMsgType`               | array          | `["text", "button", "ctaUrl"]`                            | Message kinds the bot may send: `text`, `button`, `ctaUrl`                                                                                               |
| `truncateMsg`               | boolean        | `false`                                                   | `true` truncates button labels longer than 20 characters. `false` sends such messages as a numbered text list instead                                    |
| `enableReply`               | boolean        | `false`                                                   | Lets the bot quote an earlier message when replying                                                                                                      |
| `showTypingIndicator`       | boolean        | `true`                                                    | Show a typing indicator while the bot is working                                                                                                         |
| `sendFirstMessage`          | boolean        | `true`                                                    | Greet a first-time web-chat visitor before they write (web channel only)                                                                                 |
| `minBotMsgDelay`            | number         | `0`                                                       | Minimum seconds to wait before replying                                                                                                                  |
| `hasTimeout`                | boolean        | `false`                                                   | Enable follow-up (nudge) messages when the contact stops replying                                                                                        |
| `timeoutDuration`           | number or null | `null`                                                    | Fallback delay in seconds before a follow-up when the model does not choose one (60 when unset)                                                          |
| `maxConsecutiveNudges`      | number         | `3`                                                       | Maximum follow-ups without a reply                                                                                                                       |
| `maxBotMessagesPerSession`  | number         | `50`                                                      | Bot messages allowed per session                                                                                                                         |
| `followUpPrompt`            | string         | built-in prompt                                           | Prompt used to write follow-ups. Supports `{{follow_up_number}}` and `{{follow_up_number_ordinal}}`                                                      |
| `followUpLocation`          | string         | `assistant`                                               | Where the follow-up prompt is injected: `system` or `assistant`                                                                                          |
| `enableFollowUpType`        | boolean        | `false`                                                   | Ask the model to label each follow-up with a `followUpType`                                                                                              |
| `latestImagesCount`         | number         | `5`                                                       | How many recent images are passed to the model                                                                                                           |
| `imageContextFilter`        | string         | `all`                                                     | Which images to include: `all`, `incoming`, `outgoing`                                                                                                   |
| `audioTranscriptionConfig`  | object         | `{ "enabled": true, "provider": "elevenlabs-scribe-v2" }` | Voice-note transcription settings (see below)                                                                                                            |
| `includeTimestampInContext` | boolean        | `true`                                                    | Prefix messages with their timestamp                                                                                                                     |
| `contextTimestampTimezone`  | string         | `Asia/Kolkata`                                            | IANA zone (`Europe/London`) or `IST`, `UTC`, `PST`, `EST`, `CET`, `AEST`                                                                                 |
| `sessionExpiryHours`        | number         | `24`                                                      | Flow bots: idle hours before the flow session ends (taken from the flow settings)                                                                        |
| `flowDefinition`            | object or null | `null`                                                    | Flow bots: the definition produced by the flow builder (`groups`, `edges`, `events`, ...)                                                                |
| `voiceBot`                  | object         | see below                                                 | Voice-call settings, used when the bot is the active voice bot                                                                                           |
| `functionDefinitions`       | array          | `[]`                                                      | Tools the bot can call (see [Function definitions](#function-definitions))                                                                               |
| `builtInTools`              | array or null  | `null`                                                    | Built-in voice tools: `sendMsgToWhatsApp`, `endCall`. Each entry is `{ "name", "directReturn" }`                                                         |
| `resultConfig`              | object or null | `null`                                                    | Saved settings of the last AI results run for this bot                                                                                                   |
| `createdBy`                 | string         | `human`                                                   | `human`, `copilot`, `api`                                                                                                                                |
| `businessId`, `orgId`       | number         |                                                           | Owning business and organization                                                                                                                         |
| `createdAt`, `updatedAt`    | string         |                                                           | ISO 8601 timestamps                                                                                                                                      |

### Chatbot types

| `type`           | What it is                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `llm`            | Prompt-driven AI bot. Needs `systemPrompt`. Only `llm` bots can be used as the voice bot |
| `flow`           | Visual flow built in the flow builder. Needs `flowDefinition`                            |
| `static_flowbot` | Code-backed flow bot, authored in the code editor                                        |
| `journey`        | Event-driven journey, authored in the code editor                                        |
| `meta_ai`        | Meta AI business agent that runs on Meta's side; configured from the dashboard           |

Use this API to create and configure `llm` and `flow` bots. The other types are managed from the code editor or the dashboard.

### `audioTranscriptionConfig`

| Key           | Type    | Default                | Description                                                                        |
| ------------- | ------- | ---------------------- | ---------------------------------------------------------------------------------- |
| `enabled`     | boolean | `true`                 | Transcribe incoming voice notes before passing them to the model                   |
| `provider`    | string  | `elevenlabs-scribe-v2` | `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `elevenlabs-scribe-v2` |
| `language`    | string  |                        | ISO-639-1 code such as `en` or `hi`                                                |
| `temperature` | number  |                        | `0` to `2`                                                                         |
| `prompt`      | string  |                        | Style hint for the transcriber                                                     |

### `voiceBot`

Each section is merged on update, so you can send only the keys you want to change. Voice IDs are the public IDs shown in the dashboard.

| Key                                                                                                                             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tts.provider`, `tts.model`, `tts.voiceId`, `tts.speed`                                                                         | Text-to-speech. `provider`: `cartesia` (default), `elevenlabs`, `openai`. `speed`: `0.6` to `1.5`. ElevenLabs also accepts `stability` and `similarity_boost` (`0` to `1`) and `streamingMode` (`sentence`, `word`)                                                                                                                                                                                                                                                                                |
| `stt.provider`, `stt.language`, `stt.model`, `stt.endpointing`                                                                  | Speech-to-text. `provider`: `deepgram` (default), `elevenlabs`, `assemblyai`. `language` defaults to `multi`. `endpointing`: `10` to `5000` ms (default `250`). Booleans: `interimResults`, `smartFormat`, `punctuate`, `profanityFilter`, `includeTimestamps`, `tagAudioEvents`                                                                                                                                                                                                                   |
| `realtime.voice`, `realtime.turnDetection`, `realtime.noiseReduction`                                                           | Used with realtime speech models. `voice`: `alloy`, `ash`, `ballad`, `coral`, `echo`, `sage`, `shimmer`, `verse`, `marin`, `cedar`, or a Heltar Voice name (`priya`, `kiara`, `vikram`, `meera`, `jhanvi`, `ananya`, `karan`, `kavya`, `simran`, `isha`, `aditya`, `ravi`, `sahil`, `deepak`, `nisha`, `pooja`, `rajesh`, `swati`, `riya`, `tara`, `amit`, `sneha`, `madhuri`, `divya`, `nikhil`, `varun`, `anjali`, `rahul`, `ashok`, `neha`). `turnDetection.type`: `server_vad`, `semantic_vad` |
| `vad.stopSecs`, `vad.startSecs`, `vad.confidence`                                                                               | Voice activity detection. Defaults `0.2`, `0.15`, `0.65`                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `session.minEndpointingDelay`, `session.maxEndpointingDelay`, `session.preemptiveGeneration`, `session.minInterruptionDuration` | Turn handling. Defaults `0.1`, `1.5`, `true`, `0.3`                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `backgroundNoise.enabled`, `backgroundNoise.volume`, `backgroundNoise.ambientSound`, `backgroundNoise.thinkingSound`            | Ambient audio. Sounds are a built-in clip name (`office_ambience`, `crowded_room`, `city_ambience`, `forest_ambience`, `keyboard_typing`, `keyboard_typing2`, `hold_music`, `none`) or a public audio URL. Disabled by default                                                                                                                                                                                                                                                                     |
| `silenceWatchdog.enabled`, `silenceWatchdog.timeout`                                                                            | Speak again after `timeout` seconds of silence (`5` to `300`, default `30`). Disabled by default                                                                                                                                                                                                                                                                                                                                                                                                   |
| `noiseCancellation.enabled`, `noiseCancellation.model`                                                                          | Caller-side noise cancellation. `model`: `NC`, `BVC`, `BVCTelephony` (default). Disabled by default                                                                                                                                                                                                                                                                                                                                                                                                |
| `pronunciations`                                                                                                                | Array of `{ "word", "replacement", "caseSensitive" }` entries applied before speech synthesis                                                                                                                                                                                                                                                                                                                                                                                                      |
| `greetingInstruction`                                                                                                           | Instruction for the opening line of a call                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `elevenlabsAgentId`, `elevenlabsAgentPublic`                                                                                    | Hand the call to an ElevenLabs conversational agent instead of the built-in pipeline                                                                                                                                                                                                                                                                                                                                                                                                               |

### Function definitions

`functionDefinitions[]` entries describe tools the model may call. Functions are stored at organization level and linked to bots, so the same function can be shared by several bots. Each entry:

| Field              | Type           | Description                                                                                                                                 |
| ------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | string         | Omit to create a new function. Pass an existing ID to update and link it. A new function whose `name` matches an existing one is reused     |
| `name`             | string         | Tool name the model calls (required)                                                                                                        |
| `description`      | string         | What the tool does (required)                                                                                                               |
| `parameters`       | object         | JSON Schema for the model-supplied arguments: `{ "type": "object", "properties": {...}, "required": [...], "additionalProperties": false }` |
| `heltarParameters` | object or null | Extra JSON Schema for values you supply outside the model, such as URL path variables                                                       |
| `executionDetails` | object or null | How the tool runs (see below). `null` means the bot only returns the tool call for you to handle                                            |
| `sourceCode`       | string or null | Code for `lambda_function` tools                                                                                                            |
| `codeLanguage`     | string or null | `python` (default), `javascript`, `java`                                                                                                    |
| `env`              | object or null | Environment variables made available to `sourceCode`                                                                                        |
| `directReturn`     | boolean        | `true` sends the tool's output to the contact as-is and skips the follow-up model turn (default `false`)                                    |
| `createdBy`        | string         | `human`, `copilot`, `api`                                                                                                                   |

`executionDetails.type`:

| `type`                            | Extra keys                                                                                                      | Behaviour                                                                                                                           |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `api_call`                        | `apiUrl` (required URL), `method` (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`; default `POST`), `headers` (object) | The bot calls your endpoint with the arguments. `{variable}` placeholders in `apiUrl` are added to `heltarParameters` automatically |
| `lambda_function`                 | none (uses `sourceCode`, `codeLanguage`, `env`)                                                                 | Runs `sourceCode` in the hosted code runtime                                                                                        |
| `unified_function_event_handlers` | none                                                                                                            | Runs the function of the same `name` from your code editor deployment                                                               |

---

## Create Chatbot

:::api
method: POST
endpoint: /v1/chatbots
title: Create Chatbot
description: Create a new chatbot for your business. An AI bot needs a system prompt, a flow bot needs a flow definition. Returns `201 Created` with the full chatbot object.

## Body Parameters

- name: string [required] - Display name
- type: string - `llm` (default), `flow`, `static_flowbot`, `journey`, `meta_ai`
- systemPrompt: string - Instructions for the model. Required when `type` is `llm` or omitted
- flowDefinition: object - Flow builder definition. Required when `type` is `flow`
- model: string - Model ID from the dashboard model picker (default `google/gemini-3.5-flash`)
- contextLength: number - Recent messages sent as context (default 10)
- reasoningEffort: string - `default`, `none`, `minimal`, `low`, `medium`, `high`, `xhigh` (default `none`)
- hasTimeout: boolean - Enable follow-up messages when the contact stops replying (default false)
- timeoutDuration: number - Fallback follow-up delay in seconds
- createdBy: string - `human` (default), `copilot`, `api`. Use `api` for bots created by your integration

```request
{
  "name": "Support Bot",
  "type": "llm",
  "systemPrompt": "You are the support assistant for Acme Store. Answer questions about orders, returns and delivery. Keep replies short.",
  "model": "google/gemini-3.5-flash",
  "contextLength": 20,
  "hasTimeout": true,
  "timeoutDuration": 3600,
  "createdBy": "api"
}
```

## Response

```response
{
  "message": "Chatbot created successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Support Bot",
    "type": "llm",
    "systemPrompt": "You are the support assistant for Acme Store. Answer questions about orders, returns and delivery. Keep replies short.",
    "model": "google/gemini-3.5-flash",
    "contextLength": 20,
    "temperature": 0.7,
    "maxTokens": 1024,
    "reasoningEffort": "none",
    "verbosity": "medium",
    "hasTimeout": true,
    "timeoutDuration": 3600,
    "sendMsgType": ["text", "button", "ctaUrl"],
    "truncateMsg": false,
    "enableReply": false,
    "showTypingIndicator": true,
    "sendFirstMessage": true,
    "minBotMsgDelay": 0,
    "maxConsecutiveNudges": 3,
    "maxBotMessagesPerSession": 50,
    "sessionExpiryHours": 24,
    "includeTimestampInContext": true,
    "contextTimestampTimezone": "Asia/Kolkata",
    "followUpLocation": "assistant",
    "enableFollowUpType": false,
    "latestImagesCount": 5,
    "imageContextFilter": "all",
    "audioTranscriptionConfig": {
      "enabled": true,
      "provider": "elevenlabs-scribe-v2"
    },
    "createdBy": "api",
    "createdAt": "2026-09-09T10:30:00.000Z",
    "updatedAt": "2026-09-09T10:30:00.000Z"
  }
}
```

:::

The response is the full [chatbot object](#the-chatbot-object); the example above is abbreviated.

> [!NOTE]
> The create request also accepts `latestImagesCount`, `imageContextFilter`, `audioTranscriptionConfig`, `includeTimestampInContext` and `contextTimestampTimezone`, but these are not stored by the create call today. Set them with [Update Chatbot](#update-chatbot) after the bot exists. Function definitions and voice settings are also added through Update Chatbot.

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/chatbots" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Support Bot",
    "systemPrompt": "You are the support assistant for Acme Store. Keep replies short.",
    "model": "google/gemini-3.5-flash",
    "createdBy": "api"
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/chatbots', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'Support Bot',
    systemPrompt:
      'You are the support assistant for Acme Store. Keep replies short.',
    model: 'google/gemini-3.5-flash',
    createdBy: 'api',
  }),
});
const { data: chatbot } = await response.json();
console.log(chatbot.id);
```

```python
import requests

response = requests.post(
    "{{API_URL}}/v1/chatbots",
    headers={
        "Authorization": "Bearer YOUR_API_KEY",
        "Content-Type": "application/json",
    },
    json={
        "name": "Support Bot",
        "systemPrompt": "You are the support assistant for Acme Store. Keep replies short.",
        "model": "google/gemini-3.5-flash",
        "createdBy": "api",
    },
)
chatbot = response.json()["data"]
print(chatbot["id"])
```

:::

### Create a flow bot

```bash
curl -X POST "{{API_URL}}/v1/chatbots" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Order Tracking Flow",
    "type": "flow",
    "flowDefinition": { "version": "1", "groups": [], "edges": [], "events": [] }
  }'
```

Send the definition exactly as exported by the flow builder. `sessionExpiryHours` is taken from the flow's settings (24 hours when not set).

### Errors

| Status | When                                                                                                                                               |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `400`  | `name` missing, `systemPrompt` missing for an `llm` bot, `flowDefinition` missing or invalid for a `flow` bot, invalid `reasoningEffort` or `type` |
| `403`  | API key lacks `chatbots:write`                                                                                                                     |

---

## List Chatbots

:::api
method: GET
endpoint: /v1/chatbots
title: List Chatbots
description: List every chatbot your business can use, newest first. Includes bots created by your business and bots shared across your organization, plus the currently active text and voice bots.

## Query Parameters

- createdBy: string - Only bots created by `human`, `copilot` or `api`
- includeFunctionNames: boolean - `true` returns each bot's function names in a `functions` array instead of `functionDefinitionsCount`

## Response

```response
{
  "message": "Chatbots retrieved successfully",
  "data": {
    "chatbots": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Support Bot",
        "type": "llm",
        "model": "google/gemini-3.5-flash",
        "systemPrompt": "You are the support assistant for Acme Store...",
        "contextLength": 20,
        "hasTimeout": true,
        "timeoutDuration": 3600,
        "createdBy": "api",
        "functionDefinitionsCount": 2,
        "createdAt": "2026-09-09T10:30:00.000Z",
        "updatedAt": "2026-09-09T10:30:00.000Z"
      },
      {
        "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "name": "Order Tracking Flow",
        "type": "flow",
        "model": "google/gemini-3.5-flash",
        "systemPrompt": "",
        "functionDefinitionsCount": 0,
        "createdAt": "2026-09-08T08:00:00.000Z",
        "updatedAt": "2026-09-08T08:00:00.000Z"
      }
    ],
    "activeChatbot": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Support Bot",
      "type": "llm"
    },
    "activeVoiceBot": null
  }
}
```

:::

Each entry is the [chatbot object](#the-chatbot-object) (abbreviated above) with one extra field: `functionDefinitionsCount`, the number of functions linked to the bot. With `includeFunctionNames=true` the count is replaced by `functions`, an array of function names. `activeChatbot` and `activeVoiceBot` are the matching entries from `chatbots`, or `null`.

```bash
curl -X GET "{{API_URL}}/v1/chatbots?includeFunctionNames=true" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Get Chatbot

:::api
method: GET
endpoint: /v1/chatbots/:id
title: Get Chatbot
description: Fetch one chatbot with its full configuration and linked functions.

## Path Parameters

- id: string [required] - Chatbot UUID

## Response

```response
{
  "message": "Chatbot retrieved successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Support Bot",
    "type": "llm",
    "model": "google/gemini-3.5-flash",
    "systemPrompt": "You are the support assistant for Acme Store...",
    "contextLength": 20,
    "temperature": 0.7,
    "maxTokens": 1024,
    "reasoningEffort": "none",
    "verbosity": "medium",
    "hasTimeout": true,
    "timeoutDuration": 3600,
    "sendMsgType": ["text", "button", "ctaUrl"],
    "voiceBot": {
      "tts": { "provider": "cartesia", "model": "sonic-3", "voiceId": "cartesia_arushi", "speed": 1 },
      "stt": { "provider": "deepgram", "language": "multi", "model": "nova-3", "endpointing": 250 }
    },
    "builtInTools": null,
    "functionDefinitions": [
      {
        "id": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
        "type": "function",
        "name": "get_order_status",
        "description": "Look up an order by its ID",
        "parameters": {
          "type": "object",
          "properties": { "orderId": { "type": "string" } },
          "required": ["orderId"],
          "additionalProperties": false
        },
        "executionDetails": { "type": "unified_function_event_handlers" },
        "directReturn": false,
        "createdBy": "human"
      }
    ],
    "linkedFunctions": [],
    "businessId": 12345,
    "orgId": 678,
    "createdAt": "2026-09-09T10:30:00.000Z",
    "updatedAt": "2026-09-09T10:30:00.000Z"
  }
}
```

:::

`functionDefinitions` contains every function the bot can call (bot-specific and organization-level ones merged), each with its per-bot `directReturn` flag. `linkedFunctions` is always an empty array in this representation.

```bash
curl -X GET "{{API_URL}}/v1/chatbots/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Errors

| Status | When                                                                   |
| ------ | ---------------------------------------------------------------------- |
| `500`  | No chatbot with this ID is accessible to your business or organization |

---

## Update Chatbot

:::api
method: PUT
endpoint: /v1/chatbots/:id
title: Update Chatbot
description: Change a chatbot's settings. Only the fields you send are changed, with one exception: `functionDefinitions` always replaces the bot's linked functions (see the warning below).

## Path Parameters

- id: string [required] - Chatbot UUID

## Body Parameters

- name: string - Display name
- type: string - `llm`, `flow`, `static_flowbot`, `journey`, `meta_ai`. Switching to `flow` requires a `flowDefinition` (sent now or stored earlier)
- systemPrompt: string - Instructions for the model
- flowDefinition: object - Flow builder definition (flow bots)
- model: string - Model ID. Omit to keep the current model
- contextLength: number - Recent messages sent as context
- temperature: number - Sampling temperature
- maxTokens: number - Maximum tokens per reply
- reasoningEffort: string - `default`, `none`, `minimal`, `low`, `medium`, `high`, `xhigh`
- verbosity: string - `low`, `medium`, `high`
- sendMsgType: array - Allowed message kinds: `text`, `button`, `ctaUrl`
- truncateMsg: boolean - Truncate long button labels instead of falling back to a text list
- enableReply: boolean - Let the bot quote earlier messages
- showTypingIndicator: boolean - Show a typing indicator
- sendFirstMessage: boolean - Greet first-time web-chat visitors
- minBotMsgDelay: number - Minimum seconds before replying
- hasTimeout: boolean - Enable follow-up messages
- timeoutDuration: number - Fallback follow-up delay in seconds, or `null`
- maxConsecutiveNudges: number - Maximum follow-ups without a reply
- maxBotMessagesPerSession: number - Bot messages allowed per session
- followUpPrompt: string - Follow-up prompt. Send `null` or an empty string to restore the built-in prompt
- followUpLocation: string - `system` or `assistant`
- enableFollowUpType: boolean - Ask the model to label follow-ups
- latestImagesCount: number - Recent images passed to the model (0 or more)
- imageContextFilter: string - `all`, `incoming`, `outgoing`
- audioTranscriptionConfig: object - Merged with the current transcription settings
- includeTimestampInContext: boolean - Prefix messages with their timestamp. Must be sent together with `contextTimestampTimezone`
- contextTimestampTimezone: string - IANA zone or `IST`, `UTC`, `PST`, `EST`, `CET`, `AEST`. Must be sent together with `includeTimestampInContext`
- voiceBot: object - Voice settings, merged section by section with the current values
- builtInTools: array - Built-in tool names (`sendMsgToWhatsApp`, `endCall`) or `{ "name", "directReturn" }` objects. `null` clears them
- functionDefinitions: array - Full list of the bot's functions (see [Function definitions](#function-definitions))

```request
{
  "systemPrompt": "You are the support assistant for Acme Store. Always ask for the order number first.",
  "model": "gpt-5-mini",
  "reasoningEffort": "low",
  "sendMsgType": ["text", "button"],
  "hasTimeout": true,
  "timeoutDuration": 1800,
  "includeTimestampInContext": true,
  "contextTimestampTimezone": "Asia/Kolkata",
  "functionDefinitions": [
    {
      "id": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
      "name": "get_order_status",
      "description": "Look up an order by its ID",
      "parameters": {
        "type": "object",
        "properties": { "orderId": { "type": "string", "description": "Order number, e.g. 12345" } },
        "required": ["orderId"],
        "additionalProperties": false
      },
      "executionDetails": { "type": "unified_function_event_handlers" },
      "directReturn": false
    },
    {
      "name": "create_return_request",
      "description": "Open a return request for a delivered order",
      "parameters": {
        "type": "object",
        "properties": {
          "orderId": { "type": "string" },
          "reason": { "type": "string" }
        },
        "required": ["orderId", "reason"],
        "additionalProperties": false
      },
      "executionDetails": {
        "type": "api_call",
        "apiUrl": "https://api.example.com/returns",
        "method": "POST",
        "headers": { "X-Api-Key": "YOUR_BACKEND_KEY" }
      }
    }
  ]
}
```

## Response

```response
{
  "message": "Chatbot updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Support Bot",
    "type": "llm",
    "model": "gpt-5-mini",
    "reasoningEffort": "low",
    "systemPrompt": "You are the support assistant for Acme Store. Always ask for the order number first.",
    "sendMsgType": ["text", "button"],
    "hasTimeout": true,
    "timeoutDuration": 1800,
    "includeTimestampInContext": true,
    "contextTimestampTimezone": "Asia/Kolkata",
    "functionDefinitions": [
      {
        "id": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
        "name": "get_order_status",
        "executionDetails": { "type": "unified_function_event_handlers" },
        "directReturn": false
      },
      {
        "id": "9d8c7b6a-5f4e-4d3c-8b2a-1f0e9d8c7b6a",
        "name": "create_return_request",
        "executionDetails": {
          "type": "api_call",
          "apiUrl": "https://api.example.com/returns",
          "method": "POST",
          "headers": { "X-Api-Key": "YOUR_BACKEND_KEY" }
        },
        "directReturn": false
      }
    ],
    "updatedAt": "2026-09-09T11:00:00.000Z"
  }
}
```

:::

> [!WARNING]
> `functionDefinitions` is treated as the complete list of the bot's functions. Every organization-level function that is not in the list is unlinked from the bot, and that includes the case where you omit the field entirely. When you update other settings, first read the bot with `GET /v1/chatbots/:id` and send its `functionDefinitions` back unchanged.

How function entries are matched:

- An entry **with** `id` updates that function and keeps it linked.
- An entry **without** `id` whose `name` matches an existing organization-level function updates and links that function.
- Any other entry without `id` creates a new organization-level function and links it.

```bash
curl -X PUT "{{API_URL}}/v1/chatbots/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Support Bot v2",
    "temperature": 0.4,
    "functionDefinitions": []
  }'
```

### Errors

| Status | When                                                                                                              |
| ------ | ----------------------------------------------------------------------------------------------------------------- |
| `400`  | Invalid field value (enum, range, timezone), malformed `flowDefinition`, or `type` is `flow` without a definition |
| `403`  | API key lacks `chatbots:write`                                                                                    |
| `500`  | No chatbot with this ID is accessible to your business or organization                                            |

---

## Delete Chatbot

:::api
method: DELETE
endpoint: /v1/chatbots/:id
title: Delete Chatbot
description: Permanently delete a chatbot. Functions that belong only to this bot are deleted with it; organization-level functions are unlinked but kept. Bot results stay but lose their reference to the bot. If the bot was the active text or voice bot, that slot is cleared.

## Path Parameters

- id: string [required] - Chatbot UUID

## Response

```response
{
  "message": "Chatbot deleted successfully",
  "data": null
}
```

:::

```bash
curl -X DELETE "{{API_URL}}/v1/chatbots/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Errors

| Status | When                                                                   |
| ------ | ---------------------------------------------------------------------- |
| `403`  | API key lacks `chatbots:write`                                         |
| `500`  | No chatbot with this ID is accessible to your business or organization |

---

## Export Chatbot

:::api
method: GET
endpoint: /v1/chatbots/:id/export
title: Export Chatbot
description: Export a chatbot's configuration and functions as an encrypted, base64-encoded file. A fresh encryption key is generated on every export; you need it to import the file.

## Path Parameters

- id: string [required] - Chatbot UUID

## Response

```response
{
  "message": "Chatbot exported successfully",
  "data": {
    "file": "eyJlbmNyeXB0ZWQiOnRydWUsImFsZ29yaXRobSI6ImFlcy0yNTYtY2JjIiwiZGF0YSI6Ij...",
    "fileName": "chatbot_Support_Bot_1757412600000.hcb",
    "encryptionKey": "3f9c2b7e8a1d4c6f0e5b9a8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b",
    "chatbotName": "Support Bot"
  }
}
```

:::

The export contains the bot's settings (prompt, model, message and follow-up settings, image, audio and result settings, type and flow definition) and all of its functions, including their `sourceCode` and `env`. It does not contain the bot's ID, business, or any conversation data. Store `file` as a `.hcb` file and keep `encryptionKey` with it.

```bash
curl -X GET "{{API_URL}}/v1/chatbots/550e8400-e29b-41d4-a716-446655440000/export" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Import Chatbot

:::api
method: POST
endpoint: /v1/chatbots/import
title: Import Chatbot
description: Create a new chatbot from an exported file. Returns `201 Created` with the imported chatbot and its functions.

## Body Parameters

- fileData: string [required] - The `file` value returned by the export
- encryptionKey: string [required] - The `encryptionKey` returned by the same export
- newName: string - Name for the imported bot. Defaults to the original name followed by ` (Imported)`

```request
{
  "fileData": "eyJlbmNyeXB0ZWQiOnRydWUsImFsZ29yaXRobSI6ImFlcy0yNTYtY2JjIiwiZGF0YSI6Ij...",
  "encryptionKey": "3f9c2b7e8a1d4c6f0e5b9a8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b",
  "newName": "Support Bot (staging)"
}
```

## Response

```response
{
  "message": "Chatbot imported successfully",
  "data": {
    "id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
    "name": "Support Bot (staging)",
    "type": "llm",
    "model": "google/gemini-3.5-flash",
    "systemPrompt": "You are the support assistant for Acme Store...",
    "functionDefinitions": [],
    "linkedFunctions": [
      {
        "directReturn": false,
        "function": {
          "id": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
          "name": "get_order_status",
          "executionDetails": { "type": "unified_function_event_handlers" }
        }
      }
    ],
    "createdAt": "2026-09-09T12:00:00.000Z",
    "updatedAt": "2026-09-09T12:00:00.000Z"
  }
}
```

:::

Import rules:

- Only `llm` and `flow` bots keep their type; any other exported type is imported as an `llm` bot.
- If the export has no model, the imported bot uses `google/gemini-3.1-pro-preview`.
- Functions are matched by `name`: an organization-level function with the same name is linked instead of duplicated; new names are created as organization-level functions.
- The import response lists functions under `linkedFunctions[].function`; subsequent `GET /v1/chatbots/:id` calls show them merged into `functionDefinitions`.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/import" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fileData": "eyJlbmNyeXB0ZWQiOnRydWUs...",
    "encryptionKey": "3f9c2b7e8a1d4c6f0e5b9a8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b",
    "newName": "Support Bot (staging)"
  }'
```

### Errors

| Status | When                                                                               |
| ------ | ---------------------------------------------------------------------------------- |
| `400`  | `fileData` or `encryptionKey` missing or empty                                     |
| `500`  | Wrong key, corrupted file, checksum mismatch, or an invalid flow definition inside |

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
  "message": "Active text bot set successfully",
  "data": {
    "activeChatbotId": "550e8400-e29b-41d4-a716-446655440000",
    "botType": "text"
  }
}
```

:::

The key in `data` follows `botType`: `activeChatbotId` for `text`, `activeVoiceBotId` for `voice`. Deactivating returns `"Text bot deactivated successfully"` (or `"Voice bot deactivated successfully"`) with the key set to `null`.

> [!TIP]
> To unassign/deactivate, send `"chatbotId": null` with the desired `botType`.

> [!NOTE]
> Only an `llm` chatbot can be set as the voice bot. Flow, code-backed and Meta AI bots have no voice runtime.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/active/bot" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "chatbotId": "550e8400-e29b-41d4-a716-446655440000", "botType": "text" }'
```

### Errors

| Status | When                                                                              |
| ------ | --------------------------------------------------------------------------------- |
| `400`  | `botType` missing or not `text`/`voice`, or `chatbotId` is not a UUID             |
| `500`  | Chatbot not found in your business or organization, or a non-`llm` bot as `voice` |

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
  "message": "Active bots retrieved successfully",
  "data": {
    "activeChatbotId": "550e8400-e29b-41d4-a716-446655440000",
    "activeChatbot": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Support Bot",
      "type": "llm",
      "model": "google/gemini-3.5-flash"
    },
    "activeVoiceBotId": null,
    "activeVoiceBot": null
  }
}
```

:::

`activeChatbot` and `activeVoiceBot` are full [chatbot objects](#the-chatbot-object) (abbreviated above). When no bot is active, the ID field is omitted and the object is `null`.

```bash
curl -X GET "{{API_URL}}/v1/chatbots/active/all" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Live chatbots

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

Live chatbots let you run several text bots at once and split new conversations between them by weight, for example to A/B test two prompts. The single active bot (`POST /v1/chatbots/active/bot`) still acts as the fallback.

:::api
method: PUT
endpoint: /v1/business/live-chatbots
title: Update Live Chatbots
description: Replace the list of live text bots and their traffic weights. Send an empty array to turn weighted routing off and go back to the single active bot.

## Body Parameters

- liveChatbots: array [required] - Entries of `{ "chatbotId": string, "weight": number }`. `weight` is `0` to `100` and relative to the other entries (they do not need to sum to 100). A weight of `0` pauses that bot for new contacts

```request
{
  "liveChatbots": [
    { "chatbotId": "550e8400-e29b-41d4-a716-446655440000", "weight": 70 },
    { "chatbotId": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "weight": 30 }
  ]
}
```

## Response

```response
{
  "message": "Live chatbots config updated successfully",
  "data": {
    "liveChatbots": [
      { "chatbotId": "550e8400-e29b-41d4-a716-446655440000", "weight": 70 },
      { "chatbotId": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "weight": 30 }
    ]
  }
}
```

:::

How a bot is chosen for a contact:

1. If the contact's assigned bot is the active bot, it is used.
2. If no live bots are configured, the active bot is used.
3. If the contact's assigned bot is still in the live list, it stays assigned (sticky, whatever its weight).
4. Otherwise a live bot is picked at random by weight and assigned to the contact. If every weight is `0`, the active bot is used; if there is none either, the bot does not reply.

```bash
curl -X PUT "{{API_URL}}/v1/business/live-chatbots" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "liveChatbots": [ { "chatbotId": "550e8400-e29b-41d4-a716-446655440000", "weight": 100 } ] }'
```

### Errors

| Status | When                                                                                            |
| ------ | ----------------------------------------------------------------------------------------------- |
| `400`  | `liveChatbots` missing, a `weight` outside `0`-`100`, or a `chatbotId` not in your organization |
| `403`  | API key is not a Full access key                                                                |

---

## Assign Chatbot to Contact

:::api
method: PUT
endpoint: /v1/clients/bot/assign
title: Assign Chatbot to Contact
description: Assign a specific chatbot to a contact, or unassign by passing `null`. When assigned, this chatbot handles the contact's conversations instead of the business's active or live bots. The contact is created if it does not exist yet.

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
  "message": "Chatbot assigned to client successfully",
  "data": {
    "clientWaNumber": "919876543210",
    "assignedChatbotId": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

:::

> [!TIP]
> To unassign a chatbot from a contact (revert to the business's bot selection), send `"chatbotId": null`. The response message becomes `"Chatbot assignment removed from client"` and `assignedChatbotId` is `null`.

```bash
curl -X PUT "{{API_URL}}/v1/clients/bot/assign" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "clientWaNumber": "919876543210", "chatbotId": "550e8400-e29b-41d4-a716-446655440000" }'
```

### Errors

| Status | When                                                          |
| ------ | ------------------------------------------------------------- |
| `400`  | `clientWaNumber` missing or invalid, `chatbotId` empty string |
| `403`  | API key lacks `clients:write`                                 |
| `404`  | No chatbot with `chatbotId` in your business or organization  |

---

## Clear Bot Session

:::api
method: PUT
endpoint: /v1/clients/session/clear/:clientWaNumber
title: Clear Bot Session
description: Resets the chatbot's conversation memory for a specific contact. After clearing, the bot no longer references any messages sent before the clear point and starts with a fresh context. Flow bots also restart from the beginning. A private "session cleared" marker message is saved in the chat history to show when the reset happened.

## Path Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)

```request
PUT /v1/clients/session/clear/919876543210
```

## Response

```response
{
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
> The session clear does not delete any messages. It only changes which messages the bot considers as context. All chat history remains visible in the inbox, and a "Bot session cleared" indicator appears in the chat timeline.

```bash
curl -X PUT "{{API_URL}}/v1/clients/session/clear/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Errors

| Status | When                                         |
| ------ | -------------------------------------------- |
| `403`  | API key lacks `clients:write`                |
| `404`  | No contact with this number in your business |

---

## Trigger Chatbot Talk

:::api
method: POST
endpoint: /v1/chatbots/talk
title: Trigger Chatbot Talk
description: Trigger the chatbot to start a conversation with a specific contact. The bot picks up existing chat history as context and sends its response via WhatsApp. The API returns immediately; the bot processes and sends messages asynchronously. If the bot was switched off for the contact, it is switched back on.

## Body Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)
- chatbotId: string - UUID of a specific chatbot to use. If not provided, the contact's assigned bot or the business's bot selection is used
- context: string - Extra context to append to the conversation. Works like follow-up prompts and gives the bot additional instructions or information
- contextLocation: string - Where to append the context. One of `system`, `user`, or `assistant`. Defaults to `user`
- eventType: string - Meta AI bots only: the event name handed to the agent (1 to 256 characters, default `business_event`). Ignored for every other bot type

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
  "message": "Chatbot conversation triggered successfully",
  "data": null
}
```

:::

### Context Location Options

| Value       | Behavior                                                                                |
| ----------- | --------------------------------------------------------------------------------------- |
| `system`    | Appended to the system prompt. Use for bot instructions and directives                  |
| `user`      | Added as a user message at the end of chat history. Appears as if the client said it    |
| `assistant` | Added as an assistant message at the end of chat history. Appears as if the bot said it |

> [!TIP]
> The `context` parameter is optional but useful for giving the bot situational awareness. For example, append a system context like "The customer has been inactive for 3 days, gently follow up" to guide the bot's response.

> [!IMPORTANT]
> **Chatbot selection priority:**
>
> 1. If `chatbotId` is provided, that bot is used **and assigned** to the contact for future conversations.
> 2. If `chatbotId` is not provided, the contact's currently assigned bot is used.
> 3. If no bot is assigned to the contact, the business's bot selection applies: a weighted pick from the [live chatbots](#live-chatbots), or the active bot. The chosen bot is assigned to the contact.

> [!NOTE]
> The request body is strict: unknown fields return `400`. For a Meta AI bot the request is handed to Meta as a business event and the response message is `"Agent event accepted — Meta AI decides what to send"`; Meta decides whether and what to send.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/talk" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientWaNumber": "919876543210",
    "context": "Customer just placed order #12345, ask about delivery preferences",
    "contextLocation": "system"
  }'
```

---

## Process Conversation

:::api
method: POST
endpoint: /v1/chatbots/:chatbotId/process
title: Process Conversation
description: Send messages to a chatbot and get its response. Unlike the Talk endpoint, this does NOT send messages via WhatsApp and does not touch the contact's chat history; it only returns the chatbot's reply. Useful for testing or building custom integrations. Model usage is billed to your AI wallet.

## Path Parameters

- chatbotId: string [required] - Chatbot UUID

## Body Parameters

- messages: array [required] - Conversation messages in OpenAI chat format (see below)
- outputMessageFormat: boolean - Return the reply as structured JSON in the bot's WhatsApp message format (default false)
- clientNumber: string - Contact's WhatsApp number, added to the system prompt for context
- executeFunctions: boolean - Run the bot's functions server-side when the model calls them (default false)

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
  "message": "Chatbot response generated successfully",
  "data": {
    "messages": [
      {
        "role": "assistant",
        "content": "{\"message\":[{\"messageType\":\"text\",\"message\":\"Our business hours are 9 AM to 6 PM, Monday to Friday.\"}]}"
      }
    ],
    "isComplete": true
  }
}
```

:::

### Message Format

Each message in the array has:

| Field          | Type            | Required   | Description                                                                                                                                                                             |
| -------------- | --------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `role`         | string          | Yes        | `user`, `assistant`, `system`, or `tool`                                                                                                                                                |
| `content`      | string or array | Yes\*      | Text, or an array of parts: `{ "type": "text", "text" }` and `{ "type": "image_url", "image_url": { "url", "detail" } }`. \*Optional for an assistant message that carries `tool_calls` |
| `tool_calls`   | array           | No         | Tool calls on an assistant message: `{ "id", "type": "function", "function": { "name", "arguments" } }`                                                                                 |
| `tool_call_id` | string          | For `tool` | The `id` of the tool call this message answers                                                                                                                                          |

The bot's own system prompt is added automatically. If you include a `system` message of your own, it is used instead.

### Response fields

| Field            | Description                                                                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `messages`       | Everything generated during the call: the assistant replies and, when functions were executed, the `tool` messages holding their results |
| `isComplete`     | `true` when the bot produced a final reply. `false` when the turn limit was reached with tool calls still pending                        |
| `isDirectReturn` | `true` when a `directReturn` function ended the turn; its output is the last `tool` message                                              |

### Function calls

- With `executeFunctions: false` (default) the model makes a single turn. If it decides to call a function, the assistant message comes back with `tool_calls` and empty content. Run the function yourself, append a `tool` message with the result (and the assistant message that requested it), and call the endpoint again.
- With `executeFunctions: true` only functions that have `executionDetails` are offered to the model; they are run server-side and the model continues until it produces a final reply or a `directReturn` function ends the turn.

### Structured output

With `outputMessageFormat: true` the assistant `content` is a JSON string shaped like `{ "message": [ ... ] }`, where each item is one WhatsApp message in one of the formats the bot is allowed to send (`sendMsgType`):

```json
{
  "message": [
    { "messageType": "text", "message": "Hi! Which order should I look up?" },
    {
      "messageType": "button",
      "body": "Pick an option",
      "buttons": ["Track order", "Start a return"]
    },
    {
      "messageType": "cta_url",
      "body": "See all orders",
      "button": { "text": "Open orders", "url": "https://example.com/orders" }
    }
  ]
}
```

Bots with `hasTimeout` also return a `followUp` object (`shouldSchedule`, `delaySeconds`, and `followUpType` when `enableFollowUpType` is on). Bots with `enableReply` add a `replyToIndex` to each item.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/550e8400-e29b-41d4-a716-446655440000/process" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{ "role": "user", "content": "Where is order #12345?" }],
    "executeFunctions": true,
    "clientNumber": "919876543210"
  }'
```

### Errors

| Status | When                                                                                                  |
| ------ | ----------------------------------------------------------------------------------------------------- |
| `400`  | `messages` missing, a `tool` message without `tool_call_id`, or a user/system message without content |
| `401`  | Your business is not linked to an organization                                                        |
| `500`  | Chatbot not found, a prepaid AI wallet below the $5 minimum balance, or a model/provider failure      |

---

## Get Bot Results

Every time a bot takes over a conversation with a contact, a result row is created for that contact and bot. Flow bots fill it with the answers collected during the flow; for AI bots you fill it with [AI Results](#run-ai-results).

:::api
method: GET
endpoint: /v1/chatbots/results
title: Get Bot Results
description: List bot results for your business, newest first (up to 50,000 rows). Each row carries the contact, the bot, and the stored result fields flattened to the top level.

## Query Parameters

- chatbotId: string - Only results of this chatbot. For a `journey` bot, results are returned across the whole organization

## Response

```response
{
  "message": "Bot results retrieved successfully",
  "data": [
    {
      "id": 98765,
      "createdAt": "2026-09-01T09:15:00.000Z",
      "clientName": "Rahul Sharma",
      "clientWaNumber": "919876543210",
      "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
      "chatbotName": "Support Bot",
      "intent": "order_status",
      "sentiment": "neutral",
      "order.id": "12345"
    },
    {
      "id": 98764,
      "createdAt": "2026-09-01T08:40:00.000Z",
      "clientName": "Priya Patel",
      "clientWaNumber": "919123456789",
      "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
      "chatbotName": "Support Bot"
    }
  ]
}
```

:::

Nested result objects are flattened with dot-separated keys (`order.id`). Rows without stored data only carry the six base fields.

```bash
curl -X GET "{{API_URL}}/v1/chatbots/results?chatbotId=550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Run AI Results

:::api
method: POST
endpoint: /v1/chatbots/results/ai
title: Run AI Results
description: Analyse the recent WhatsApp conversation of one or more contacts with a model and return structured JSON that matches the schema you provide. Optionally stores the output on existing result rows and saves the settings on a chatbot. Contacts are processed in parallel batches; the call returns when all are done. Model usage is billed to your AI wallet.

## Body Parameters

- clientWaNumbers: array [required] - Entries of `{ "clientWaNumber": string, "botResultId": number }`. At least one. When `botResultId` is given, that result row is updated with the output
- outputFormat: object [required] - `{ "name": string, "strict": boolean, "schema": object }`. `schema` is a JSON Schema object (`type`, `properties`, `required`, `additionalProperties`). `strict` defaults to `true`
- systemPrompt: string - Instructions for the analysis
- model: string - Model ID (default `gpt-5-nano`)
- contextLength: number - Recent messages to analyse per contact (default 10)
- isAddPrivateMessages: boolean - Include private notes in the history (default true)
- temperature: number - Sampling temperature
- maxTokens: number - Maximum output tokens
- reasoningEffort: string - `default`, `none`, `minimal`, `low`, `medium`, `high`, `xhigh`
- verbosity: string - `low`, `medium`, `high`
- chatbotId: string - Save these settings as the bot's `resultConfig` so the dashboard can rerun them
- concurrency: number - Contacts processed at the same time, `1` to `50` (default 50)

```request
{
  "clientWaNumbers": [
    { "clientWaNumber": "919876543210", "botResultId": 98765 },
    { "clientWaNumber": "919123456789" }
  ],
  "outputFormat": {
    "name": "conversation_summary",
    "strict": true,
    "schema": {
      "type": "object",
      "properties": {
        "intent": { "type": "string" },
        "sentiment": { "type": "string", "enum": ["positive", "neutral", "negative"] },
        "orderId": { "type": ["string", "null"] }
      },
      "required": ["intent", "sentiment", "orderId"],
      "additionalProperties": false
    }
  },
  "systemPrompt": "Summarise the conversation and extract the requested fields.",
  "model": "gpt-5-mini",
  "contextLength": 20,
  "isAddPrivateMessages": false,
  "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
  "concurrency": 10
}
```

## Response

```response
{
  "message": "AI results retrieved successfully",
  "data": [
    {
      "intent": "order_status",
      "sentiment": "neutral",
      "orderId": "12345",
      "clientWaNumber": "919876543210",
      "botResultId": 98765
    },
    {
      "clientWaNumber": "919123456789",
      "error": "Failed to process"
    }
  ]
}
```

:::

Each entry is the model's output (nested objects flattened to dot-separated keys) plus the `clientWaNumber` and `botResultId` you sent. A contact that could not be processed comes back with `"error": "Failed to process"` instead of the fields. With `strict: true`, list every property in `required` and set `additionalProperties` to `false`, as the model provider requires.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/results/ai" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientWaNumbers": [{ "clientWaNumber": "919876543210" }],
    "outputFormat": {
      "name": "lead_score",
      "schema": {
        "type": "object",
        "properties": { "score": { "type": "integer" }, "reason": { "type": "string" } },
        "required": ["score", "reason"],
        "additionalProperties": false
      }
    },
    "systemPrompt": "Score this lead from 1 to 10 and explain why."
  }'
```

### Errors

| Status | When                                                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------- |
| `400`  | `clientWaNumbers` empty or invalid, `outputFormat` missing `name` or `schema`, `concurrency` outside `1`-`50` |
| `403`  | API key lacks `chatbots:write`                                                                                |

---

## List Organization Functions

:::api
method: GET
endpoint: /v1/chatbots/functions/org
title: List Organization Functions
description: List the organization-level functions that can be linked to any chatbot in your organization, newest first.

## Query Parameters

- createdBy: string - Only functions created by `human`, `copilot` or `api`

## Response

```response
{
  "message": "Org-level functions retrieved successfully",
  "data": [
    {
      "id": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
      "type": "function",
      "name": "get_order_status",
      "description": "Look up an order by its ID",
      "parameters": {
        "type": "object",
        "properties": { "orderId": { "type": "string" } },
        "required": ["orderId"],
        "additionalProperties": false
      },
      "heltarParameters": null,
      "executionDetails": { "type": "unified_function_event_handlers" },
      "sourceCode": null,
      "env": null,
      "codeLanguage": null,
      "createdBy": "human",
      "orgId": 678,
      "chatbotId": null,
      "createdAt": "2026-08-20T07:00:00.000Z",
      "updatedAt": "2026-08-20T07:00:00.000Z"
    }
  ]
}
```

:::

Returns an empty array when your business is not linked to an organization. Fields are described under [Function definitions](#function-definitions).

```bash
curl -X GET "{{API_URL}}/v1/chatbots/functions/org?createdBy=api" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Execute Function

:::api
method: POST
endpoint: /v1/chatbots/functions/execute
title: Execute Function
description: Run a chatbot function directly with the parameters you supply, without involving the model. Useful to test a function before linking it to a bot. Pass `sourceCode` to run ad-hoc Python code instead of a stored function.

## Body Parameters

- functionId: string [required] - ID of the function to run. Still required when `sourceCode` is given (any non-empty value is accepted in that case)
- parameters: object [required] - Arguments passed to the function
- sourceCode: string - Python code to run instead of the stored function
- env: object - Environment variables for `sourceCode` (default `{}`)

```request
{
  "functionId": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
  "parameters": { "orderId": "12345" }
}
```

## Response

```response
{
  "message": "Function executed successfully",
  "data": {
    "success": true,
    "statusCode": 200,
    "result": {
      "orderId": "12345",
      "status": "shipped",
      "eta": "2026-09-12"
    }
  }
}
```

:::

What runs depends on the function's `executionDetails.type`:

| Type                              | Behaviour                                                                                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `unified_function_event_handlers` | Your code editor deployment is called with `parameters`, `function_name` and your business context; `data` is the function's return value        |
| `lambda_function`                 | The stored `sourceCode` runs in the hosted runtime with the stored `env`; `data` is the runtime result (`success`, `statusCode`, and the output) |
| `api_call`                        | Not supported by this endpoint (the bot still calls such functions during conversations)                                                         |

```bash
curl -X POST "{{API_URL}}/v1/chatbots/functions/execute" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "functionId": "7b1c9d2e-3f4a-4b5c-8d6e-7f8a9b0c1d2e",
    "parameters": { "orderId": "12345" }
  }'
```

To try code before saving it as a function, send it in `sourceCode` (Python) with any non-empty `functionId`; the code runs with `parameters` and `env` and the runtime result is returned in `data`.

### Errors

| Status | When                                                                                                                            |
| ------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `400`  | `functionId` or `parameters` missing                                                                                            |
| `403`  | API key lacks `chatbots:write`                                                                                                  |
| `500`  | Function not found or has no `executionDetails`, `api_call` function, `lambda_function` without code, or the code itself failed |

---

## Extract PDF Text

:::api
method: POST
endpoint: /v1/chatbots/extract-pdf
title: Extract PDF Text
description: Extract the text of a PDF with a vision-capable model, for example to build a knowledge base for a system prompt. Model usage is billed to your AI wallet.

## Body Parameters

- fileData: string [required] - The PDF as a base64 data URI (`data:application/pdf;base64,...`). Maximum 50 MB
- filename: string - File name passed to the model (default `document.pdf`)
- model: string - Vision-capable model to use (default `gpt-4.1-nano`). Models without vision support fall back to the default

```request
{
  "fileData": "data:application/pdf;base64,JVBERi0xLjcKJeLjz9MKMSAwIG9iago8PC...",
  "filename": "return-policy.pdf"
}
```

## Response

```response
{
  "message": "PDF text extracted successfully",
  "data": {
    "text": "Return policy\n\nItems can be returned within 14 days of delivery..."
  }
}
```

:::

If extraction fails the call still returns `200` with `"message": "Failed to extract PDF text"` and an empty `text`.

```bash
curl -X POST "{{API_URL}}/v1/chatbots/extract-pdf" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{ \"fileData\": \"data:application/pdf;base64,$(base64 -w0 return-policy.pdf)\", \"filename\": \"return-policy.pdf\" }"
```

### Errors

| Status | When                                    |
| ------ | --------------------------------------- |
| `400`  | `fileData` missing or larger than 50 MB |
| `403`  | API key lacks `chatbots:write`          |

---

## Wallet

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

Model usage by your chatbots (conversations, AI results, transcription, PDF extraction) is charged in USD to your organization's AI wallet. A prepaid wallet must hold at least $5 for bots to reply. Top-ups are arranged through your account manager.

:::api
method: GET
endpoint: /v1/wallet
title: Get Wallet
description: Get the active AI wallet of your organization.

## Response

```response
{
  "message": "Wallet information retrieved successfully",
  "data": {
    "id": "8c0f4b2e-6d1a-4f3b-9e2c-1a2b3c4d5e6f",
    "orgId": 678,
    "balance": "42.5000000000",
    "availableBalance": "42.5000000000",
    "currency": "USD",
    "walletType": "prepaid",
    "isActive": true,
    "createdAt": "2026-01-10T06:00:00.000Z",
    "updatedAt": "2026-09-09T10:30:00.000Z"
  }
}
```

:::

| Field              | Description                                             |
| ------------------ | ------------------------------------------------------- |
| `balance`          | Current balance in USD, returned as a decimal string    |
| `availableBalance` | Balance available for use, returned as a decimal string |
| `walletType`       | `prepaid`, `postpaid`, or `hybrid`                      |

`data` is `null` when your organization has no active wallet yet.

```bash
curl -X GET "{{API_URL}}/v1/wallet" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/wallet/:walletId/transactions
title: List Wallet Transactions
description: List top-ups and manual adjustments on a wallet, newest first. Usage charges are deducted from the balance directly and do not appear as transactions.

## Path Parameters

- walletId: string [required] - Wallet UUID from `GET /v1/wallet`

## Query Parameters

- limit: number - Maximum rows to return (all rows when omitted)
- offset: number - Rows to skip, for paging

## Response

```response
{
  "message": "Transaction history retrieved successfully",
  "data": [
    {
      "id": "d4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f7a",
      "amount": "25.0000000000",
      "type": "credit",
      "reason": "top_up",
      "status": "completed",
      "balanceAfter": "42.5000000000",
      "description": "Credit of 25USD for top_up",
      "metadata": null,
      "createdAt": "2026-09-01T12:00:00.000Z"
    }
  ]
}
```

:::

| Field                    | Values                                                    |
| ------------------------ | --------------------------------------------------------- |
| `type`                   | `credit`, `debit`                                         |
| `reason`                 | `top_up`, `admin_adjustment`                              |
| `status`                 | `pending`, `completed`, `failed`, `cancelled`, `refunded` |
| `amount`, `balanceAfter` | USD decimal strings                                       |

```bash
curl -X GET "{{API_URL}}/v1/wallet/8c0f4b2e-6d1a-4f3b-9e2c-1a2b3c4d5e6f/transactions?limit=20&offset=0" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Errors

| Status | When                                                              |
| ------ | ----------------------------------------------------------------- |
| `401`  | Your business is not linked to an organization (`GET /v1/wallet`) |
| `403`  | API key is not a Full access or Read-only key                     |
