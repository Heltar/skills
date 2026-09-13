---
title: Code Editor
description: Execute custom functions from the code editor
icon: Code
order: 7
---

# Code Editor API

Manage and execute the custom code you write in the Code Editor. Everything you can do from the editor toolbar is available here: fetch the current code, save a draft, test it, publish versions, deploy one to production, and run the deployed code from external systems.

Your code is stored once per organisation. Every business in your organisation shares the same code, versions, and deployment.

| Method   | Endpoint                         | Purpose                                                   |
| -------- | -------------------------------- | --------------------------------------------------------- |
| `GET`    | `/v1/org/code`                   | Check whether code exists and read environment variables  |
| `GET`    | `/v1/org/code/source`            | Download the source of the draft or of a specific version |
| `POST`   | `/v1/org/code/save`              | Save the draft (`$LATEST`) code and environment variables |
| `POST`   | `/v1/org/code/test`              | Run the draft with a test payload                         |
| `GET`    | `/v1/org/code/versions`          | List published versions and which one is deployed         |
| `POST`   | `/v1/org/code/versions`          | Publish the current draft as a new version                |
| `DELETE` | `/v1/org/code/versions/:version` | Delete a published version                                |
| `POST`   | `/v1/org/code/deploy`            | Make a published version the production deployment        |
| `POST`   | `/v1/org/code/run`               | Run the production deployment with business context       |

---

## Authentication & Scope

Every `/v1/org/code/*` endpoint is authenticated with a Bearer **API key** (see [Authentication](./authentication.md)). These endpoints use the `org` scope:

- `org:read` for the `GET` endpoints (fetch code, download source, list versions).
- `org:write` for the `POST` and `DELETE` endpoints (save, test, create/delete versions, deploy, and **run**).

> [!NOTE]
> The `org` resource is labelled **ai-studio** in the API key scope picker. Choose it with Read and/or Write when creating the key under **Settings → Developer**, or use a **Full access** key (**Read-only** keys can call the `GET` endpoints). A call the key isn't scoped for returns **403 Forbidden**.

```bash
Authorization: Bearer YOUR_API_KEY
```

---

## How It Works

Send a request with the name of the function you want to run, along with any input values it needs.

```json
{
  "function_name": "your_function",
  "param1": "value1",
  "param2": 123
}
```

Your business details are automatically added to every request. You don't need to include them yourself. Here's what gets injected:

```json
{
  "business": {
    "id": 0,
    "phoneNumberId": "",
    "countryCode": 91,
    "bizWhatsappNumber": "",
    "businessAccountId": "",
    "fbAppId": ""
  }
}
```

When the same function is invoked from a chatbot conversation (i.e. the bot calls it as a tool while replying to a client), the `business` block additionally includes `clientWaNumber` — the WhatsApp number of the client the bot is currently talking to. When you call `POST /v1/org/code/run` yourself, pass `clientWaNumber` as a top-level field and it is copied into `business.clientWaNumber`, so one handler works for both callers. If you don't send it, `business.clientWaNumber` is absent.

> [!NOTE]
> Business context is injected by **Run Deployed Code** only. **Test Draft Code** passes your payload to the handler exactly as you send it.

### Draft, versions, and deployment

- **Draft (`$LATEST`)** is the working copy. `POST /v1/org/code/save` replaces it and `POST /v1/org/code/test` runs it.
- **Versions** are immutable snapshots of the draft, numbered `1`, `2`, `3`, ... Create one with `POST /v1/org/code/versions`.
- **Deployment** is the version that production points at. `POST /v1/org/code/deploy` selects it and `POST /v1/org/code/run` executes it.

Your code runs on a managed Python runtime. The entry point is `all_events_handler(event, context)` in `all_events_entry_point.py` at the root of your workspace. Each invocation may run for up to 5 minutes with 1 GB of memory and 2 GB of temporary disk space.

> [!IMPORTANT]
> While someone has the Code Editor open in the dashboard, write calls that change the workspace (**save**, **create version**, **delete version**) return **403 Forbidden** with a message naming that person. Ask them to close the editor, or wait for their session to go idle, and retry. Test, deploy, and run are never blocked.

