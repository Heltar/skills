---
title: Calls
description: Place and manage voice calls — WhatsApp, SIP, and AI-agent outbound
icon: Phone
order: 10
---

# Calls API

Initiate voice calls and let your AI voice bot dial customers over WhatsApp or your SIP trunk. All endpoints live under `/v1/calls`.

---

## Initiate a Call

A single endpoint handles every path: employee-initiated WhatsApp calls, SIP calls, and AI-agent outbound calls. The runtime behavior is selected by `callType` + `mode`.

:::api
method: POST
endpoint: /v1/calls/initiate
title: Initiate Call
description: Start a voice call. Combine `callType` and `mode` to pick the channel (WhatsApp / SIP) and who runs the call (direct employee / AI agent).

## Body Parameters

- clientWaNumber: string [required] - Destination number, digits only, with country code (e.g. `919999999999`).
- callType: string - `whatsapp` (default) or `sip`.
- mode: string - `agent` (default — AI voice bot runs the call) or `direct` (employee runs the call).
- chatbotId: string - UUID of the voice bot to use. Falls back to the business's `activeVoiceBotId` when omitted.

```request
{
  "callType": "whatsapp",
  "mode": "agent",
  "clientWaNumber": "919999999999",
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Outbound call initiated",
  "data": {
    "callId": "wacid.IRgg...",
    "roomName": "wactr_xxx",
    "clientWaNumber": "919999999999"
  }
}
```

:::

### Matrix: `callType` × `mode`

| `callType` | `mode`   | Result                                                                                  | Requires                                               |
| ---------- | -------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `whatsapp` | `agent`  | **AI voice bot calls a WhatsApp number.** We dial, the agent handles SDP.               | WhatsApp Business API onboarding + `chatbotId`.        |
| `whatsapp` | `direct` | Employee-initiated WhatsApp call from the browser.                                      | WhatsApp Business API onboarding + a WebRTC `session`. |
| `sip`      | `agent`  | **AI voice bot calls a regular phone** over your SIP trunk.                             | `sipConfig.outboundTrunkId` + `chatbotId`.             |
| `sip`      | `direct` | Employee joins a voice room from the browser; backend dials the phone via SIP for them. | `sipConfig.outboundTrunkId`.                           |

> [!TIP]
> For `agent` mode, if you omit `chatbotId`, the business's `activeVoiceBotId` is used. Set it via the chatbot editor → **Publish as Voice Bot**.

### Outbound WhatsApp (Agent Mode)

Place an AI-driven WhatsApp voice call.

```request
POST /v1/calls/initiate
Authorization: <JWT>
Content-Type: application/json

{
  "callType": "whatsapp",
  "mode": "agent",
  "clientWaNumber": "919999999999",
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

**What happens:**

1. Backend opens a voice session, dispatches the agent into it, and places the call via Meta's Calls API.
2. The response returns `{callId, roomName, clientWaNumber}` — `callId` is Meta's `wacid`, used by follow-up webhooks and terminate calls.
3. When the recipient picks up, Meta fires a `connect` webhook; the backend forwards the SDP answer to complete the WebRTC handshake.
4. The voice bot greets the recipient and runs the conversation.
5. Call cleanup fires automatically via the `terminate` webhook, a session-finished webhook, or `POST /v1/calls/terminate`.

### Outbound SIP (Agent Mode)

Place an AI-driven call to a regular phone number via your SIP trunk.

```request
POST /v1/calls/initiate
Authorization: <JWT>
Content-Type: application/json

