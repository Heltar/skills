---
title: Authentication
description: How to authenticate API requests
icon: Key
order: 2
---

# Authentication

All API requests require an API Key for authentication. API keys are tied to your business account and have access to all API endpoints.

---

## Getting Your API Key

1. Log in to the app
2. Go to **Settings** in the sidebar
3. Click on **Developer**
4. In the **API Keys** section, click **Generate New Key**
5. Copy and securely store your API key

> [!IMPORTANT]
> API keys are shown only once when generated. Store them securely - you cannot view the full key again.

---

## Using Your API Key

Include the API key in the `Authorization` header with every request:

```
Authorization: Bearer YOUR_API_KEY
```

---

## Example Requests

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/clients" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json"
```

```javascript
const response = await fetch('{{API_URL}}/v1/clients', {
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
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
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json'
    }
)
data = response.json()
```

:::

---

## Security Best Practices

> [!WARNING]
> Never expose your API key in public code or client-side applications.

| Do                                  | Don't                                |
| ----------------------------------- | ------------------------------------ |
| Store keys in environment variables | Hardcode keys in source code         |
| Make API calls from your server     | Make API calls from browser/frontend |
| Use HTTPS for all requests          | Use HTTP (unencrypted)               |
| Rotate keys periodically            | Share keys across teams              |
| Use separate keys for dev/prod      | Use production keys in development   |

### Environment Variables

Store your API key in environment variables:

```bash
# .env file (never commit this!)
HELTAR_API_KEY=your_api_key_here
```

```javascript
// Access in your code
const apiKey = process.env.HELTAR_API_KEY;
```

---

## Regenerating API Key

If your API key is compromised:

1. Go to **Settings** -> **Developer**
2. Click **Generate New Key**
3. Update your applications with the new key
4. The old key is automatically invalidated

> [!TIP]
> Set an expiration time when generating keys for added security. Expired keys stop working automatically.
