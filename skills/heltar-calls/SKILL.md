---
name: heltar-calls
description: 'Initiate and manage voice calls on Heltar — WhatsApp voice, SIP trunk, employee-direct, or AI-voice-bot agent calls. Use when placing outbound calls, hanging up active calls, listing call history, or testing a voice bot in the browser.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Voice
  tags: calls, voice, whatsapp-voice, sip, voice-bot, agent-mode, direct-mode, terminate, webrtc
  uses:
    - heltar-authentication
    - heltar-chatbots
---

# Heltar Calls

## Overview

A single endpoint, `/v1/calls/initiate`, handles every outbound call path. The runtime picks behavior from two parameters: `callType` (channel) × `mode` (who runs the call).

## Agent Instructions

Confirm two things before generating code:

1. **`callType`** — `whatsapp` (call a WhatsApp number) or `sip` (regular phone via SIP trunk).
2. **`mode`** — `agent` (AI voice bot runs it; backend handles SDP) or `direct` (employee runs it from the browser; you provide WebRTC `session`).

| `callType` | `mode`   | Result                                               | Required setup                                      |
| ---------- | -------- | ---------------------------------------------------- | --------------------------------------------------- |
| `whatsapp` | `agent`  | AI voice bot calls a WhatsApp number                 | WABA onboarding + `chatbotId` (or active voice bot) |
| `whatsapp` | `direct` | Employee browser → WhatsApp call                     | WABA + WebRTC `session: { sdp, sdpType }`           |
| `sip`      | `agent`  | AI voice bot calls a regular phone                   | SIP trunk configured + `chatbotId`                  |
| `sip`      | `direct` | Employee browser joins voice room; backend dials SIP | SIP trunk configured                                |

If `mode: agent` and `chatbotId` is omitted, the business's `activeVoiceBotId` is used. Configure it in the chatbot editor → **Publish as Voice Bot**.

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

Response: `{ callId, roomName, clientWaNumber }`. `callId` is Meta's `wacid` — store it; you'll need it to terminate or correlate webhooks.

## Outbound SIP (agent)

```jsonc
POST /v1/calls/initiate
{ "callType": "sip", "mode": "agent", "clientWaNumber": "919999999999", "chatbotId": "..." }
```

Response: `{ roomName, participantSid }`. Use `roomName` (not a `wacid`) to terminate.

## Terminate a call

```jsonc
POST /v1/calls/terminate
// WhatsApp:
{ "callType": "whatsapp", "wacid": "wacid.IRgg..." }
// SIP:
{ "callType": "sip", "roomName": "sip-6-out-9199…-…" }
```

Cleanup also fires automatically on Meta's `terminate` webhook or session-finished webhook.

## Browser test — `Test Call`

```jsonc
POST /v1/calls/test-voice-bot
{ "chatbotId": "f4cfa825-..." }
// Response: { roomName, token, voiceUrl }
```

Use `token` + `voiceUrl` (a `wss://` URL) with a compatible WebRTC client SDK to talk to the bot from the browser.

## Employee-direct WhatsApp handshake

These complete the SDP exchange for `mode: direct, callType: whatsapp`. They are **not** used in `mode: agent` (backend handles SDP automatically):

| Endpoint                    | Body                                                      |
| --------------------------- | --------------------------------------------------------- |
| `POST /v1/calls/pre-accept` | `{ wacid, session }` — answer in ringing state            |
| `POST /v1/calls/accept`     | `{ wacid, session, callType? }` — pick up                 |
| `POST /v1/calls/reject`     | `{ wacid, callType? }` or `{ roomName, callType: "sip" }` |

## Call history

```
GET /v1/calls?clientWaNumber=&direction=incoming|outgoing|missed&from=&to=&limit=&cursor=
```

## Common errors

| `errorMessage`                                             | Cause                                                     | Fix                                                       |
| ---------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |
| `Business WhatsApp credentials not configured`             | `fbAccessToken` / `phoneNumberId` missing                 | Complete Settings → WhatsApp API Setup                    |
| `Active call already exists for this client`               | Live call already in progress to that number              | Terminate via `/v1/calls/terminate` or wait for it to end |
| `No chatbotId provided and no active voice bot configured` | `mode: agent` but no bot                                  | Pass `chatbotId` or publish a voice bot                   |
| `Chatbot not found`                                        | `chatbotId` doesn't belong to this business               | Verify the UUID                                           |
| `session is required for direct WhatsApp calls`            | `mode: direct, callType: whatsapp` without WebRTC session | Include `{ sdp, sdpType }` from the WebRTC peer           |

## Common gotchas

- Don't reuse `wacid` from a previous call to terminate a current one — `wacid` is per-call.
- For `mode: agent`, the API returns immediately; the actual call dials in the background once Meta accepts. Listen for webhooks for status.
- Voice bot IDs are separate from text bot IDs (see [`heltar-chatbots`](../heltar-chatbots/SKILL.md)).

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