---

## Get Code Status

:::api
method: GET
endpoint: /v1/org/code
title: Get Code Status
description: Check whether any code has been saved for your organisation and read the environment variables currently configured for it.

## Response

```response
{
  "message": "Fetched function details",
  "data": {
    "exists": true,
    "environment": {
      "STORE_API_KEY": "sk_live_xxxxxxxxxxxx",
      "STORE_BASE_URL": "https://api.example.com"
    }
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/org/code" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Response Fields

- `data.exists`: `true` once a draft has been saved at least once. `false` for a new organisation, in which case `environment` is omitted.
- `data.environment`: the environment variables saved with the code, as a flat object of string values. Values are returned as stored, so treat this response as sensitive.

---

## Download Source

:::api
method: GET
endpoint: /v1/org/code/source
title: Download Source
description: Download the workspace of the draft or of a published version, together with version metadata. The response is JSON, and the code itself is a base64-encoded ZIP archive in `data.base64Zip`.

## Query Parameters

- version: string - Version to download. `$LATEST` (the draft) or a version number such as `21`. Defaults to `$LATEST`.
- meta: string - Set to `1` to return metadata only. `base64Zip` and `versions` are omitted, which is much faster when you only need the current state.

## Response

```response
{
  "message": "Fetched code bundle for version $LATEST",
  "data": {
    "base64Zip": "UEsDBBQAAAAIAA...",
    "currentVersion": "$LATEST",
    "isReadOnly": false,
    "deployedVersion": "21",
    "lastModified": "2026-09-01T10:15:22.000+0000",
    "environment": {
      "STORE_API_KEY": "sk_live_xxxxxxxxxxxx"
    },
    "versions": [
      {
        "version": "$LATEST",
        "description": "",
        "createdAt": "2026-09-01T10:15:22.000+0000",
        "isDeployed": false
      },
      {
        "version": "21",
        "description": "Added order tracking",
        "createdAt": "2026-08-28T08:40:11.000+0000",
        "isDeployed": true
      }
    ]
  }
}
```

:::

The response has `Content-Type: application/json`. Decode `data.base64Zip` to get a standard `.zip` file containing your workspace (`all_events_entry_point.py`, `chatbot/`, `function_definitions/`, and any other files you saved).

```bash
curl -X GET "{{API_URL}}/v1/org/code/source?version=21" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  | jq -r '.data.base64Zip' | base64 -d > code-v21.zip
```

```bash
curl -X GET "{{API_URL}}/v1/org/code/source?meta=1" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Response Fields

- `data.base64Zip`: base64-encoded ZIP archive of the workspace. Omitted when `meta=1`.
- `data.currentVersion`: the version the archive belongs to, `$LATEST` or a version number.
- `data.isReadOnly`: `true` for a published version (versions are immutable), `false` for the draft.
- `data.deployedVersion`: the version currently deployed to production, or `null` if nothing has been deployed yet.
- `data.lastModified`: when the draft was last saved.
- `data.environment`: environment variables saved with the code.
- `data.versions`: the full version list (same shape as `GET /v1/org/code/versions`). Omitted when `meta=1`.

Requesting a version that isn't `$LATEST` or a whole number returns **400** `Invalid version <value>`. Requesting a version whose code cannot be found returns **400** `Code not available for version <value>`. If no code has ever been saved, the request returns **400** `Function bundle not available`.

---

## Save Draft Code

:::api
method: POST
endpoint: /v1/org/code/save
title: Save Draft Code
description: Replace the draft (`$LATEST`) with a new workspace and, optionally, update environment variables. Saving does not publish a version or change what is deployed.

## Body Parameters

- codeZipBase64: string [required] - Base64-encoded ZIP archive of the whole workspace. `all_events_entry_point.py` must sit at the root of the archive. A `data:application/zip;base64,` prefix is accepted and stripped.
- environment: object - Environment variables as a flat object of string values. Omit the field to leave the existing variables untouched. Send `{}` to remove every variable. The combined size of all keys and values must stay under 4096 bytes.

