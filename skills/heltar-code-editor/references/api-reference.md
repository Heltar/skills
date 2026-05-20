---
title: Code Editor
description: Execute custom functions from the code editor
icon: Code
order: 7
---

# Code Editor API

Execute custom functions written in the code editor. Send a request with the function name and parameters — business context is injected automatically.

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

When the same function is invoked from a chatbot conversation (i.e. the bot calls it as a tool while replying to a client), the `business` block additionally includes `clientWaNumber` — the WhatsApp number of the client the bot is currently talking to. This field is **not** present when the function is invoked directly via `POST /v1/org/code/run`.

---

## Run Deployed Code

:::api
method: POST
endpoint: /v1/org/code/run
title: Run Deployed Code
description: Execute the currently deployed (production) version of your function. Business context is injected automatically. Use this to trigger your functions from external systems or integrations.

## Body Parameters

- function_name: string [required] - Name of the function to execute
- \*: any - Any additional parameters your function expects

```request
{
  "function_name": "welcome",
  "param1": "value1"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Code executed successfully",
  "data": {
    "result": { ... },
    "logs": "print output",
    "statusCode": 200
  }
}
```

:::

---

> [!IMPORTANT]
> **Run Deployed Code** always uses the production-deployed version. Make sure you've deployed a tested version before calling it from external systems.

> [!TIP]
> You can generate an API key from **Settings** → **Developer** in the dashboard.
