---
title: Contacts
description: Manage contacts via API
icon: Users
order: 4
---

# Contacts API

Create, update, and manage your WhatsApp contacts. Contacts are automatically created when you send a message, but you can also create them proactively with custom attributes.

---

:::api
method: POST
endpoint: /v1/clients
title: Create or Update Contacts
description: Create new contacts or update existing ones in bulk. If a contact with the same WhatsApp number exists, it will be updated with the new data.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number with country code (no + prefix)
- username: string - Contact display name
- countryCode: number - Country code (e.g., 91 for India)
- attributes: string [required] - JSON string of custom attributes
- assignTo: string - Agent email to assign the chat to

```request
[
  {
    "clientWaNumber": "919876543210",
    "username": "John Doe",
    "countryCode": 91,
    "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\",\"orderId\":\"ORD-123\"}",
    "assignTo": "agent@company.com"
  }
]
```

## Response

```response
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "John Doe",
    "clientWaNumber": "919876543210",
    "countryCode": 91,
    "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\"}",
    "isOpen": false,
    "isBotReply": true,
    "optedIn": true,
    "createdAt": "2024-01-15T10:00:00Z"
  }
]
```

:::

> [!TIP]
> Use custom attributes to store customer data like order IDs, subscription tier, or preferences. These can be used in chatbot flows and for segmentation.

---

:::api
method: GET
endpoint: /v1/clients
title: List All Contacts
description: Retrieve a paginated list of all contacts. Contacts are sorted by most recent activity.

## Query Parameters

- limit: number - Maximum contacts to return (default: 50, max: 100)
- offset: number - Pagination offset (default: 0)
- search: string - Search by name or phone number

## Response

```response
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "John Doe",
      "clientWaNumber": "919876543210",
      "countryCode": 91,
      "isOpen": true,
      "unreadMessages": 3,
      "latestMessageTimestamp": "2024-01-15T12:30:00Z"
    }
  ],
  "total": 150
}
```

:::

---

:::api
method: GET
endpoint: /v1/clients/:clientWaNumber
title: Get Contact
description: Get a specific contact by their WhatsApp number.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number of the contact

## Response

```response
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "John Doe",
  "clientWaNumber": "919876543210",
  "countryCode": 91,
  "attributes": "{\"city\":\"Mumbai\"}",
  "unreadMessages": 5,
  "isOpen": true,
  "isBotReply": false,
  "optedIn": true,
  "conversationExpire": "2024-01-16T10:00:00Z",
  "latestMessageTimestamp": "2024-01-15T12:30:00Z"
}
```

:::

---

:::api
method: DELETE
endpoint: /v1/clients
title: Delete Contacts
description: Delete multiple contacts by their WhatsApp numbers.

## Body Parameters

- clientWaNumbers: array [required] - Array of WhatsApp numbers to delete

```request
{
  "clientWaNumbers": ["919876543210", "919876543211"]
}
```

:::

---

:::api
method: PUT
endpoint: /v1/clients/attributes-and-tags
title: Update Attributes & Tags
description: Update custom attributes and tags for a contact.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number
- attributes: object - Custom key-value attributes
- tags: array - Array of tag strings

```request
{
  "clientWaNumber": "919876543210",
  "attributes": {
    "city": "Delhi",
    "tier": "gold",
    "lastPurchase": "2024-01-15"
  },
  "tags": ["premium", "active", "newsletter"]
}
```

:::

---

## Chat Management

:::api
method: PUT
endpoint: /v1/clients/chat/toggle/:clientWaNumber
title: Toggle Chat Status
description: Open or close a chat conversation.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number

## Body Parameters

- isOpen: boolean [required] - true to open, false to close

```request
{
  "isOpen": true
}
```

:::

---

:::api
method: POST
endpoint: /v1/clients/chat/assign
title: Assign Chat
description: Assign a chat to an agent.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number
- employeeId: number [required] - Agent ID

```request
{
  "clientWaNumber": "919876543210",
  "employeeId": 123
}
```

:::

---

## Bot Management

:::api
method: PUT
endpoint: /v1/clients/bot/toggle/:clientWaNumber
title: Toggle Bot
description: Enable or disable chatbot for a specific contact.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number

## Body Parameters

- isBotReply: boolean [required] - true to enable, false to disable

```request
{
  "isBotReply": true
}
```

:::

---

## Contact Fields Reference

| Field                    | Type    | Description                                    |
| ------------------------ | ------- | ---------------------------------------------- |
| `id`                     | string  | Unique identifier (UUID)                       |
| `username`               | string  | Contact display name                           |
| `clientWaNumber`         | string  | WhatsApp number with country code              |
| `countryCode`            | number  | Country calling code (e.g., 91)                |
| `attributes`             | string  | Custom attributes as JSON string               |
| `unreadMessages`         | number  | Count of unread messages                       |
| `isOpen`                 | boolean | Whether chat is open (true) or closed (false)  |
| `isBotReply`             | boolean | Whether chatbot is enabled for this contact    |
| `optedIn`                | boolean | Marketing opt-in status                        |
| `conversationExpire`     | string  | ISO 8601 timestamp when 24-hour window expires |
| `latestMessageTimestamp` | string  | Timestamp of most recent message               |
| `createdAt`              | string  | When the contact was created                   |