```request
{
  "codeZipBase64": "UEsDBBQAAAAIAA...",
  "environment": {
    "STORE_API_KEY": "sk_live_xxxxxxxxxxxx",
    "STORE_BASE_URL": "https://api.example.com"
  }
}
```

## Response

```response
{
  "message": "Code saved successfully"
}
```

:::

The first save for an organisation creates the deployment. Later saves overwrite the draft in place; published versions are never affected. A save replaces the entire workspace, so always send the complete set of files, not just the ones that changed. The easiest way to build the archive is to start from a `GET /v1/org/code/source` download.

:::code-group

```curl
ZIP_B64=$(zip -qr - . | base64 -w0)

curl -X POST "{{API_URL}}/v1/org/code/save" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"codeZipBase64\": \"$ZIP_B64\", \"environment\": {\"STORE_API_KEY\": \"sk_live_xxxxxxxxxxxx\"}}"
```

```javascript
import { readFileSync } from 'node:fs';

const codeZipBase64 = readFileSync('./workspace.zip').toString('base64');

const response = await fetch('{{API_URL}}/v1/org/code/save', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    codeZipBase64,
    environment: { STORE_API_KEY: 'sk_live_xxxxxxxxxxxx' },
  }),
});
const data = await response.json();
```

```python
import base64
import requests

with open('workspace.zip', 'rb') as f:
    code_zip_base64 = base64.b64encode(f.read()).decode()

response = requests.post(
    '{{API_URL}}/v1/org/code/save',
    headers={'Authorization': 'Bearer YOUR_API_KEY'},
    json={
        'codeZipBase64': code_zip_base64,
        'environment': {'STORE_API_KEY': 'sk_live_xxxxxxxxxxxx'},
    },
)
data = response.json()
```

:::

Common failures:

- **400** `Code zip in base64 is required` or `codeZipBase64 payload is empty`: the archive is missing or blank.
- **400** `Environment variables are too large: ... bytes against a 4096 byte limit.`: shorten or remove some variables.
- **400** `An update is already in progress for this function. Please wait a moment and try again.`: a previous save is still being applied.
- **403**: someone is editing the code in the dashboard (see above).

---

## Test Draft Code

:::api
method: POST
endpoint: /v1/org/code/test
title: Test Draft Code
description: Execute the draft (`$LATEST`) with a payload of your choice and get back the handler's return value, its print output, and any error it raised. The same as **Test Run** in the editor toolbar.

## Body Parameters

- function_name: string - Name of the function to execute. Your handler reads it from the event; the API itself does not require it.

```request
{
  "function_name": "get_order_status",
  "order_id": "ORD-12345"
}
```

## Response

```response
{
  "message": "Code executed",
  "data": {
    "result": {
      "status": "shipped",
      "tracking_number": "TRK123456"
    },
    "logs": "looking up ORD-12345",
    "statusCode": 200
  }
}
```

:::

The body is passed to `all_events_handler(event, context)` as `event` exactly as you send it. Business context is **not** injected here; include any `business` fields your handler relies on yourself.

```bash
curl -X POST "{{API_URL}}/v1/org/code/test" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "function_name": "get_order_status",
    "order_id": "ORD-12345"
  }'
```

### Response Fields

- `data.result`: whatever your handler returned, parsed as JSON. If the return value is not valid JSON it is returned as a string.
- `data.logs`: the `print` output of this invocation, one line per entry. Omitted when nothing was printed.
- `data.statusCode`: invocation status. `200` means the call reached your code, even if the code then raised an exception.
- `data.functionError`: present only when your handler raised. `result` then holds the error details (`errorMessage`, `errorType`, `stackTrace`).

```json
{
  "message": "Code executed",
  "data": {
    "result": {
      "errorMessage": "'order_id'",
      "errorType": "KeyError",
      "stackTrace": [
        "  File \"/var/task/all_events_entry_point.py\", line 6, in all_events_handler\n"
      ]
    },
    "logs": "",
    "statusCode": 200,
    "functionError": "Unhandled"
  }
}
```

