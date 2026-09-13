---
name: heltar-authentication
description: "API key setup, header format, scopes, and security best practices for the Heltar WhatsApp Business API. Use when the user is starting a new integration, can't authenticate, gets a 401 or 403, needs to choose key scopes, or needs to rotate / revoke keys."
metadata:
  author: Heltar
  version: 0.1.0
  category: Authentication
  tags: api-key, bearer, authentication, scopes, security, 401, 403
  uses: []
---

# Heltar Authentication

## Overview

Every Heltar API request authenticates with a single API key passed as a `Bearer` token. Keys belong to a business and carry **scopes** that decide which endpoints they can call.

## Agent Instructions

Before generating any API code, gather:

1. **Does the user already have an API key?** If not, walk them through generating one (see _Getting an API key_ below). Keys are shown **only once** at creation — they cannot be retrieved later.
2. **Which scopes does the integration need?** Pick the resources from the table under _Scopes_ (e.g. `messages:write` + `clients:read` for a notification service). Account-level endpoints need a **Full access** key — see the rule below.
3. **Where will the code run?** API calls must be **server-side** only. Refuse to generate browser/frontend snippets that put the key in client code; offer a server proxy instead.
4. **How will the key be stored?** Always read from an environment variable (`HELTAR_API_KEY`). Never inline the key into source.

## Environment variables

```bash
export HELTAR_API_KEY="hk_live_..."
export API_URL="<your-heltar-api-base-url>"  # ask the user; do not guess
```

## Authorization header

Every request:

```
Authorization: Bearer $HELTAR_API_KEY
Content-Type: application/json
```

## Quick Start — verify a key works

A safe, read-only call to confirm auth is wired up correctly (needs `clients:read`, or a Full access / Read-only key):

```bash
curl -X GET "$API_URL/v1/clients?limit=1" \
  -H "Authorization: Bearer $HELTAR_API_KEY"
```

```javascript
const res = await fetch(`${process.env.API_URL}/v1/clients?limit=1`, {
  headers: { Authorization: `Bearer ${process.env.HELTAR_API_KEY}` },
});
console.log(res.status, await res.json());
```

```python
import os, requests
res = requests.get(
    f"{os.environ['API_URL']}/v1/clients",
    params={"limit": 1},
    headers={"Authorization": f"Bearer {os.environ['HELTAR_API_KEY']}"},
)
print(res.status_code, res.json())
```

A `200` confirms the key is valid. A `401` means the key is missing, malformed, or revoked; a `403` means the key is valid but not scoped for this endpoint.

## Getting an API key

1. Sign in to the dashboard.
2. **Settings → API Key / Dev tools**.
3. Click **Create API Key**.
4. Give it a name and choose its **scopes** — the **Full access** or **Read-only** preset, or exactly the resources and actions it needs. Optionally set an expiry.
5. Copy the key immediately (`hk_live_…`) — it is shown **once**. You can create as many keys as you need.

## Scopes

A scope is `resource:action` with `action` = `read` or `write`; `*` is full access and `*:read` is read-only everything. The resource is the first path segment after `/v1`:

| Resource    | Shown in the app as | Covers                                     |
| ----------- | ------------------- | ------------------------------------------ |
| `messages`  | Messages            | `/v1/messages/*` — send / fetch messages   |
| `clients`   | Contacts            | `/v1/clients/*` — contacts, bot assignment |
| `templates` | Templates           | `/v1/templates/*`                          |
| `campaigns` | Campaigns           | `/v1/campaigns/*`                          |
| `chatbots`  | Chatbots            | `/v1/chatbots/*`                           |
| `groups`    | Groups              | `/v1/groups/*`                             |
| `calls`     | Calls               | `/v1/calls/*`                              |
| `schedule`  | Schedule            | `/v1/schedule/*`                           |
| `org`       | AI Studio           | `/v1/org/code/*` — Code Editor             |
| `embed`     | Embed               | Embedded agent chat                        |
| `journeys`  | Journeys            | Journey events                             |

`GET` requests need `<resource>:read`; everything else needs `<resource>:write`. A call the key isn't scoped for returns **403 Forbidden**.

> **Account-level endpoints are not in the picker.** `/v1/business/*` (account status, opt-in/opt-out rules, profile, settings, call settings, live chatbots), the team endpoints under `/v1/auth/business-employees/*` and `/v1/role-permission`, `/v1/analytics/*`, `/v1/link-tracker/*`, `/v1/voice-calls/*`, `/v1/sip/*` and `/v1/wallet/*` need a key created with the **Full access** preset — or **Read-only** for their `GET` requests. A per-resource key gets `403` on them no matter which resources it holds.

Some dashboard-only areas (**webhooks**, **flows**) can never be reached with an API key, even a full-access one — configure those in the app.

## Rotation and revocation

Generate a new key, deploy it everywhere, then **Revoke** the old one from **Settings → API Key / Dev tools**. A revoked key stops working on its next request; other keys are unaffected. Create separate keys per integration and per environment so one can be rotated without breaking the rest, and set an expiry on short-lived keys.

Businesses created before scoped keys may still have a single legacy key that behaves as full access; **Revoke legacy key** disables every old key at once while `hk_live_…` keys keep working.

## Common errors

| Status | Likely cause                                                     | Fix                                                                                                                                      |
| ------ | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 401    | Missing/invalid `Authorization` header, or revoked / expired key | Re-issue from **Settings → API Key / Dev tools**, redeploy                                                                               |
| 403    | Valid key but the endpoint needs a scope the key doesn't carry   | Add the `<resource>:read` / `:write` scope, or use a **Full access** (**Read-only** for GET) key for account-level endpoints — see above |

- `429 Too Many Requests` — per-business rate limit for API keys (analytics, campaign statistics, message search and the link list: 60 per 15 minutes; list reads such as contacts, message history, campaigns and call records: 600 per 15 minutes; key management: 20 per 15 minutes). Honour the `Retry-After` header (seconds) and back off; sending messages and campaigns is not rate limited this way. Dashboard sessions are never limited.

## Hard rules for generated code

- ✅ Read the key from `HELTAR_API_KEY` env var.
- ✅ Use HTTPS only.
- ✅ Make calls from a server, not a browser.
- ✅ Scope keys to what the integration needs; reserve **Full access** for account-level endpoints.
- ❌ Never echo the full key in logs — redact past the first 4 characters.
- ❌ Never commit the key. If a sample `.env` is generated, also generate/append a `.env` line to `.gitignore`.

## Related Skills

Every other `heltar-*` skill depends on this one. The account-level endpoints that need a Full access key are covered by `heltar-business` (`/v1/business/*`), `heltar-team` (`/v1/auth/business-employees/*`, `/v1/role-permission`), `heltar-analytics` (`/v1/analytics/*`), `heltar-link-tracker` (`/v1/link-tracker/*`), [`heltar-calls`](../heltar-calls/SKILL.md) (`/v1/voice-calls/*`, `/v1/sip/*`) and [`heltar-chatbots`](../heltar-chatbots/SKILL.md) (`/v1/wallet/*`).

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
