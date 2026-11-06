---
title: Calls
description: Place and manage voice calls — WhatsApp, SIP, and AI-agent outbound
icon: Phone
order: 10
---

# Calls API

Place, answer and manage voice calls. WhatsApp calls run over the WhatsApp Business Calling API on your connected business number; SIP calls run over your own SIP trunk. Either channel can be handled by an employee from the browser or by an AI voice bot.

| Group                 | Endpoints                                                                                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Calls                 | `POST /v1/calls/initiate`, `POST /v1/calls/pre-accept`, `POST /v1/calls/accept`, `POST /v1/calls/reject`, `POST /v1/calls/terminate`, `POST /v1/calls/test-voice-bot`, `GET /v1/calls` |
| Call settings         | `GET /v1/business/call-settings`, `POST /v1/business/call-settings`                                                                                                                    |
| AI voice call records | `GET /v1/voice-calls`, `GET /v1/voice-calls/:callId`                                                                                                                                   |
| SIP trunk             | `POST /v1/sip/setup`, `DELETE /v1/sip/teardown`                                                                                                                                        |

---

## Authentication

All endpoints on this page require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

Endpoints under `/v1/calls` use the `calls:read` scope for `GET` and `calls:write` for `POST`. The call-settings, voice-call and SIP endpoints sit outside the per-resource scope picker; see the note at the top of each of those sections.

See [Authentication](/docs/api/authentication) for full setup instructions.

---

## Initiate a Call

A single endpoint handles every outbound path: employee-initiated WhatsApp calls, SIP calls, and AI-agent outbound calls. The runtime behavior is selected by `callType` + `mode`.

:::api
method: POST
endpoint: /v1/calls/initiate
title: Initiate Call
description: Start a voice call. Combine `callType` and `mode` to pick the channel (WhatsApp / SIP) and who runs the call (direct employee / AI agent).

## Body Parameters

- clientWaNumber: string [required] - Destination phone number with country code, digits only (e.g. `919876543210`). For `callType: "whatsapp"` with `mode: "direct"`, the WhatsApp user ID of a contact who hides their number is also accepted. SIP calls accept phone numbers only.
- callType: string - `whatsapp` (default) or `sip`.
- mode: string - `agent` (default, the AI voice bot runs the call) or `direct` (an employee runs the call from the browser).
- chatbotId: string - UUID of the voice bot to use in `agent` mode. Falls back to the business's active voice bot when omitted.
- session: object - WebRTC SDP offer from your client, `{ "sdpType": "offer", "sdp": "..." }`. Required when `callType` is `whatsapp` and `mode` is `direct`; ignored otherwise.
- bizOpaqueCallbackData: string - Opaque string echoed back in the WhatsApp call webhooks for this call. Direct WhatsApp mode only.
- refId: string - Your own reference id. Returned unchanged as `message.refId` in the direct WhatsApp response.
- integrations: array - Custom data to attach to the call record for webhook forwarding, same shape as on messages (see the [Custom Data in Webhooks guide](/docs/guides/custom-data-in-webhooks)). Direct WhatsApp mode only.

```request
{
  "callType": "whatsapp",
  "mode": "agent",
  "clientWaNumber": "919876543210",
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

## Response

```response
{
  "message": "Outbound call initiated",
  "data": {
    "callId": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
    "roomName": "wactr_8f3a2c1d",
    "clientWaNumber": "919876543210"
  }
}
```

:::

### Matrix: `callType` × `mode`

| `callType` | `mode`   | Result                                                                                    | Requires                                                               |
| ---------- | -------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `whatsapp` | `agent`  | **AI voice bot calls a WhatsApp number.** The platform dials and handles the media setup. | WhatsApp Business API connected + a voice bot (`chatbotId` or active). |
| `whatsapp` | `direct` | Employee-initiated WhatsApp call from the browser.                                        | WhatsApp Business API connected + a WebRTC `session` offer.            |
| `sip`      | `agent`  | **AI voice bot calls a regular phone** over your SIP trunk.                               | SIP trunk configured (`POST /v1/sip/setup`) + a voice bot.             |
| `sip`      | `direct` | Employee joins a voice room from the browser; the platform dials the phone via SIP.       | SIP trunk configured (`POST /v1/sip/setup`).                           |

> [!TIP]
> For `agent` mode, if you omit `chatbotId`, the business's active voice bot is used. Set it via the chatbot editor → **Publish as Voice Bot**.

### Outbound WhatsApp (Agent Mode)

Place an AI-driven WhatsApp voice call.

```bash
curl -X POST "{{API_URL}}/v1/calls/initiate" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "whatsapp",
    "mode": "agent",
    "clientWaNumber": "919876543210",
    "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
  }'