If no code has been saved yet the request returns **400** `function not found for this org`.

---

## List Versions

:::api
method: GET
endpoint: /v1/org/code/versions
title: List Versions
description: List every published version plus the draft, newest first, with a flag on the version that is currently deployed.

## Response

```response
{
  "message": "Fetched versions",
  "data": [
    {
      "version": "$LATEST",
      "description": "",
      "createdAt": "2026-09-01T10:15:22.000+0000",
      "isDeployed": false
    },
    {
      "version": "22",
      "description": "Added order tracking",
      "createdAt": "2026-09-01T10:15:22.000+0000",
      "isDeployed": false
    },
    {
      "version": "21",
      "description": "Version created on 2026-08-28T08:40:11.204Z",
      "createdAt": "2026-08-28T08:40:11.000+0000",
      "isDeployed": true
    }
  ]
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/org/code/versions" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Response Fields

- `data[].version`: `$LATEST` for the draft, otherwise the version number as a string.
- `data[].description`: the description given when the version was created.
- `data[].createdAt`: when the version was published (for `$LATEST`, when the draft was last saved).
- `data[].isDeployed`: `true` for the version production currently points at. At most one entry is `true`; none is when nothing has been deployed.

`data` is an empty array when no code has been saved yet.

---

## Create Version

:::api
method: POST
endpoint: /v1/org/code/versions
title: Create Version
description: Publish the current draft as a new, immutable, numbered version. The same as **Create Version** in the editor toolbar. Creating a version does not deploy it.

## Body Parameters

- description: string - Human-readable note shown in the version list. Defaults to `Version created on <timestamp>`.

```request
{
  "description": "Added order tracking"
}
```

## Response

```response
{
  "message": "Successfully created version 22",
  "data": {
    "version": "22",
    "description": "Added order tracking",
    "createdAt": "2026-09-01T10:15:22.000+0000",
    "isDeployed": false
  }
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/org/code/versions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "description": "Added order tracking" }'
```

Version numbers always increase and are never reused, even after a version is deleted. Save the draft first; publishing fails if no code has been saved.

---

## Delete Version

:::api
method: DELETE
endpoint: /v1/org/code/versions/:version
title: Delete Version
description: Permanently delete a published version. The draft and the deployed version cannot be deleted.

## Path Parameters

- version: string [required] - Version number to delete, for example `20`. `$LATEST` is rejected.

## Response

```response
{
  "message": "Version 20 deleted successfully",
  "data": {
    "version": "20"
  }
}
```

:::

```bash
curl -X DELETE "{{API_URL}}/v1/org/code/versions/20" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Common failures:

- **400** `Valid version number is required`: `$LATEST` or an empty value was given.
- **400** `Cannot delete version 21 because it is currently deployed`: deploy another version first.
- **404** `Version 20 not found`: the version does not exist or was already deleted.
- **403**: someone is editing the code in the dashboard.

---

## Deploy Version

:::api
method: POST
endpoint: /v1/org/code/deploy
title: Deploy Version
description: Point production at a published version. From this moment `POST /v1/org/code/run` and chatbot tool calls execute that version. The same as the **Deploy** dropdown in the editor toolbar.

## Body Parameters

- functionVersion: string [required] - Version number to deploy, as returned by `GET /v1/org/code/versions` (for example `22`).

```request
{
  "functionVersion": "22"
}
```

## Response

```response
{
  "message": "Successfully deployed version 22"
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/org/code/deploy" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "functionVersion": "22" }'
```

Deploying also syncs the chatbot and function definitions found in the deployed version (`chatbot/*.json` and `function_definitions/*.json`) to the **AI Agent** page of the business the API key belongs to, exactly as described in the [Code Editor guide](../features/code-editor.md). The sync runs after the deployment succeeds and never fails it: if a definition cannot be synced the deployment still stands.

