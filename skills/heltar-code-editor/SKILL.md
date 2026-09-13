---
name: heltar-code-editor
description: "Manage and run the custom Python code your organisation writes in Heltar's Code Editor — read the draft, save it, test it, publish and deploy versions, and run the deployed code from external systems. Use when the user wants to trigger their own Heltar function from a webhook, cron, or backend integration, or automate the save → version → deploy workflow from CI."
metadata:
  author: Heltar
  version: 0.1.0
  category: Automation
  tags: code-editor, ai-studio, run-deployed, custom-functions, function-name, draft, versions, deploy, org-scope
  uses:
    - heltar-authentication
---

# Heltar Code Editor

## Overview

Heltar's Code Editor lets users author and deploy custom functions inside the dashboard. Code is stored **once per organisation** (every business in the org shares the same draft, versions and deployment) and runs on a managed Python runtime: entry point `all_events_handler(event, context)` in `all_events_entry_point.py`, up to 5 minutes, 1 GB of memory and 2 GB of temporary disk per invocation. `POST /v1/org/code/run` invokes the **deployed** (production) version by function name with business context injected automatically; the other endpoints cover the draft → version → deploy lifecycle.

## Agent Instructions

| User intent                                                | Endpoint                                                                         |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------- |
| "Run my deployed function from a webhook / cron / backend" | `POST /v1/org/code/run`                                                          |
| "Does code exist? Which env vars are set?"                 | `GET /v1/org/code`                                                               |
| "Download the draft or version N as a zip"                 | `GET /v1/org/code/source?version=$LATEST` (or `21`; `&meta=1` for metadata only) |
| "Upload / save my workspace and env vars"                  | `POST /v1/org/code/save`                                                         |
| "Try the draft with a test payload"                        | `POST /v1/org/code/test`                                                         |
| "Which versions exist, which one is live?"                 | `GET /v1/org/code/versions`                                                      |
| "Publish the draft as a version"                           | `POST /v1/org/code/versions`                                                     |
| "Delete an old version"                                    | `DELETE /v1/org/code/versions/:version`                                          |
| "Make version N production"                                | `POST /v1/org/code/deploy`                                                       |

Confirm with the user before generating a run call:

1. **Function name** — must be handled by the **deployed** version, not just saved as a draft (`GET /v1/org/code/versions` shows which entry has `isDeployed: true`).
2. **Custom parameters** — anything the function expects (e.g. `orderId`). Pass them as top-level body fields; they reach the handler unchanged.
3. **Is the call about a contact?** Pass `clientWaNumber` as a top-level field — it is copied into `business.clientWaNumber`, so one handler serves API calls and chatbot tool calls alike.

The runtime prepends a `business` block to **run** requests — the caller does **not** send `phoneNumberId`, `businessAccountId`, etc. **Test does not inject it**: `/test` passes your payload to the handler exactly as sent, so include any `business` fields the handler relies on yourself.

## Authentication

Bearer API key with the **`org`** scope — `org:read` for the GET endpoints, `org:write` for POST / DELETE (including **run**). The `org` resource is labelled **ai-studio** in the API key scope picker; a **Full access** key also works (**Read-only** keys can call the GETs). Any other scope returns `403 Forbidden`. See [`heltar-authentication`](../heltar-authentication/SKILL.md).

Every call acts on the business the key belongs to. Append `?business_id=<id>` to act for another business in the same organisation (deploy syncs definitions to that business; run uses its context).

## Quick Start — run the deployed code

```bash
curl -X POST "$API_URL/v1/org/code/run" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "function_name": "get_order_status",
    "order_id": "ORD-12345",
    "clientWaNumber": "919876543210"
  }'
```

```javascript
const res = await fetch(`${process.env.API_URL}/v1/org/code/run`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.HELTAR_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    function_name: 'get_order_status',
    order_id: 'ORD-12345',
    clientWaNumber: '919876543210',
  }),
});
console.log(await res.json());
```