```

**What happens:**

1. The platform opens a voice session, dispatches the voice bot into it, and places the call through the WhatsApp Business Calling API.
2. The response returns `{ callId, roomName, clientWaNumber }`. `callId` is the WhatsApp call id (`wacid.…`); use it as `wacid` in `POST /v1/calls/terminate` and to match the call in webhooks and `GET /v1/calls`.
3. When the recipient picks up, WhatsApp sends a `connect` event; the platform completes the media handshake for the bot.
4. The voice bot greets the recipient and runs the conversation. The call is recorded.
5. Cleanup runs automatically on the WhatsApp `terminate` event, when the voice session ends, or on `POST /v1/calls/terminate`.

Only one live call per destination number is allowed at a time; a second request returns `400 Active call already exists for this client`.

### Outbound WhatsApp (Direct Mode)

Send your WebRTC SDP offer and drive the call from your own client. The response is the stored call record plus the contact.

```bash
curl -X POST "{{API_URL}}/v1/calls/initiate" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "whatsapp",
    "mode": "direct",
    "clientWaNumber": "919876543210",
    "session": { "sdpType": "offer", "sdp": "v=0\r\no=- 4611731400430051336 2 IN IP4 127.0.0.1\r\n..." },
    "refId": "crm-call-12345"
  }'
```

**Response:**

```json
{
  "message": "Call initiated successfully!",
  "data": {
    "client": {
      "clientWaNumber": "919876543210",
      "username": "Alice",
      "isOpen": true,
      "countryCode": "91"
    },
    "isNewClient": false,
    "message": {
      "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "clientWaNumber": "919876543210",
      "timestamp": "2026-09-09T10:15:00.000Z",
      "status": "waiting",
      "type": "interactive",
      "body": "Outgoing voice call",
      "interactive": {
        "type": "call",
        "direction": "BUSINESS_INITIATED",
        "duration": null,
        "callEvent": [
          { "event": "initiate", "timestamp": "2026-09-09T10:15:00.000Z" }
        ]
      },
      "sentByName": "Ravi",
      "refId": "crm-call-12345"
    }
  }
}
```

`message.wamid` is the WhatsApp call id. The recipient's SDP answer arrives on the `connect` webhook event (see [Inbound calls](#inbound-calls) for the event shape); apply it to your peer connection to complete the handshake.

### Outbound SIP (Agent Mode)

Place an AI-driven call to a regular phone number via your SIP trunk.

```bash
curl -X POST "{{API_URL}}/v1/calls/initiate" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "sip",
    "mode": "agent",
    "clientWaNumber": "919876543210",
    "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
  }'
```

**Response:**

```json
{
  "message": "SIP call initiated",
  "data": {
    "roomName": "sip-12345-out-919876543210-1757412900000",
    "participantSid": "PA_7Kx2mQ9vL4Rt"
  }
}
```

With `mode: "direct"` the response additionally carries `token` and `livekitUrl`; connect a WebRTC client to `livekitUrl` with `token` to join the room while the phone is dialled.

```json
{
  "message": "SIP call initiated",
  "data": {
    "roomName": "sip-12345-out-919876543210-1757412900000",
    "token": "<join-token>",
    "livekitUrl": "wss://voice.example.com",
    "participantSid": "PA_7Kx2mQ9vL4Rt"
  }
}
```

SIP calls ring for up to 45 seconds and are capped at 10 minutes. If a dial prefix is configured on the trunk, it is prepended to the national number; otherwise the destination is dialled in international format (`+919876543210`). Use `roomName` with `POST /v1/calls/terminate` (`callType: "sip"`) to hang up.

---

## Inbound calls

When a customer calls your WhatsApp business number, WhatsApp notifies the platform with a `connect` event that carries the caller's SDP offer. What happens next depends on your setup:

- **A voice bot is published for the business.** The platform answers automatically and the bot runs the call. There is nothing to do; the call shows up in `GET /v1/calls` and, once processed, in `GET /v1/voice-calls`.
- **No voice bot.** The call rings in the Inbox. To answer it from your own client, complete the WebRTC handshake with the endpoints below: `pre-accept` (answer while still ringing, recommended) or `accept`, or `reject` to decline. Use `terminate` to hang up an answered call.

If you have a webhook URL subscribed to the `metaWebhooks` field type (see [Webhooks](/docs/api/webhooks)), the raw notification is forwarded to you as-is. Call events arrive in `value.calls[]` with `"field": "calls"`:

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "field": "calls",
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "15550001234",
              "phone_number_id": "106540352242922"
            },
            "contacts": [
              { "profile": { "name": "Alice" }, "wa_id": "919876543210" }
            ],
            "calls": [
              {
                "id": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
                "from": "919876543210",
                "to": "15550001234",
                "event": "connect",
                "timestamp": "1757412900",
                "direction": "USER_INITIATED",
                "session": { "sdp_type": "offer", "sdp": "v=0\r\no=- ..." }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

| Field                      | Description                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `id`                       | WhatsApp call id (`wacid.…`). Pass it as `wacid` to the endpoints below.                                                 |
| `event`                    | `connect` when the call is set up (carries `session`), `terminate` when it ends.                                         |
| `direction`                | `USER_INITIATED` (inbound) or `BUSINESS_INITIATED` (outbound).                                                           |
| `from` / `to`              | Caller and callee numbers. For contacts who hide their number, `from_user_id` / `to_user_id` carry the user ID instead.  |
| `session`                  | `{ sdp_type, sdp }`. An `offer` on an inbound `connect`; the `answer` on the `connect` event of an outbound direct call. |
| `status`                   | On `terminate`: `COMPLETED` or `FAILED`.                                                                                 |
| `start_time` / `end_time`  | On `terminate`: UNIX timestamps of the media session.                                                                    |
| `duration`                 | On `terminate`: call length in seconds. An inbound `terminate` without `duration` is a missed call.                      |
| `biz_opaque_callback_data` | Echo of the `bizOpaqueCallbackData` you sent, if any.                                                                    |

Every event is appended to the call's timeline; `GET /v1/calls` returns it as `callEvents[]`.

:::api
method: POST
endpoint: /v1/calls/pre-accept
title: Pre-accept Call
description: Answer an inbound WhatsApp call while it is still ringing by sending your SDP answer early, then accept it. Fastest way to connect.

## Body Parameters

- wacid: string [required] - WhatsApp call id from the `connect` event.
- session: object [required] - Your SDP answer, `{ "sdpType": "answer", "sdp": "..." }`.
- bizOpaqueCallbackData: string - Opaque string echoed back in the call webhooks.

```request
{
  "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
  "session": { "sdpType": "answer", "sdp": "v=0\r\no=- ..." }
}
```

## Response

```response
{
  "message": "Call pre-accepted successfully!",
  "data": {
    "cleanMessage": {
      "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "clientWaNumber": "919876543210",
      "timestamp": "2026-09-09T10:15:00.000Z",
      "status": "received",
      "type": "interactive",
      "body": "Missed call",
      "interactive": {
        "type": "call",
        "direction": "USER_INITIATED",
        "duration": null,
        "callEvent": [{ "event": "connect", "timestamp": "2026-09-09T10:15:00.000Z" }]
      }
    },
    "clientWaNumber": "919876543210"
  }
}
```

:::

> [!NOTE]
> This request sends the pre-accept and then the accept for the same call, so a separate `POST /v1/calls/accept` is not needed after it. `cleanMessage` is the stored call record (its `body` is updated to `Incoming voice call` once the call ends with a duration); the key is omitted when no record matches `wacid`.

```bash
curl -X POST "{{API_URL}}/v1/calls/pre-accept" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
    "session": { "sdpType": "answer", "sdp": "v=0\r\no=- ..." }
  }'
