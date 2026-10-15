---
name: heltar-calls
description: 'Place, answer and manage voice calls on Heltar — WhatsApp voice, SIP trunk, web-chat widget, employee-direct, or AI-voice-bot agent calls. Use when placing outbound calls, answering or rejecting inbound calls, hanging up, listing call history, reading AI voice-call transcripts and metrics, changing WhatsApp calling settings, connecting a SIP trunk, or testing a voice bot in the browser.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Voice
  tags: calls, voice, whatsapp-voice, sip, sip-trunk, voice-bot, agent-mode, direct-mode, inbound, pre-accept, terminate, webrtc, call-settings, voice-calls, transcripts
  uses:
    - heltar-authentication
    - heltar-chatbots
---

# Heltar Calls

## Overview

A single endpoint, `/v1/calls/initiate`, handles every outbound call path. The runtime picks behavior from two parameters: `callType` (channel) × `mode` (who runs the call). Inbound WhatsApp calls are answered by the published voice bot automatically, or by your own client through the pre-accept / accept / reject endpoints. Around that sit the WhatsApp calling settings, the AI voice-call records (recording, metrics, transcript) and the SIP trunk configuration.

## Agent Instructions

| User intent                                                       | Endpoint                                                                                                   |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| "Call this number" (bot or employee, WhatsApp or SIP)             | `POST /v1/calls/initiate`                                                                                  |
| "Answer the inbound WhatsApp call while it's ringing" (fastest)   | `POST /v1/calls/pre-accept`                                                                                |
| "Pick up an inbound WhatsApp / SIP / web-widget call"             | `POST /v1/calls/accept`                                                                                    |
| "Decline an inbound call"                                         | `POST /v1/calls/reject`                                                                                    |
| "Hang up"                                                         | `POST /v1/calls/terminate`                                                                                 |
| "Talk to the voice bot from the browser"                          | `POST /v1/calls/test-voice-bot`                                                                            |
| "Call history / missed calls / recording links"                   | `GET /v1/calls?limit=&page=`                                                                               |
| "Can customers call us? Set calling hours / hide the call button" | `GET` / `POST /v1/business/call-settings` (**Full access** key; **Read-only** for GET)                     |
| "Transcript, latency, tool calls, billed minutes of a bot call"   | `GET /v1/voice-calls?limit=&offset=`, `GET /v1/voice-calls/:callId` (**Full access** or **Read-only** key) |
| "Connect / remove our SIP trunk"                                  | `POST /v1/sip/setup`, `DELETE /v1/sip/teardown` (**Full access** key)                                      |

`/v1/calls/*` uses `calls:read` (GET) / `calls:write` (POST). The call-settings, voice-call and SIP endpoints sit outside the per-resource scope picker — a per-resource key gets `403 API key does not have the required scope`.

Confirm two things before generating an outbound call:

1. **`callType`** — `whatsapp` (default; call a WhatsApp number) or `sip` (regular phone via SIP trunk). `web` exists only on accept / reject / terminate, for web-chat widget calls.
2. **`mode`** — `agent` (default; AI voice bot runs it, the platform handles SDP) or `direct` (employee runs it from the browser; you provide the WebRTC `session`).

| `callType` | `mode`   | Result                                                | Required setup                                                                |
| ---------- | -------- | ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| `whatsapp` | `agent`  | AI voice bot calls a WhatsApp number                  | WhatsApp Business API connected + `chatbotId` (or active voice bot)           |
| `whatsapp` | `direct` | Employee browser → WhatsApp call                      | WhatsApp Business API connected + WebRTC `session: { sdpType: "offer", sdp }` |
| `sip`      | `agent`  | AI voice bot calls a regular phone                    | SIP trunk (`POST /v1/sip/setup`) + `chatbotId` (or active voice bot)          |
| `sip`      | `direct` | Employee browser joins voice room; platform dials SIP | SIP trunk (`POST /v1/sip/setup`)                                              |

If `mode: agent` and `chatbotId` is omitted, the business's active voice bot is used. Configure it in the chatbot editor → **Publish as Voice Bot** (or `POST /v1/chatbots/active/bot` with `botType: voice`).

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md). In-product browser flows use a short-lived session JWT instead of an API key — for backend integrations, always use the API key.