```python
import os, requests
res = requests.post(
    f"{os.environ['API_URL']}/v1/org/code/run",
    headers={"Authorization": f"Bearer {os.environ['HELTAR_API_KEY']}"},
    json={"function_name": "get_order_status", "order_id": "ORD-12345", "clientWaNumber": "919876543210"},
)
print(res.json())
```

## Response shape

```jsonc
{
  "message": "Code executed successfully",
  "data": {
    "result":        /* whatever your handler returned; a non-JSON return value comes back as a string */,
    "logs":          "print output",   // omitted when nothing was printed
    "statusCode":    200,              // 200 = the call reached your code, even if it then raised
    "functionError": "Unhandled"       // only when the handler raised; `result` then holds errorMessage / errorType / stackTrace
  }
}
```

`POST /v1/org/code/test` returns the same shape. `400 function not found for this org` means nothing has been saved (test) or deployed (run) yet.

## Auto-injected `business` block

On **run**, the function receives:

```jsonc
{
  "business": {
    "id": 0,
    "phoneNumberId": "",
    "countryCode": 91,
    "bizWhatsappNumber": "",
    "businessAccountId": "",
    "fbAppId": "",
    "clientWaNumber": "919876543210", // only when sent top-level, or when a chatbot calls the function as a tool
  },
}
```

…merged into the request body. **Do not** send these from the caller — they will be overwritten by the runtime. When a chatbot invokes the same function during a conversation, `business.clientWaNumber` is the contact the bot is talking to; on a direct run it is present only if you passed `clientWaNumber` top-level. Nothing is injected on `/test`.

## Save → version → deploy

```bash
ZIP_B64=$(zip -qr - . | base64 -w0)          # all_events_entry_point.py at the zip root
curl -X POST "$API_URL/v1/org/code/save" \
  -H "Authorization: Bearer $HELTAR_API_KEY" -H "Content-Type: application/json" \
  -d "{\"codeZipBase64\": \"$ZIP_B64\", \"environment\": {\"STORE_API_KEY\": \"sk_live_…\"}}"
curl -X POST "$API_URL/v1/org/code/versions" \
  -H "Authorization: Bearer $HELTAR_API_KEY" -H "Content-Type: application/json" \
  -d '{ "description": "Added order tracking" }'                # → data.version "22"
curl -X POST "$API_URL/v1/org/code/deploy" \
  -H "Authorization: Bearer $HELTAR_API_KEY" -H "Content-Type: application/json" \
  -d '{ "functionVersion": "22" }'
```

- **Save** replaces the entire draft workspace — always send the complete set of files (start from a `GET /v1/org/code/source` download). `environment` omitted = untouched, `{}` = cleared, keys + values ≤ 4096 bytes in total. Saving never publishes or deploys.
- **Versions** are immutable snapshots, numbered and never reused. `$LATEST` and the deployed version cannot be deleted.
- **Deploy** points production at a version and also syncs `chatbot/*.json` and `function_definitions/*.json` to the AI Agent page of the key's business (sync issues never fail the deploy; Meta AI agent problems appear in `data.metaAgentSync`).

## Common gotchas

- Run executes the **deployed** version. Saving — and even creating a version — has no effect until `POST /v1/org/code/deploy`.
- While someone has the Code Editor open in the dashboard, `save`, create-version and delete-version return `403` naming that person. Test, deploy and run are never blocked.
- `GET /v1/org/code` and `/source` return environment-variable **values** as stored — treat the responses as sensitive.
- Avoid putting secrets in `param*` fields that go through your own logs — they may end up captured by the function's `logs` output too.
- `statusCode: 200` does not mean the code succeeded — check for `functionError` and read `result.stackTrace`.
- `400 An update is already in progress for this function` on save: a previous save is still being applied; retry after a moment.

## Related Skills

- [`heltar-chatbots`](../heltar-chatbots/SKILL.md) — functions with `executionDetails.type: unified_function_event_handlers` call this deployment by `name`.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
