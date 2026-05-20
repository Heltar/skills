---
name: heltar-code-editor
description: "Run a custom function deployed in Heltar's Code Editor from external systems. Use when the user wants to trigger their own Heltar function from a webhook, cron, or backend integration."
metadata:
  author: Heltar
  version: 0.1.0
  category: Automation
  tags: code-editor, run-deployed, custom-functions, function-name
  uses:
    - heltar-authentication
---

# Heltar Code Editor

## Overview

Heltar's Code Editor lets users author and deploy custom functions inside the dashboard. `POST /v1/org/code/run` invokes the **deployed** (production) version of a function by name. Business context is injected automatically — the caller never sends business identifiers.

## Agent Instructions

Confirm with the user:

1. **Function name** — must be a function that has been **deployed**, not just saved as a draft.
2. **Custom parameters** — anything the function expects (e.g. `param1`, `orderId`). Pass them as top-level body fields.

The backend automatically prepends a `business` block to the request — the caller does **not** need to send `phoneNumberId`, `businessAccountId`, etc.

## Authentication

Bearer API key. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

## Endpoint

```
POST /v1/org/code/run
```

## Quick Start

```bash
curl -X POST "$API_URL/v1/org/code/run" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "function_name": "welcome",
    "param1": "value1",
    "param2": 123
  }'
```

```javascript
const res = await fetch(`${process.env.API_URL}/v1/org/code/run`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.HELTAR_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ function_name: 'welcome', param1: 'value1' }),
});
console.log(await res.json());
```

```python
import os, requests
res = requests.post(
    f"{os.environ['API_URL']}/v1/org/code/run",
    headers={"Authorization": f"Bearer {os.environ['HELTAR_API_KEY']}"},
    json={"function_name": "welcome", "param1": "value1"},
)
print(res.json())
```

## Response shape

```jsonc
{
  "code": "OK",
  "message": "Code executed successfully",
  "data": {
    "result":     /* whatever your function returned */,
    "logs":       "print output",
    "statusCode": 200
  }
}
```

## Auto-injected `business` block

The function receives:

```jsonc
{
  "business": {
    "id": 0,
    "phoneNumberId": "",
    "countryCode": 91,
    "bizWhatsappNumber": "",
    "businessAccountId": "",
    "fbAppId": "",
  },
}
```

…merged into the request body. **Do not** send these from the caller — they will be overwritten by the runtime.

When the same function is invoked from a chatbot conversation (the bot calls it as a tool while replying to a client), the `business` block additionally includes `clientWaNumber` — the WhatsApp number of the client the bot is talking to. This is **not** present when the function is invoked directly via `POST /v1/org/code/run`.

## Common gotchas

- The endpoint runs the **deployed** version. Saving a function in the editor without deploying it has no effect on this endpoint. Deploy first, then call.
- Avoid putting secrets in `param*` fields that go through your own logs — they may end up captured by the function's `logs` output too.
- If the deployed function throws, the response still has shape `{ code, message, data: { statusCode, logs } }` — check `statusCode` for non-200, and `logs` for traceback.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