```

:::api
method: POST
endpoint: /v1/calls/accept
title: Accept Call
description: Accept an inbound call. For WhatsApp, send your SDP answer. For a SIP or web-chat widget call, send the `roomName` to receive a join token for the voice room.

## Body Parameters

- callType: string - `whatsapp` (default), `sip`, or `web` (web-chat widget call).
- wacid: string - WhatsApp call id. Required when `callType` is `whatsapp`.
- session: object - Your SDP answer, `{ "sdpType": "answer", "sdp": "..." }`. Required when `callType` is `whatsapp`.
- roomName: string - Voice room of the call. Required when `callType` is `sip` or `web`.
- bizOpaqueCallbackData: string - Opaque string echoed back in the WhatsApp call webhooks.

```request
{
  "callType": "whatsapp",
  "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
  "session": { "sdpType": "answer", "sdp": "v=0\r\no=- ..." }
}
```

## Response

```response
{
  "message": "Call accepted successfully!",
  "data": {
    "cleanMessage": {
      "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "clientWaNumber": "919876543210",
      "status": "received",
      "type": "interactive",
      "interactive": { "type": "call", "direction": "USER_INITIATED", "duration": null, "callEvent": [] }
    },
    "clientWaNumber": "919876543210"
  }
}
```

:::

For `callType: "sip"` or `"web"` the response carries a join token instead. Connect a WebRTC client to `livekitUrl` with `token`; recording starts when you join.

```json
{
  "message": "SIP call accepted",
  "data": {
    "roomName": "sip-12345-in-919876543210-1757412900000",
    "token": "<join-token>",
    "livekitUrl": "wss://voice.example.com"
  }
}
```

```bash
curl -X POST "{{API_URL}}/v1/calls/accept" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "sip",
    "roomName": "sip-12345-in-919876543210-1757412900000"
  }'
```

:::api
method: POST
endpoint: /v1/calls/reject
title: Reject Call
description: Decline an inbound call. For WhatsApp, provide `wacid`. For a SIP or web-chat widget call, provide `roomName`; the room is closed.

## Body Parameters

- callType: string - `whatsapp` (default), `sip`, or `web`.
- wacid: string - WhatsApp call id. Required when `callType` is `whatsapp`.
- roomName: string - Voice room of the call. Required when `callType` is `sip` or `web`.

```request
{
  "callType": "whatsapp",
  "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA=="
}
```

## Response

```response
{
  "message": "Call rejected successfully!",
  "data": {
    "cleanMessage": {
      "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "clientWaNumber": "919876543210",
      "status": "received",
      "type": "interactive",
      "interactive": { "type": "call", "direction": "USER_INITIATED", "duration": null, "callEvent": [] }
    },
    "clientWaNumber": "919876543210"
  }
}
```

:::

For `callType: "sip"` or `"web"` the response is `{ "message": "SIP call rejected", "data": { "roomName": "..." } }`.

```bash
curl -X POST "{{API_URL}}/v1/calls/reject" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA=="
  }'
