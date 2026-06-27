---
title: Authentication
description: How to authenticate API requests with API keys and scopes
icon: Key
order: 2
---

# Authentication

Every API request is authenticated with an **API key** sent as a Bearer token. Keys belong to a business and carry **scopes** that decide which endpoints they can call.

---

## Getting Your API Key

1. Log in to the app
2. Go to **Settings** -> **API Key / Dev tools**
3. Click **Create API Key**
4. Give it a name, choose its **scopes** (see below), optionally set an expiry
5. Copy and securely store the key — it looks like `hk_live_…`

> [!IMPORTANT]
> The full key is shown **only once**, right after you create it. Store it securely — you can't view it again. You can create as many keys as you need.

---

## Using Your API Key

Include the key in the `Authorization` header on every request:

```
Authorization: Bearer hk_live_xxxxxxxxxxxxxxxxxxxx
```

### Example Requests

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/clients" \
  -H "Authorization: Bearer hk_live_xxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json"
```

```javascript
const response = await fetch('{{API_URL}}/v1/clients', {
  headers: {
    Authorization: 'Bearer hk_live_xxxxxxxxxxxxxxxxxxxx',
    'Content-Type': 'application/json',
  },
});
const data = await response.json();
```

```python
import requests

response = requests.get(
    '{{API_URL}}/v1/clients',
    headers={
        'Authorization': 'Bearer hk_live_xxxxxxxxxxxxxxxxxxxx',
        'Content-Type': 'application/json'
    }
)
data = response.json()
```

:::

---

## Scopes

A scope is written as `resource:action`, where `action` is `read` or `write`. A request is allowed only if the key holds a scope that covers it.

| Scope            | Grants                                       |
| ---------------- | -------------------------------------------- |
| `*`              | Full access — every resource, read and write |
| `*:read`         | Read-only access to every resource           |
| `messages:write` | Send messages only                           |
| `clients:read`   | Read contacts only                           |
| `clients:*`      | Read **and** write contacts                  |

When you create a key you can pick a **preset** — **Full access** or **Read-only** — or select exactly the resources and actions you need (`messages`, `templates`, `campaigns`, `contacts`, `chatbots`, `groups`, `calls`, `schedule`, `code-editor`).

A call that the key isn't scoped for returns **403 Forbidden**.

> [!NOTE]
> Some dashboard-only areas (such as **webhooks** and **flows**) can never be reached with an API key — even a full-access (`*`) one. Configure those in the app.

---

## Revoking a Key

1. Go to **Settings** -> **API Key / Dev tools**
2. Find the key in the list and click **Revoke**

A revoked key stops working **immediately** on its next request. Your other keys are unaffected — revoking one key never disturbs the rest.

> [!TIP]
> Create separate keys per integration (and per environment) so you can revoke or rotate one without breaking the others. Set an expiry for short-lived keys — they stop working automatically when they expire.

---

## Security Best Practices

> [!WARNING]
> Never expose an API key in public code or client-side applications.

| Do                                  | Don't                                |
| ----------------------------------- | ------------------------------------ |
| Store keys in environment variables | Hardcode keys in source code         |
| Make API calls from your server     | Make API calls from browser/frontend |
| Use HTTPS for all requests          | Use HTTP (unencrypted)               |
| Scope keys to only what they need   | Use a full-access key for everything |
| Use separate keys for dev/prod      | Share one key across teams           |

### Environment Variables

```bash
# .env file (never commit this!)
HELTAR_API_KEY=hk_live_xxxxxxxxxxxxxxxxxxxx
```

```javascript
// Access in your code
const apiKey = process.env.HELTAR_API_KEY;
```

---

## Legacy Keys

Businesses created before scoped keys may still have a single older API key. It continues to work and behaves as a full-access key. You can retire it any time from **Settings** -> **API Key / Dev tools** using **Revoke legacy key**, which disables every old key issued for the business at once — your new `hk_live_…` keys keep working. New businesses don't have a legacy key.
