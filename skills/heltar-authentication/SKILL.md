---
name: heltar-authentication
description: "API key setup, header format, and security best practices for the Heltar WhatsApp Business API. Use when the user is starting a new integration, can't authenticate, gets a 401, or needs to rotate / regenerate keys."
metadata:
  author: Heltar
  version: 0.1.0
  category: Authentication
  tags: api-key, bearer, authentication, security, 401
  uses: []
---

# Heltar Authentication

## Overview

Every Heltar API request authenticates with a single API key passed as a `Bearer` token. Keys are tied to a business account and grant access to all API endpoints for that business.

## Agent Instructions

Before generating any API code, gather:

1. **Does the user already have an API key?** If not, walk them through generating one (see _Getting an API key_ below). Keys are shown **only once** at creation — they cannot be retrieved later.
2. **Where will the code run?** API calls must be **server-side** only. Refuse to generate browser/frontend snippets that put the key in client code; offer a server proxy instead.
3. **How will the key be stored?** Always read from an environment variable (`HELTAR_API_KEY`). Never inline the key into source.

## Environment variables

```bash
export HELTAR_API_KEY="your-api-key"
export API_URL="<your-heltar-api-base-url>"  # ask the user; do not guess
```

## Authorization header

Every request:

```
Authorization: Bearer $HELTAR_API_KEY
Content-Type: application/json
```

## Quick Start — verify a key works

A safe, read-only call to confirm auth is wired up correctly:

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

A `200` confirms the key is valid. A `401` means the key is missing, malformed, or revoked.

## Getting an API key

1. Sign in to the dashboard.
2. **Settings → Developer → API Keys**.
3. Click **Generate New Key**.
4. Copy the key immediately — it is shown **once**.
5. Optionally set an expiry for added security.

## Rotation

Generate a new key, deploy it everywhere, then the old key is automatically invalidated when the new one is generated. There is no separate revoke step.

## Common errors

| Status | Likely cause                                                         | Fix                                                                                                         |
| ------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 401    | Missing/invalid `Authorization` header, or revoked key               | Re-issue from **Settings → Developer**, redeploy                                                            |
| 403    | Valid key but the action requires a permission the key doesn't carry | Check the endpoint's required permission; some endpoints (e.g. group settings) require `contactsManagement` |

## Hard rules for generated code

- ✅ Read the key from `HELTAR_API_KEY` env var.
- ✅ Use HTTPS only.
- ✅ Make calls from a server, not a browser.
- ❌ Never echo the full key in logs — redact past the first 4 characters.
- ❌ Never commit the key. If a sample `.env` is generated, also generate/append a `.env` line to `.gitignore`.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