```

`roomName` values are bound to your business; passing a room that belongs to another business returns `403 Forbidden`.

---

## Terminate a Call

:::api
method: POST
endpoint: /v1/calls/terminate
title: Terminate Call
description: Hang up an active call. For WhatsApp, provide `wacid` (returned by the initiate call or the `connect` event). For a SIP or web-chat widget call, provide `roomName`.

## Body Parameters

- callType: string - `whatsapp` (default), `sip`, or `web`.
- wacid: string - WhatsApp call id. Required when `callType` is `whatsapp`.
- roomName: string - Voice room returned by the initiate response. Required when `callType` is `sip` or `web`.

```request
{
  "callType": "whatsapp",
  "wacid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA=="
}
```

## Response

```response
{
  "message": "Call terminated successfully!",
  "data": {
    "cleanMessage": {
      "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "clientWaNumber": "919876543210",
      "status": "waiting",
      "type": "interactive",
      "body": "Outgoing voice call (AI Agent)",
      "interactive": {
        "type": "call",
        "direction": "BUSINESS_INITIATED",
        "duration": null,
        "callEvent": [{ "event": "initiate", "timestamp": "2026-09-09T10:15:00.000Z" }]
      }
    },
    "clientWaNumber": "919876543210"
  }
}
```

:::

For `callType: "sip"` or `"web"` the response is `{ "message": "SIP call terminated", "data": { "roomName": "..." } }` and the room is closed.

```bash
curl -X POST "{{API_URL}}/v1/calls/terminate" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "sip",
    "roomName": "sip-12345-out-919876543210-1757412900000"
  }'