{
  "callType": "sip",
  "mode": "agent",
  "clientWaNumber": "919999999999",
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

**Response**:

```json
{
  "code": "OK",
  "message": "SIP call initiated",
  "data": {
    "roomName": "sip-6-out-919999999999-1700000000000",
    "participantSid": "<participant-sid>"
  }
}
```

---

## Terminate a Call

:::api
method: POST
endpoint: /v1/calls/terminate
title: Terminate Call
description: Hang up an active call. For WhatsApp, provide `wacid` (returned by the initiate call). For SIP, provide `roomName`.

## Body Parameters

- callType: string - `whatsapp` (default) or `sip`.
- wacid: string - WhatsApp call id (required when `callType: "whatsapp"`).
- roomName: string - Voice session room name returned by the initiate response (required when `callType: "sip"`).

```request
{
  "callType": "whatsapp",
  "wacid": "wacid.IRgg..."
}
```

## Response

```response
{
  "code": "OK",
  "message": "Call terminated successfully",
  "data": {
    "callId": "wacid.IRgg...",
    "clientWaNumber": "919999999999"
  }
}
```

:::

---

## Test a Voice Bot in the Browser

Spins up a private voice session, dispatches the specified voice bot into it, and returns a join token so the caller can talk to the agent directly from the browser. Used by the **Test Call → Browser** button in the chatbot editor.

:::api
method: POST
endpoint: /v1/calls/test-voice-bot
title: Test Voice Bot (Browser)
description: Create an isolated room with the agent and return a token to join it from the browser.

## Body Parameters

- chatbotId: string - Voice bot to test. Falls back to the business's `activeVoiceBotId` if omitted.

```request
{
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Voice bot test room ready",
  "data": {
    "roomName": "test-6-f4cfa825-1700000000000",
    "token": "<join-jwt>",
    "voiceUrl": "wss://<voice-host>"
  }
}
```

:::

Use the returned `token` + `voiceUrl` (WebSocket URL for the voice session) with a compatible WebRTC client SDK in the browser to join and talk to the agent.

---

## Accept / Pre-Accept / Reject (Employee-Initiated WhatsApp)

These endpoints complete the WebRTC handshake for **employee-initiated** WhatsApp calls. They are not used by `mode: "agent"` (the backend handles SDP automatically).

| Endpoint                    | Use                                                                                  |
| --------------------------- | ------------------------------------------------------------------------------------ |
| `POST /v1/calls/pre-accept` | Send the SDP answer in "ringing" state before picking up. Body: `{wacid, session}`.  |
| `POST /v1/calls/accept`     | Accept the call with an SDP answer. Body: `{wacid, session, callType?}`.             |
| `POST /v1/calls/reject`     | Reject an incoming call. Body: `{wacid, callType?}` or `{roomName, callType:"sip"}`. |

---

## List Call History

:::api
method: GET
endpoint: /v1/calls
title: Get Call Messages
description: Fetch past call records. Filter by direction, time range, or search.

## Query Parameters

- clientWaNumber: string - Filter by destination number.
- direction: string - `incoming` / `outgoing` / `missed`.
- from: string - ISO date-time lower bound.
- to: string - ISO date-time upper bound.
- limit: number - Page size (default 50).
- cursor: string - Pagination cursor returned by a previous response.

:::

---

## Error responses

All endpoints wrap errors in a consistent envelope:

```json
{
  "errorType": "BadRequest",
  "errorMessage": "Active call already exists for this client",
  "errorsValidation": null,
  "errorRaw": null
}
```

Common cases for agent-mode outbound:

| `errorMessage`                                             | Cause                                                                           | Fix                                                                                                         |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `Business WhatsApp credentials not configured`             | `fbAccessToken` or `phoneNumberId` missing on the business.                     | Complete WhatsApp API setup in Settings → **WhatsApp API Setup**.                                           |
| `Active call already exists for this client`               | A live call to this `clientWaNumber` is already in progress.                    | Terminate it via `/v1/calls/terminate`, or wait for it to end. Stale caches auto-clear on the next attempt. |
| `No chatbotId provided and no active voice bot configured` | `mode: "agent"` but neither `chatbotId` was sent nor `activeVoiceBotId` is set. | Pass `chatbotId` in the request, or publish a chatbot as the active voice bot.                              |
| `Chatbot not found`                                        | `chatbotId` doesn't exist under this business/org.                              | Verify the id and that it belongs to the authenticated business.                                            |
| `session is required for direct WhatsApp calls`            | `callType: "whatsapp", mode: "direct"` but no `session` sent.                   | Include `{sdp, sdpType}` from your WebRTC peer.                                                             |

---

## Related

- **[Voice Calls → Voice Bot Integration](/docs/features/calls#voice-bot-integration)** — product-side overview of incoming and outbound bot-handled calls.
- **[Chatbots → Test Voice Bot](/docs/features/chatbots#test-voice-bot)** — UI walkthrough for the in-editor test tool.