## Quick Start — outbound AI call over WhatsApp

```bash
curl -X POST "$API_URL/v1/calls/initiate" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "callType": "whatsapp",
    "mode": "agent",
    "clientWaNumber": "919999999999",
    "chatbotId": "f4cfa825-406c-45c4-a548-dfd154e07f14"
  }'
```

Response: `{ callId, roomName, clientWaNumber }`. `callId` is the WhatsApp call id (`wacid.…`) — store it; it is the `wacid` for terminate and the key to match the call in webhooks, `GET /v1/calls` and `GET /v1/voice-calls/:callId`.

Direct WhatsApp mode returns the stored call record instead (`data.message.wamid` is the call id); `refId`, `bizOpaqueCallbackData` and `integrations[]` are accepted only in that mode and echoed back. The recipient's SDP answer arrives on the `connect` webhook event — apply it to your peer connection.

## Outbound SIP (agent)

```jsonc
POST /v1/calls/initiate
{ "callType": "sip", "mode": "agent", "clientWaNumber": "919999999999", "chatbotId": "..." }
```

Response: `{ roomName, participantSid }`. Use `roomName` (not a `wacid`) to terminate. With `mode: direct` the response adds `token` + `livekitUrl` so a WebRTC client can join the room while the phone is dialled. SIP calls ring for up to 45 s and are capped at 10 min.

## Terminate a call

```jsonc
POST /v1/calls/terminate
// WhatsApp (default callType):
{ "callType": "whatsapp", "wacid": "wacid.IRgg..." }
// SIP or web-chat widget call:
{ "callType": "sip", "roomName": "sip-6-out-9199…-…" }   // or "callType": "web"
```

Response for WhatsApp: `{ cleanMessage, clientWaNumber }` — `cleanMessage` is the stored call record. For `sip` / `web`: `{ "message": "SIP call terminated", "data": { "roomName" } }` and the room is closed. Cleanup also fires automatically on WhatsApp's `terminate` webhook or when the voice session ends.

## Browser test — `Test Call`

```jsonc
POST /v1/calls/test-voice-bot
{ "chatbotId": "f4cfa825-..." }   // falls back to the active voice bot
// Response: { roomName, token, voiceUrl }
```

Use `token` + `voiceUrl` (a `wss://` URL) with a compatible WebRTC client SDK to talk to the bot from the browser. The room closes 30 s after the last participant leaves.

## Inbound calls

When a customer calls the business number, WhatsApp sends a `connect` event carrying the caller's SDP offer; it is forwarded to your `metaWebhooks` webhook as `value.calls[]` with `"field": "calls"` (see [`heltar-webhooks`](../heltar-webhooks/SKILL.md)).

- **Voice bot published** → the platform answers; nothing to do. The call appears in `GET /v1/calls` and, once processed, in `GET /v1/voice-calls`.
- **No voice bot** → the call rings in the Inbox. Answer from your own client with `wacid` = the event's `calls[].id`:

| Endpoint                    | Body                                                                                                                                          |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /v1/calls/pre-accept` | `{ wacid, session: { sdpType: "answer", sdp } }` — answer while still ringing (recommended); it also performs the accept, so no separate call |
| `POST /v1/calls/accept`     | WhatsApp: `{ wacid, session }` · SIP / web: `{ callType: "sip" or "web", roomName }` → returns `{ roomName, token, livekitUrl }` to join      |
| `POST /v1/calls/reject`     | WhatsApp: `{ wacid }` · SIP / web: `{ callType, roomName }`                                                                                   |

An inbound `terminate` event without `duration` is a missed call. These endpoints are **not** used for outbound `mode: agent` calls — the platform completes the SDP handshake itself.

## Call history

```
GET /v1/calls?limit=50&page=1
```

The only query parameters are `limit` (1–50000; omit to get every call) and `page` (1-based, max 10000, applies only with `limit`) — filter by `clientWaNumber`, `callType` (`incoming` / `outgoing` / `missed`) or `direction` client-side. Each record carries `wamid` (`wacid.…` for WhatsApp, the `roomName` for SIP), `callEvents[]`, `duration` and `awsLink` (recording URL or `null`). Invalid `page` / `limit` → `422`.

## Voice-call records, call settings, SIP trunk

- `GET /v1/voice-calls` (offset paged, `limit` ≤ 100) and `GET /v1/voice-calls/:callId` (`callId` = `wacid.…` or the SIP `roomName`) return billing (`durationSeconds`, `billedMinutes`, `recordingUrl`), metrics (turns, latencies, tool calls) and `sessionReport.chat_history.items[]` — the transcript. Records are filled in two steps (billing shortly after hang-up, analytics when the bot session closes); poll again if you see zeros or no transcript.
- `GET /v1/business/call-settings` / `POST` with `{ "calling": { status, call_icon_visibility, callback_permission_status, call_hours: { status, timezone_id, weekly_operating_hours[], holiday_schedule[] }, sip } }` — send only the keys to change; times are 24-hour `HHMM`, `holiday_schedule` max 20 entries. `calling.sip` is WhatsApp's own SIP routing, unrelated to the trunk below.
- `POST /v1/sip/setup` `{ provider: twilio | telnyx | vonage | custom, address, countryCode, bizWhatsappNumber, authUsername?, authPassword?, dialPrefix?, transport? }` provisions the trunk — calling it again replaces the configuration, the body is strict, credentials are never returned. `DELETE /v1/sip/teardown` removes it. Required before any `callType: sip` call.

## Common errors

| `errorMessage`                                                     | Cause                                                         | Fix                                                       |
| ------------------------------------------------------------------ | ------------------------------------------------------------- | --------------------------------------------------------- |
| `Business WhatsApp credentials not configured`                     | WhatsApp Business API not connected                           | Complete Settings → WhatsApp API Setup                    |
| `Active call already exists for this client`                       | Live call already in progress to that number                  | Terminate via `/v1/calls/terminate` or wait for it to end |
| `No chatbotId provided and no active voice bot configured`         | `mode: agent` but no bot (`No voice bot configured` for SIP)  | Pass `chatbotId` or publish a voice bot                   |
| `Chatbot not found`                                                | `chatbotId` doesn't belong to this business                   | Verify the UUID                                           |
| `session is required for direct WhatsApp calls`                    | `mode: direct, callType: whatsapp` without WebRTC session     | Include `{ sdpType: "offer", sdp }` from the WebRTC peer  |
| `wacid is required for WhatsApp calls, roomName for SIP/web calls` | Accept / reject / terminate body lacks the id for `callType`  | Send `wacid` for `whatsapp`, `roomName` for `sip` / `web` |
| `SIP is not configured. Run setup first.`                          | `callType: sip` without a trunk                               | `POST /v1/sip/setup` (or Settings → SIP Calling)          |
| `Invalid destination phone number`                                 | SIP call with a non-normalisable number or a WhatsApp user ID | Send digits with country code                             |
| `API key does not have the required scope`                         | Per-resource key on call-settings / voice-calls / SIP         | Use a Full access (or Read-only for GET) key              |
| `Forbidden`                                                        | `roomName` belongs to another business                        | Use the `roomName` returned to you                        |

## Common gotchas

- Don't reuse `wacid` from a previous call to terminate a current one — `wacid` is per-call.
- For `mode: agent`, the API returns immediately; the actual call dials in the background once WhatsApp accepts. Listen for webhooks for status.
- Only one live call per destination number at a time.
- SIP accepts phone numbers only (digits with country code); the WhatsApp user ID of a contact who hides their number works only with `callType: whatsapp, mode: direct`.
- Voice bot IDs are separate from text bot IDs (see [`heltar-chatbots`](../heltar-chatbots/SKILL.md)).

## Related Skills

- [`heltar-chatbots`](../heltar-chatbots/SKILL.md) — publish the voice bot and tune its `voiceBot` settings.
- [`heltar-webhooks`](../heltar-webhooks/SKILL.md) — receive `calls` events.
- `heltar-business` — the other `/v1/business/*` account settings beyond `call-settings`.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