Chatbots that are also published as Meta AI agents are re-pushed to Meta on deploy. When any of them report a problem the message ends with `— N Meta AI agent(s) reported sync issues, see metaAgentSync` and the response carries a `data.metaAgentSync` array, one entry per chatbot and business:

```json
{
  "message": "Successfully deployed version 22 — 1 Meta AI agent(s) reported sync issues, see metaAgentSync",
  "data": {
    "metaAgentSync": [
      {
        "businessId": 12345,
        "businessName": "Acme Store",
        "chatbotId": "550e8400-e29b-41d4-a716-446655440000",
        "chatbotName": "support_bot",
        "status": "warning",
        "warning": "Agent content is under review by Meta"
      }
    ]
  }
}
```

`status` is one of `synced`, `skipped`, `warning`, or `error`; `warning` and `error` carry the detail. `data` is omitted entirely when there is nothing to report.

> [!TIP]
> Every request to `/v1/org/code/*` acts on the business the API key belongs to. To deploy (and sync definitions) for another business in the same organisation, or to run code with that business's context, append `?business_id=<id>` to the URL.

---

## Run Deployed Code

:::api
method: POST
endpoint: /v1/org/code/run
title: Run Deployed Code
description: Execute the currently deployed (production) version of your function. Business context is injected automatically. Use this to trigger your functions from external systems or integrations.

## Body Parameters

- function_name: string [required] - Name of the function to execute
- clientWaNumber: string - WhatsApp number of the client this call is about. Copied into `business.clientWaNumber` so the handler sees the same shape as when a chatbot calls it.

```request
{
  "function_name": "welcome",
  "param1": "value1"
}
```

## Response

```response
{
  "message": "Code executed successfully",
  "data": {
    "result": { ... },
    "logs": "print output",
    "statusCode": 200
  }
}
```

:::

Any other top-level fields in the body are passed through to your handler unchanged, alongside the injected `business` block. The response has the same shape as **Test Draft Code**: `result`, `logs`, `statusCode`, and `functionError` when the handler raised.

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/org/code/run" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "function_name": "get_order_status",
    "order_id": "ORD-12345",
    "clientWaNumber": "919876543210"
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/org/code/run', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    function_name: 'get_order_status',
    order_id: 'ORD-12345',
    clientWaNumber: '919876543210',
  }),
});
const { data } = await response.json();
console.log(data.result, data.logs);
```

```python
import requests

response = requests.post(
    '{{API_URL}}/v1/org/code/run',
    headers={'Authorization': 'Bearer YOUR_API_KEY'},
    json={
        'function_name': 'get_order_status',
        'order_id': 'ORD-12345',
        'clientWaNumber': '919876543210',
    },
)
data = response.json()['data']
print(data['result'], data.get('logs'))
```

:::

If nothing has been deployed yet the request returns **400** `function not found for this org`. Deploy a version first.

---

## Errors

Errors follow the standard envelope: `{ "errorType": "BadRequest", "errorMessage": "..." }`.

| Status | `errorType`           | When                                                                                                                                                                                                        |
| ------ | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | `BadRequest`          | Missing `codeZipBase64` or `functionVersion`; invalid `version`; environment variables over 4096 bytes; a save still in progress; no code saved or deployed yet; deleting `$LATEST` or the deployed version |
| 401    | `Unauthorized`        | Missing, invalid, or revoked API key                                                                                                                                                                        |
| 403    | `Forbidden`           | The key lacks `org:read` / `org:write`; or someone is editing the code in the dashboard (save, create version, delete version only)                                                                         |
| 404    | `NotFound`            | The version to delete does not exist                                                                                                                                                                        |
| 500    | `InternalServerError` | The invocation, publish, or deployment failed on the platform side. Retry; if it persists, contact support                                                                                                  |

---

> [!IMPORTANT]
> **Run Deployed Code** always uses the production-deployed version. Make sure you've deployed a tested version before calling it from external systems.

> [!TIP]
> You can generate an API key from **Settings** → **Developer** in the dashboard.