```

---

## Test a Voice Bot in the Browser

Spins up a private voice session, dispatches the specified voice bot into it, and returns a join token so the caller can talk to the agent directly from the browser. Used by the **Test Call → Browser** button in the chatbot editor.

:::api
method: POST
endpoint: /v1/calls/test-voice-bot
title: Test Voice Bot (Browser)
description: Create an isolated room with the agent and return a token to join it from the browser.

## Body Parameters

- chatbotId: string - Voice bot to test. Falls back to the business's active voice bot if omitted.

```request
{
  "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
}
```

## Response

```response
{
  "message": "Voice bot test room ready",
  "data": {
    "roomName": "test-12345-f4cfa825-406c-45c4-a548-dfd154e07f14-1757412900000",
    "token": "<join-token>",
    "voiceUrl": "wss://voice.example.com"
  }
}
```

:::

Use the returned `token` + `voiceUrl` (WebSocket URL for the voice session) with a compatible WebRTC client SDK in the browser to join and talk to the agent. The room closes on its own 30 seconds after the last participant leaves.

```bash
curl -X POST "{{API_URL}}/v1/calls/test-voice-bot" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14" }'
```

---

## List Call History

:::api
method: GET
endpoint: /v1/calls
title: Get Call Messages
description: Fetch past call records for the business, newest first. Covers inbound, outbound, missed, WhatsApp and SIP calls.

## Query Parameters

- limit: number - Page size, 1 to 50000. Omit to return every call in one response. A value below 1 falls back to 50.
- page: number - 1-based page number, max 10000 (default 1). Only applies when `limit` is set.

## Response

```response
{
  "message": "Call messages retrieved successfully",
  "data": {
    "calls": [
      {
        "wamid": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
        "clientWaNumber": "919876543210",
        "username": "Alice",
        "timestamp": "2026-09-09T10:15:00.000Z",
        "status": "received",
        "direction": "USER_INITIATED",
        "callEvents": [
          { "event": "connect", "timestamp": "2026-09-09T10:15:00.000Z" },
          {
            "event": "terminate",
            "timestamp": "2026-09-09T10:17:05.000Z",
            "status": "COMPLETED",
            "startTime": "2026-09-09T10:15:02.000Z",
            "endTime": "2026-09-09T10:17:05.000Z",
            "duration": 123
          }
        ],
        "duration": 123,
        "callType": "incoming",
        "phoneNumberId": "106540352242922",
        "awsLink": "https://storage.example.com/voice-recordings/incoming-call-12345.mp4"
      },
      {
        "wamid": "sip-12345-out-919876543210-1757412000000",
        "clientWaNumber": "919876543210",
        "username": "Alice",
        "timestamp": "2026-09-09T10:00:00.000Z",
        "status": "delivered",
        "direction": "BUSINESS_INITIATED",
        "callEvents": [
          { "event": "initiate", "timestamp": "2026-09-09T10:00:00.000Z" },
          { "event": "terminate", "timestamp": "2026-09-09T10:01:10.000Z", "duration": 58 }
        ],
        "duration": 58,
        "callType": "outgoing",
        "phoneNumberId": "106540352242922",
        "awsLink": "https://storage.example.com/voice-recordings/sip-12345-out-919876543210-1757412000000.mp4"
      }
    ]
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/calls?limit=50&page=1" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Call record fields

| Field            | Description                                                                                                                                  |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `wamid`          | Call id: the WhatsApp call id (`wacid.…`) for WhatsApp calls, the `roomName` for SIP calls.                                                  |
| `clientWaNumber` | The other party's number (or WhatsApp user ID).                                                                                              |
| `username`       | Contact name from your contact list; falls back to `clientWaNumber`.                                                                         |
| `timestamp`      | When the call record was created (ISO 8601).                                                                                                 |
| `status`         | `received` for inbound calls; the outbound record status (`waiting`, `delivered`, `failed`, ...) otherwise.                                  |
| `direction`      | `USER_INITIATED`, `BUSINESS_INITIATED`, or `UNKNOWN`.                                                                                        |
| `callEvents`     | Timeline of events: `initiate` / `connect` / `terminate` with `status`, `startTime`, `endTime`, `duration` and `failureReason` when present. |
| `duration`       | Seconds. The recording length once the recording is processed; otherwise the duration reported by WhatsApp. `null` for missed calls.         |
| `callType`       | `incoming`, `outgoing`, or `missed` (inbound with no duration).                                                                              |
| `phoneNumberId`  | Your WhatsApp business phone number id.                                                                                                      |
| `awsLink`        | Recording URL, or `null` when no recording exists.                                                                                           |

Invalid `page` or `limit` values return `422 ValidationError`.

---

## Call settings

Read and update the WhatsApp calling settings of your connected business number: whether customers can call you, the call button visibility, business hours, callback permission requests and WhatsApp's own SIP routing. These settings live on WhatsApp; the API forwards them and returns WhatsApp's response inside `data`.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: GET
endpoint: /v1/business/call-settings
title: Get Call Settings
description: Fetch the current calling settings of the business phone number from WhatsApp.

## Response

```response
{
  "message": "Successfully fetched call settings!",
  "data": {
    "calling": {
      "status": "ENABLED",
      "call_icon_visibility": "DEFAULT",
      "callback_permission_status": "ENABLED",
      "call_hours": {
        "status": "ENABLED",
        "timezone_id": "Asia/Kolkata",
        "weekly_operating_hours": [
          { "day_of_week": "MONDAY", "open_time": "0900", "close_time": "1800" },
          { "day_of_week": "TUESDAY", "open_time": "0900", "close_time": "1800" }
        ],
        "holiday_schedule": [
          { "date": "2026-10-20", "start_time": "0000", "end_time": "2359" }
        ]
      },
      "sip": { "status": "DISABLED" }
    }
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/business/call-settings" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

:::api
method: POST
endpoint: /v1/business/call-settings
title: Update Call Settings
description: Update the calling settings of the business phone number on WhatsApp. Send only the keys you want to change inside `calling`.

## Body Parameters

- calling: object [required] - Calling settings to apply. See the fields table below.

```request
{
  "calling": {
    "status": "ENABLED",
    "call_icon_visibility": "DEFAULT",
    "callback_permission_status": "ENABLED",
    "call_hours": {
      "status": "ENABLED",
      "timezone_id": "Asia/Kolkata",
      "weekly_operating_hours": [
        { "day_of_week": "MONDAY", "open_time": "0900", "close_time": "1800" },
        { "day_of_week": "TUESDAY", "open_time": "0900", "close_time": "1800" },
        { "day_of_week": "WEDNESDAY", "open_time": "0900", "close_time": "1800" },
        { "day_of_week": "THURSDAY", "open_time": "0900", "close_time": "1800" },
        { "day_of_week": "FRIDAY", "open_time": "0900", "close_time": "1800" }
      ],
      "holiday_schedule": [
        { "date": "2026-10-20", "start_time": "0000", "end_time": "2359" }
      ]
    }
  }
}
```

## Response

```response
{
  "message": "Successfully updated call settings!",
  "data": {
    "success": true
  }
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/business/call-settings" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "calling": {
      "status": "ENABLED",
      "call_icon_visibility": "DEFAULT"
    }
  }'
```

### `calling` fields

| Field                                 | Type   | Values / format                                                                                                    |
| ------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------ |
| `status`                              | string | `ENABLED` or `DISABLED`. Master switch for inbound calls.                                                          |
| `call_icon_visibility`                | string | `DEFAULT` (show the call button) or `DISABLE_ALL` (hide it).                                                       |
| `callback_permission_status`          | string | `ENABLED` or `DISABLED`. Whether you can ask customers for permission to call them back.                           |
| `call_hours.status`                   | string | `ENABLED` or `DISABLED`. Required when `call_hours` is present.                                                    |
| `call_hours.timezone_id`              | string | IANA timezone, e.g. `Asia/Kolkata`. Required when `call_hours` is present.                                         |
| `call_hours.weekly_operating_hours[]` | array  | `{ day_of_week, open_time, close_time }`. `day_of_week` is `MONDAY` … `SUNDAY`; times are 24-hour `HHMM` (`0900`). |
| `call_hours.holiday_schedule[]`       | array  | Up to 20 overrides: `{ date: "YYYY-MM-DD", start_time: "HHMM", end_time: "HHMM" }`.                                |
| `sip.status`                          | string | `ENABLED` or `DISABLED`. WhatsApp's SIP routing of WhatsApp calls; unrelated to the SIP trunk section below.       |
| `sip.servers[]`                       | array  | `{ hostname, port?, request_uri_user_params? }` for WhatsApp SIP routing.                                          |

| Status | `errorMessage`                              | Cause                                                         |
| ------ | ------------------------------------------- | ------------------------------------------------------------- |
| 400    | `Phone number ID or access token not found` | WhatsApp Business API is not connected for this business.     |
| 400    | Validation error                            | A value is outside the allowed enum or time/date format.      |
| 400    | `Failed to update call settings`            | WhatsApp rejected the change; its error is in `errorRaw`.     |
| 403    | `API key does not have the required scope`  | Key created with a per-resource scope instead of Full access. |

---

## AI voice call records

Every call that the platform records produces a voice-call record: voice-bot calls on WhatsApp and SIP, and SIP or web-chat widget calls answered by an employee. The record combines billing (recording-based duration and billed minutes, recording URL) with conversation analytics (turns, latencies, tool calls) and the full session transcript.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: GET
endpoint: /v1/voice-calls
title: List Voice Calls
description: List voice-call records for the business, newest first, with offset pagination.

## Query Parameters

- limit: number - Page size, max `100` (default `50`).
- offset: number - Number of records to skip (default `0`).

## Response

```response
{
  "message": "Voice calls listed",
  "data": {
    "calls": [
      {
        "id": 98765,
        "businessId": 12345,
        "callId": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
        "clientWaNumber": "919876543210",
        "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14",
        "model": "gpt-4o-mini",
        "agentMode": "heltar_voice",
        "durationSeconds": 123,
        "billedMinutes": 3,
        "recordingUrl": "https://storage.example.com/voice-recordings/incoming-call-12345.mp4",
        "direction": "inbound",
        "participantCount": 2,
        "userTurns": 6,
        "agentTurns": 7,
        "interruptions": 1,
        "avgResponseLatencyMs": 840,
        "minResponseLatencyMs": 610,
        "maxResponseLatencyMs": 1320,
        "totalUserSpeechMs": 41200,
        "totalAgentSpeechMs": 63800,
        "toolCallsTotal": 2,
        "toolCallsSuccess": 2,
        "toolCallsFailed": 0,
        "createdAt": "2026-09-09T10:17:10.000Z"
      }
    ],
    "total": 1,
    "limit": 50,
    "offset": 0
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/voice-calls?limit=50&offset=0" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

List items carry the same fields as the single-record response below, including the JSON blobs (`toolCallDetails`, `rawAgentInfo`, `sessionReport`), which are omitted above for brevity.

:::api
method: GET
endpoint: /v1/voice-calls/:callId
title: Get Voice Call
description: Fetch one voice-call record, including the transcript and per-turn metrics.

## Path Parameters

- callId: string [required] - The record's `callId` as returned by the list endpoint. For a voice-bot call on WhatsApp this is the WhatsApp call id (`wacid.…`); for a SIP call it is the `roomName` returned when the call was initiated.

## Response

```response
{
  "message": "Voice call fetched",
  "data": {
    "id": 98765,
    "businessId": 12345,
    "callId": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
    "clientWaNumber": "919876543210",
    "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14",
    "model": "gpt-4o-mini",
    "agentMode": "heltar_voice",
    "durationSeconds": 123,
    "billedMinutes": 3,
    "recordingUrl": "https://storage.example.com/voice-recordings/incoming-call-12345.mp4",
    "direction": "inbound",
    "participantCount": 2,
    "userTurns": 6,
    "agentTurns": 7,
    "interruptions": 1,
    "avgResponseLatencyMs": 840,
    "minResponseLatencyMs": 610,
    "maxResponseLatencyMs": 1320,
    "totalUserSpeechMs": 41200,
    "totalAgentSpeechMs": 63800,
    "toolCallsTotal": 2,
    "toolCallsSuccess": 2,
    "toolCallsFailed": 0,
    "toolCallDetails": [
      {
        "name": "lookup_order",
        "arguments": "{\"orderId\":\"12345\"}",
        "result": "{\"status\":\"shipped\"}",
        "durationMs": 412,
        "isError": false,
        "timestamp": 1757412961
      }
    ],
    "rawAgentInfo": { "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14", "model": "gpt-4o-mini" },
    "sessionReport": {
      "room": "wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==",
      "chat_history": {
        "items": [
          { "id": "msg_1", "type": "message", "role": "assistant", "content": ["Hi, this is the support desk. How can I help?"], "created_at": 1757412903 },
          { "id": "msg_2", "type": "message", "role": "user", "content": ["I want to check order 12345."], "created_at": 1757412910 },
          { "id": "fc_1", "type": "function_call", "name": "lookup_order", "arguments": "{\"orderId\":\"12345\"}", "call_id": "call_1" },
          { "id": "fco_1", "type": "function_call_output", "call_id": "call_1", "output": "{\"status\":\"shipped\"}", "is_error": false },
          { "id": "msg_3", "type": "message", "role": "assistant", "content": ["Order #12345 has shipped and arrives tomorrow."], "created_at": 1757412915 }
        ]
      },
      "usage": [{ "model": "gpt-4o-mini", "type": "llm", "input_tokens": 1820, "output_tokens": 260 }]
    },
    "createdAt": "2026-09-09T10:17:10.000Z"
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/voice-calls/wacid.HBgMOTE5ODc2NTQzMjEwFQIAERgSNzYxRjE4Q0Q2QjYwRkQwN0FCAA==" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Record fields

| Field                                                                  | Description                                                                                                                                                                              |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `callId`                                                               | Call identifier (see the path parameter above).                                                                                                                                          |
| `clientWaNumber`, `chatbotId`                                          | The other party and the voice bot that handled the call (`chatbotId` absent for employee-handled calls).                                                                                 |
| `model`                                                                | Model used by the bot, or `human-agent` for employee-handled calls.                                                                                                                      |
| `agentMode`                                                            | `heltar_voice`, `openai_realtime`, `traditional`, `elevenlabs`, or `human-agent`.                                                                                                        |
| `durationSeconds`, `billedMinutes`                                     | Length of the recording, and minutes billed (rounded up: 61 s = 2 min).                                                                                                                  |
| `recordingUrl`                                                         | URL of the audio recording.                                                                                                                                                              |
| `direction`                                                            | `inbound` or `outbound`.                                                                                                                                                                 |
| `participantCount`, `userTurns`, `agentTurns`, `interruptions`         | Conversation shape.                                                                                                                                                                      |
| `avgResponseLatencyMs`, `minResponseLatencyMs`, `maxResponseLatencyMs` | Bot response latency, end of user speech to start of bot speech.                                                                                                                         |
| `totalUserSpeechMs`, `totalAgentSpeechMs`                              | Talk time per side.                                                                                                                                                                      |
| `toolCallsTotal`, `toolCallsSuccess`, `toolCallsFailed`                | Tool-call counts; `toolCallDetails[]` lists each call with `name`, `arguments`, `result`, `durationMs`, `isError`, `timestamp`.                                                          |
| `sessionReport.chat_history.items[]`                                   | The transcript. `type` is `message` (with `role` and `content[]`), `function_call`, `function_call_output`, or `agent_handoff`; messages may carry `interrupted` and per-turn `metrics`. |
| `sessionReport.usage[]`                                                | Token usage per model.                                                                                                                                                                   |
| `rawAgentInfo`                                                         | The bot's full end-of-call report as received.                                                                                                                                           |
| `createdAt`                                                            | When the record was first written (ISO 8601).                                                                                                                                            |

> [!NOTE]
> A record is written in two steps. Billing fields (`durationSeconds`, `billedMinutes`, `recordingUrl`, `direction`) are filled once the recording has been processed, shortly after the call ends; analytics fields and `sessionReport` are filled when the bot's session closes. A record read right after hang-up may still show zeros or lack a transcript. Poll again after a short delay.

| Status | `errorMessage`                             | Cause                                                         |
| ------ | ------------------------------------------ | ------------------------------------------------------------- |
| 400    | `callId is required`                       | Empty path parameter.                                         |
| 403    | `Access denied`                            | The record belongs to another business.                       |
| 404    | `No call found for this callId`            | No record with that `callId` (yet).                           |
| 403    | `API key does not have the required scope` | Key created with a per-resource scope instead of Full access. |

---

## SIP trunk

Connect your own SIP trunk so the voice bot (or your employees) can call regular phone numbers, and so inbound calls on that trunk reach the platform. `POST /v1/calls/initiate` with `callType: "sip"` requires this to be set up. For the dashboard walkthrough, provider field mapping, transport cheat-sheet and troubleshooting, see [SIP Calling Setup](/docs/features/settings/sip).

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: POST
endpoint: /v1/sip/setup
title: Set Up SIP Trunk
description: Provision inbound and outbound SIP trunks for the business and link them to your provider. Calling this again replaces the existing configuration.

## Body Parameters

- provider: string [required] - `twilio`, `telnyx`, `vonage`, or `custom`.
- address: string [required] - Your provider's SIP server hostname, optionally with a port (e.g. `sip.example.com` or `sip.example.com:5061`). No `sip:` prefix.
- countryCode: number [required] - Country code of the caller-ID number (e.g. `91`). A numeric string is accepted.
- bizWhatsappNumber: string [required] - Caller-ID phone number without the country code (e.g. `9876543210`). It must be attached to the trunk on the provider side.
- authUsername: string - SIP authentication username, if your provider requires credentials.
- authPassword: string - SIP authentication password. Sent to the trunk only; never stored in or returned by the API.
- dialPrefix: string - Digits prepended to the destination's national number when dialling out (carrier access code). Omit to dial in international `+` format.
- transport: string - `auto` (default), `udp`, `tcp`, or `tls`. When omitted and `address` ends with `:5061`, `tls` is selected.

```request
{
  "provider": "custom",
  "address": "sip.example.com:5061",
  "countryCode": 91,
  "bizWhatsappNumber": "9876543210",
  "authUsername": "sip-user",
  "authPassword": "********",
  "transport": "tls"
}
```

## Response

```response
{
  "message": "SIP configured successfully",
  "data": {
    "inboundTrunkId": "ST_8h2kd93jfq1x",
    "outboundTrunkId": "ST_4mz7pw0dnc5b",
    "dispatchRuleId": "SDR_3k9d02maq7ve",
    "provider": "custom",
    "address": "sip.example.com:5061",
    "phoneNumber": "9876543210",
    "countryCode": 91,
    "transport": "tls"
  }
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/sip/setup" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "twilio",
    "address": "your-trunk.pstn.twilio.com",
    "countryCode": 91,
    "bizWhatsappNumber": "9876543210",
    "authUsername": "sip-user",
    "authPassword": "********"
  }'
```

The response is the stored SIP configuration (also returned as `dialPrefix` when set). Credentials are never included. Inbound calls on the trunk are routed to the business and, when a voice bot is published, answered by it.

:::api
method: DELETE
endpoint: /v1/sip/teardown
title: Remove SIP Trunk
description: Delete the business's SIP trunks and clear the stored configuration. SIP calls stop working until set up again.

## Response

```response
{
  "message": "SIP configuration removed",
  "data": null
}
```

:::

```bash
curl -X DELETE "{{API_URL}}/v1/sip/teardown" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

| Status | `errorMessage`                             | Cause                                                                                    |
| ------ | ------------------------------------------ | ---------------------------------------------------------------------------------------- |
| 400    | Validation error                           | Unknown `provider`/`transport`, empty `address`, or an extra field (the body is strict). |
| 404    | `No SIP configuration found`               | Teardown called with no SIP configuration stored.                                        |
| 403    | `API key does not have the required scope` | Key created with a per-resource scope instead of Full access.                            |

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

Common cases:

| `errorMessage`                                                                                                                           | Cause                                                                             | Fix                                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `Business WhatsApp credentials not configured`                                                                                           | WhatsApp Business API is not connected for this business.                         | Complete WhatsApp API setup in Settings → **WhatsApp API Setup**.                                           |
| `Active call already exists for this client`                                                                                             | A live call to this `clientWaNumber` is already in progress.                      | Terminate it via `/v1/calls/terminate`, or wait for it to end. Stale state auto-clears on the next attempt. |
| `No chatbotId provided and no active voice bot configured`                                                                               | `mode: "agent"` but neither `chatbotId` was sent nor a voice bot is published.    | Pass `chatbotId` in the request, or publish a chatbot as the active voice bot.                              |
| `No voice bot configured`                                                                                                                | Same as above, for `callType: "sip"`.                                             | Pass `chatbotId`, or publish a voice bot.                                                                   |
| `Chatbot not found`                                                                                                                      | `chatbotId` doesn't exist under this business/org.                                | Verify the id and that it belongs to the authenticated business.                                            |
| `session is required for direct WhatsApp calls`                                                                                          | `callType: "whatsapp", mode: "direct"` but no `session` sent.                     | Include `{ sdpType: "offer", sdp }` from your WebRTC peer.                                                  |
| `wacid is required for WhatsApp calls, roomName for SIP/web calls`                                                                       | Accept / reject / terminate body is missing the id for the chosen `callType`.     | Send `wacid` for `whatsapp`, `roomName` for `sip` / `web`.                                                  |
| `SIP is not configured. Run setup first.`                                                                                                | `callType: "sip"` without a SIP trunk.                                            | Call `POST /v1/sip/setup` (or Settings → **SIP Calling**).                                                  |
| `Invalid destination phone number`                                                                                                       | `callType: "sip"` with a number that cannot be normalised, or a WhatsApp user ID. | Send a phone number with country code, digits only.                                                         |
| `SIP trunk not found ... Re-run SIP setup`                                                                                               | The stored trunk no longer exists at the voice infrastructure.                    | Call `POST /v1/sip/setup` again to re-provision.                                                            |
| `SIP call failed: <provider reason>`                                                                                                     | The trunk rejected the call (auth, caller-ID, transport).                         | See troubleshooting in [SIP Calling Setup](/docs/features/settings/sip#troubleshooting).                    |
| `Failed to initiate call` / `Failed to accept call` / `Failed to reject call` / `Failed to terminate call` / `Failed to pre-accept call` | WhatsApp rejected the call action; its error body is in `errorRaw`.               | Check `errorRaw` (call already ended, wrong state, unknown `wacid`).                                        |
| `Forbidden`                                                                                                                              | `roomName` does not belong to the authenticated business.                         | Use the `roomName` returned to you by initiate or delivered for your inbound call.                          |

---

## Related

- **[Voice Calls → Voice Bot Integration](/docs/features/calls#voice-bot-integration)** — product-side overview of incoming and outbound bot-handled calls.
- **[SIP Calling Setup](/docs/features/settings/sip)** — dashboard walkthrough for connecting a SIP trunk.
- **[Chatbots → Test Voice Bot](/docs/features/chatbots#test-voice-bot)** — UI walkthrough for the in-editor test tool.
- **[Webhooks](/docs/api/webhooks)** — register a `metaWebhooks` URL to receive call events.
