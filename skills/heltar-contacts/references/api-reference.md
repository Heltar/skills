---
title: Contacts
description: Manage contacts via API
icon: Users
order: 4
---

# Contacts API

Create, update, and manage your WhatsApp contacts. Contacts are automatically created when you send a message, but you can also create them proactively with custom attributes.

| Method | Endpoint                                        | Purpose                                               |
| ------ | ----------------------------------------------- | ----------------------------------------------------- |
| POST   | `/v1/clients`                                   | Create or update contacts in bulk                     |
| GET    | `/v1/clients`                                   | List contacts (keyset paginated, filterable)          |
| GET    | `/v1/clients/:clientWaNumber`                   | Get one contact                                       |
| GET    | `/v1/clients/client-attributes/:clientWaNumber` | Get one contact's attributes as parsed JSON           |
| DELETE | `/v1/clients`                                   | Delete contacts                                       |
| PUT    | `/v1/clients/attributes-and-tags`               | Update attributes and tags in bulk                    |
| GET    | `/v1/business/attributes`                       | List attribute definitions                            |
| POST   | `/v1/business/attributes`                       | Create attribute definitions                          |
| PUT    | `/v1/business/attributes`                       | Rename or retype an attribute definition              |
| DELETE | `/v1/business/attributes`                       | Delete an attribute definition                        |
| PUT    | `/v1/clients/chat/toggle/:clientWaNumber`       | Open or close a chat                                  |
| POST   | `/v1/clients/chat/assign`                       | Assign a chat to one agent (or auto-assign)           |
| POST   | `/v1/clients/chat/multiassign`                  | Assign a chat to several agents, or unassign          |
| PUT    | `/v1/clients/chat/block/:clientWaNumber`        | Block or unblock a contact                            |
| GET    | `/v1/clients/blocked`                           | List blocked contacts                                 |
| PUT    | `/v1/clients/bot/toggle/:clientWaNumber`        | Enable or disable the chatbot for a contact           |
| GET    | `/v1/clients/:clientWaNumber/profile`           | Get the unified profile behind a contact              |
| PUT    | `/v1/clients/:clientWaNumber/profile`           | Update the unified profile (email, phone, attributes) |
| DELETE | `/v1/clients/:clientWaNumber/contact-book`      | Remove a contact from WhatsApp's contact book         |

---

## Authentication

All contacts endpoints require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

`GET` requests need the `clients:read` scope; every other method needs `clients:write`. A key without the scope receives `403 Forbidden`. See [Authentication](/docs/api/authentication) for full setup instructions.

> [!NOTE]
> `clientWaNumber` accepts a phone number with country code (`919876543210`). A `+`, spaces, or dashes are stripped before lookup, so `+91 98765-43210` resolves to the same contact. The same field also accepts a WhatsApp user ID for a contact who hides their phone number (`BD.1068713429041673`), an RCS thread (`919876543210@rcs`), a web-chat visitor (`<visitorId>@web`), or a WhatsApp group ID.

---

## Contacts

:::api
method: POST
endpoint: /v1/clients
title: Create or Update Contacts
description: Create new contacts or update existing ones in bulk. The body is an array. If a contact with the same WhatsApp number exists, it is updated with the new data; attributes are merged into the existing set.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number with country code (no + prefix)
- username: string [required] - Contact display name. Send an empty string to keep the existing name (a new contact then uses its number as the name)
- countryCode: number [required] - Country calling code (e.g. 91 for India). The key must be present; send `null` to derive it from the number
- attributes: string [required] - Custom attributes as a JSON string (a JSON object is also accepted). Keys must be non-empty. Include a `tags` array to set tags
- assignTo: string - Email of an agent in this business. The agent is added to the contact's assignees

```request
[
  {
    "clientWaNumber": "919876543210",
    "username": "John Doe",
    "countryCode": 91,
    "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\",\"orderId\":\"ORD-12345\",\"tags\":[\"vip\"]}",
    "assignTo": "agent@company.com"
  },
  {
    "clientWaNumber": "919876543211",
    "username": "",
    "countryCode": null,
    "attributes": { "city": "Delhi" }
  }
]
```

## Response

```response
{
  "message": "Clients created/updated successfully",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "John Doe",
      "clientWaNumber": "919876543210",
      "countryCode": 91,
      "attributes": "{\"city\":\"Mumbai\",\"tier\":\"premium\",\"orderId\":\"ORD-12345\",\"tags\":[\"vip\"]}",
      "unreadMessages": 0,
      "isOpen": false,
      "isBotReply": true,
      "optedIn": true,
      "isBlocked": false,
      "businessEmployees": [
        { "id": 123, "name": "Priya Sharma", "email": "agent@company.com" }
      ],
      "conversationExpire": "2026-09-09T10:00:00.000Z",
      "latestMessageTimestamp": "2026-09-09T10:00:00.000Z",
      "createdAt": "2026-09-09T10:00:00.000Z"
    }
  ]
}
```

:::

How the request is processed:

- Numbers are deduplicated within the request (the first occurrence wins) and processed in batches of 1000.
- When `countryCode` is given, the number is validated against it and the contact is rejected if they do not match. When it is `null`, the code is derived from the number (falling back to the stored value, then to `91`).
- `attributes` are merged key by key into the contact's existing attributes. Existing keys that are not in the request are kept.
- Every attribute key must have a definition (see [Attribute definitions](#attribute-definitions)). A key with no definition is created automatically as a `text` attribute. A `tags` value that is not yet a known tag option is added to the tag options automatically (up to 500 options).
- Values are validated against the definition's type: `numerical` must be a number or numeric string, `dropdown` must be one of the options, `tags` must be an array of known options. A value for a `text` attribute that is not a string is stored as its JSON string.
- `assignTo` must be an agent of this business, otherwise that contact fails.

> [!WARNING]
> If any contact in the request fails, the response is `400` and `errorRaw` carries both `successfulClients` and `failedClients` (each failed entry has the `client` you sent and an `error` reason). Contacts that passed validation are still saved. For contacts created by this call, the `id` in the response is a temporary placeholder; read the contact back with `GET /v1/clients/:clientWaNumber` to get its permanent `id`.

> [!TIP]
> Use custom attributes to store customer data like order IDs, subscription tier, or preferences. These can be used in chatbot flows and for segmentation.

### Create or Update Contacts Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/clients" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "clientWaNumber": "919876543210",
      "username": "John Doe",
      "countryCode": 91,
      "attributes": "{\"city\":\"Mumbai\",\"orderId\":\"ORD-12345\",\"tags\":[\"vip\"]}",
      "assignTo": "agent@company.com"
    }
  ]'
```

```javascript
const response = await fetch('{{API_URL}}/v1/clients', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify([
    {
      clientWaNumber: '919876543210',
      username: 'John Doe',
      countryCode: 91,
      attributes: JSON.stringify({
        city: 'Mumbai',
        orderId: 'ORD-12345',
        tags: ['vip'],
      }),
      assignTo: 'agent@company.com',
    },
  ]),
});
const { data } = await response.json();
```

```python
import json
import requests

response = requests.post(
    "{{API_URL}}/v1/clients",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json=[
        {
            "clientWaNumber": "919876543210",
            "username": "John Doe",
            "countryCode": 91,
            "attributes": json.dumps(
                {"city": "Mumbai", "orderId": "ORD-12345", "tags": ["vip"]}
            ),
            "assignTo": "agent@company.com",
        }
    ],
)
contacts = response.json()["data"]
```

:::

---

:::api
method: GET
endpoint: /v1/clients
title: List Contacts (keyset paginated)
description: Returns a page of contacts. Contacts with a chat come first, newest message first; once those are exhausted, contacts that have never sent or received a message (created via API or bot assignment) fill the rest of the page. Pass the `nextCursor` from a response back as `cursor` to fetch the next page; iteration ends when `nextCursor` is `null`.

## Query Parameters

- cursor: string - Opaque pagination token from a prior response's `nextCursor`. Omit for the first page and pass back as-is on subsequent calls
- limit: number - Page size. Without filters the default and maximum are 5000. With any filter set, the default is 500 and the maximum is 1000
- tags: string - Only contacts carrying ALL of the given tags. Repeat the parameter for several tags (`?tags=vip&tags=newsletter`). Up to 20 tags of at most 120 characters each; longer or empty values are ignored
- isOpen: boolean - `true` for open chats only, `false` for closed chats only
- unread: boolean - `true` for chats with unread messages (including chats manually marked unread). `false` has no effect
- assigned: boolean - `true` for chats with at least one assigned agent, `false` for unassigned chats
- isBotReply: boolean - `true` for contacts where the chatbot is enabled, `false` where it is disabled
- view: string - `all` (default) or `your`. `your` restricts to chats assigned to the signed-in dashboard user; an API key has no user identity, so `view=your` always returns an empty page
- afterTs: number - Epoch milliseconds of a boundary contact's `latestMessageTimestamp`. Together with `afterId`, starts a filtered listing below that contact. Honoured only when `cursor` is omitted and at least one filter is set
- afterId: string - UUID of the boundary contact, used with `afterTs`

## Response

```response
{
  "message": "Successfully retrieved client list",
  "data": {
    "clients": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "John Doe",
        "clientWaNumber": "919876543210",
        "countryCode": 91,
        "attributes": "{\"city\":\"Mumbai\",\"tags\":[\"vip\"]}",
        "unreadMessages": 3,
        "isOpen": true,
        "isBotReply": true,
        "optedIn": true,
        "isBlocked": false,
        "businessEmployees": [
          { "id": 123, "name": "Priya Sharma", "email": "agent@company.com" }
        ],
        "conversationExpire": "2026-09-10T12:30:00.000Z",
        "latestMessageTimestamp": "2026-09-09T12:30:00.000Z",
        "latestMessage": {
          "text": "Is my order shipped?",
          "type": "text",
          "timestamp": "2026-09-09T12:30:00.000Z",
          "historyText": "Is my order shipped?"
        },
        "createdAt": "2026-08-01T10:00:00.000Z",
        "updatedAt": "2026-09-09T12:30:00.000Z"
      }
    ],
    "nextCursor": "eyJ0cyI6MTcwNTMyMTgwMDAwMCwiaWQiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAifQ"
  }
}
```

:::

Filters are combined with AND and match only contacts that have a chat; contacts that have never exchanged a message never match a filtered listing. An invalid filter value (for example `isOpen=yes`) returns `400`. Blocked contacts are removed from every page, so a page can hold fewer than `limit` contacts while `nextCursor` is still set.

> [!NOTE]
> Full-text contact search is intentionally not supported here. Look up an exact contact via `GET /v1/clients/:clientWaNumber`, or search message content via the messages-search endpoint.

### List Contacts Example

```bash
curl -X GET "{{API_URL}}/v1/clients?limit=500&isOpen=true&assigned=false&tags=vip" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```bash
curl -X GET "{{API_URL}}/v1/clients?cursor=eyJ0cyI6MTcwNTMyMTgwMDAwMCwiaWQiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAifQ" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/clients/:clientWaNumber
title: Get Contact
description: Get a specific contact by their WhatsApp number. Blocked contacts are returned too, with `isBlocked` set to `true`.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number of the contact

## Response

```response
{
  "message": "Successfully retrieved client details",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "John Doe",
    "clientWaNumber": "919876543210",
    "countryCode": 91,
    "attributes": "{\"city\":\"Mumbai\",\"tags\":[\"vip\"]}",
    "unreadMessages": 5,
    "isOpen": true,
    "isBotReply": false,
    "optedIn": true,
    "isBlocked": false,
    "businessEmployees": [
      { "id": 123, "name": "Priya Sharma", "email": "agent@company.com" }
    ],
    "assignedChatbotId": null,
    "masterClientId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "sessionClearedAt": null,
    "conversationExpire": "2026-09-10T10:00:00.000Z",
    "latestMessageTimestamp": "2026-09-09T12:30:00.000Z",
    "latestMessage": {
      "text": "Is my order shipped?",
      "type": "text",
      "timestamp": "2026-09-09T12:30:00.000Z",
      "historyText": "Is my order shipped?"
    },
    "createdAt": "2026-08-01T10:00:00.000Z",
    "updatedAt": "2026-09-09T12:30:00.000Z"
  }
}
```

:::

Returns `404` with `"Client Details not found with 919876543210"` when the contact does not exist.

### Get Contact Example

```bash
curl -X GET "{{API_URL}}/v1/clients/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: GET
endpoint: /v1/clients/client-attributes/:clientWaNumber
title: Get Contact Attributes
description: Returns only the contact's custom attributes, as a parsed JSON object instead of the JSON string other contact endpoints return.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number of the contact

## Response

```response
{
  "code": 200,
  "message": "Successfully retrieved client attributes",
  "data": {
    "attributes": {
      "city": "Mumbai",
      "tier": "premium",
      "orderValue": 4999,
      "tags": ["vip", "newsletter"]
    }
  }
}
```

:::

Attribute values that were stored as JSON strings (for example a number sent to a `text` attribute) are decoded back to their native type; any value that is not valid JSON is returned as-is. This endpoint's response includes a `code` field alongside `message` and `data`. Returns `404` when the contact does not exist.

### Get Contact Attributes Example

```bash
curl -X GET "{{API_URL}}/v1/clients/client-attributes/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: DELETE
endpoint: /v1/clients
title: Delete Contacts
description: Delete multiple contacts by their WhatsApp numbers.

## Body Parameters

- clientWaNumbers: array [required] - Array of WhatsApp numbers to delete (at least one)

```request
{
  "clientWaNumbers": ["919876543210", "919876543211"]
}
```

## Response

```response
{
  "message": "Successfully deleted clients",
  "data": {
    "notDeleted": [],
    "deletedCount": 2
  }
}
```

:::

`notDeleted` lists the requested numbers that still exist after the call; `deletedCount` is the number of requested numbers that no longer exist (a number that never existed counts as deleted). Numbers are processed in batches of 1000.

### Delete Contacts Example

```bash
curl -X DELETE "{{API_URL}}/v1/clients" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "clientWaNumbers": ["919876543210", "919876543211"] }'
```

---

:::api
method: PUT
endpoint: /v1/clients/attributes-and-tags
title: Update Attributes & Tags
description: Update custom attributes and tags for one or more contacts. The body is an array; each entry must carry `attributes`, `tags`, or both. Attributes are merged into the contact's existing set; `tags` replaces the contact's full tag list.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number
- attributes: object - Custom key-value attributes to merge. Keys with no definition are created as `text` attributes
- tags: array - Tags as strings (numbers are converted to strings). Replaces the contact's tags. Unknown tags are added to the tag options automatically

```request
[
  {
    "clientWaNumber": "919876543210",
    "attributes": {
      "city": "Delhi",
      "tier": "gold",
      "lastPurchase": "2026-09-01"
    },
    "tags": ["premium", "active", "newsletter"]
  },
  {
    "clientWaNumber": "919876543211",
    "tags": ["newsletter"]
  }
]
```

## Response

```response
{
  "message": "Bulk update completed. 2 successful, 0 failed",
  "data": {
    "summary": { "total": 2, "successful": 2, "failed": 0 },
    "results": [
      {
        "clientWaNumber": "919876543210",
        "success": true,
        "attributes": "{\"city\":\"Delhi\",\"tier\":\"gold\",\"lastPurchase\":\"2026-09-01\",\"tags\":[\"premium\",\"active\",\"newsletter\"]}"
      },
      {
        "clientWaNumber": "919876543211",
        "success": true,
        "attributes": "{\"city\":\"Mumbai\",\"tags\":[\"newsletter\"]}"
      }
    ]
  }
}
```

:::

Each entry succeeds or fails on its own: a failed entry appears in `results` with `success: false` and an `error` such as `"Client not found with WA Number: 919876543299"` or a type-validation message (see [Attribute definitions](#attribute-definitions)). The request returns `200` as long as at least one entry succeeded; when every entry fails it returns `400` with the same `summary` and `results` inside `errorRaw`. An empty array returns `400`.

### Update Attributes & Tags Example

```bash
curl -X PUT "{{API_URL}}/v1/clients/attributes-and-tags" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "clientWaNumber": "919876543210",
      "attributes": { "city": "Delhi", "tier": "gold" },
      "tags": ["premium", "newsletter"]
    }
  ]'
```

---

## Attribute definitions

Every custom attribute a contact can hold is declared once at the business level with a `fieldKey` and a `dataType`. The per-contact `attributes` you send through `POST /v1/clients` and `PUT /v1/clients/attributes-and-tags` are validated against these definitions:

| `dataType`  | Extra field       | Accepted contact value                                 |
| ----------- | ----------------- | ------------------------------------------------------ |
| `text`      | none              | Any value; non-strings are stored as their JSON string |
| `numerical` | none              | A number, or a string that parses as a number          |
| `dropdown`  | `dropdownOptions` | One of the listed options                              |
| `tags`      | `tagOptions`      | An array whose every item is one of the listed options |

A value that does not fit returns `400`, for example `"Invalid value for attribute tier. Expected one of the following dropdown options: silver, gold, premium."`

The contact endpoints create definitions on the fly: an unknown key becomes a `text` attribute, and a new tag value is appended to the `tags` definition's `tagOptions` (up to 500 options of at most 120 characters; beyond that, unknown tags are rejected). Define an attribute here first when you want it to be `numerical`, `dropdown`, or `tags`, or use `PUT /v1/business/attributes` to change the type of one that was auto-created as `text`.

`tags` is a reserved definition of type `tags`. It cannot be created with `POST` or removed with `DELETE`; manage its `tagOptions` with `PUT`.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: GET
endpoint: /v1/business/attributes
title: List Attribute Definitions
description: Returns every attribute definition of the business.

## Response

```response
{
  "message": "Successfully Fetched Attributes",
  "data": [
    { "fieldKey": "city", "dataType": "text" },
    { "fieldKey": "orderValue", "dataType": "numerical" },
    {
      "fieldKey": "tier",
      "dataType": "dropdown",
      "dropdownOptions": ["silver", "gold", "premium"]
    },
    {
      "fieldKey": "tags",
      "dataType": "tags",
      "tagOptions": ["vip", "newsletter"]
    }
  ]
}
```

:::

### List Attribute Definitions Example

```bash
curl -X GET "{{API_URL}}/v1/business/attributes" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: POST
endpoint: /v1/business/attributes
title: Create Attribute Definitions
description: Add one or more attribute definitions. Every `fieldKey` in the request must be new; the whole request is rejected if any already exists.

## Body Parameters

- attributes: array [required] - Definitions to add. Each item has `fieldKey` (non-empty string) and `dataType` (`numerical`, `text`, `dropdown`, or `tags`). A `dropdown` item needs `dropdownOptions` (at least one string); a `tags` item needs `tagOptions` (at least one string)

```request
{
  "attributes": [
    { "fieldKey": "orderValue", "dataType": "numerical" },
    {
      "fieldKey": "tier",
      "dataType": "dropdown",
      "dropdownOptions": ["silver", "gold", "premium"]
    }
  ]
}
```

## Response

```response
{
  "message": "Successfully added attributes: orderValue, tier",
  "data": [
    { "fieldKey": "city", "dataType": "text" },
    { "fieldKey": "orderValue", "dataType": "numerical" },
    {
      "fieldKey": "tier",
      "dataType": "dropdown",
      "dropdownOptions": ["silver", "gold", "premium"]
    },
    {
      "fieldKey": "tags",
      "dataType": "tags",
      "tagOptions": ["vip", "newsletter"]
    }
  ]
}
```

:::

Returns `409 Conflict` when a `fieldKey` already exists (`"Attributes tier already exist!"`) or when the request tries to create `tags`. `data` is the complete definition list after the change.

### Create Attribute Definitions Example

```bash
curl -X POST "{{API_URL}}/v1/business/attributes" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": [
      { "fieldKey": "orderValue", "dataType": "numerical" },
      { "fieldKey": "tier", "dataType": "dropdown", "dropdownOptions": ["silver", "gold", "premium"] }
    ]
  }'
```

---

:::api
method: PUT
endpoint: /v1/business/attributes
title: Update Attribute Definition
description: Rename an attribute, change its type or options, or both. The value stored on every contact that has the attribute is converted to fit the new definition.

## Body Parameters

- oldAttribute: string [required] - The current `fieldKey`
- newAttribute: object [required] - The full replacement definition: `fieldKey`, `dataType`, and `dropdownOptions` or `tagOptions` where the type needs them

```request
{
  "oldAttribute": "tier",
  "newAttribute": {
    "fieldKey": "membershipTier",
    "dataType": "dropdown",
    "dropdownOptions": ["silver", "gold", "premium", "platinum"]
  }
}
```

## Response

```response
{
  "message": "Successfully Updated Attribute: tier to membershipTier",
  "data": [
    { "fieldKey": "city", "dataType": "text" },
    { "fieldKey": "orderValue", "dataType": "numerical" },
    {
      "fieldKey": "tags",
      "dataType": "tags",
      "tagOptions": ["vip", "newsletter"]
    },
    {
      "fieldKey": "membershipTier",
      "dataType": "dropdown",
      "dropdownOptions": ["silver", "gold", "premium", "platinum"]
    }
  ]
}
```

:::

How contact values are converted to the new `dataType`:

- `numerical`: a value that parses as a number is kept; anything else becomes `0`.
- `text`: the value is converted to a string.
- `dropdown`: the value is kept only if the old type was also `dropdown` and the value is one of the new options; otherwise it becomes the first option.
- `tags`: only values present in the new `tagOptions` are kept.

Rules for `tags`: `oldAttribute` and `newAttribute.fieldKey` must both be `tags` (renaming to or from `tags` returns `400`). If the business has no `tags` definition yet, this call creates it. Returns `400` when `oldAttribute` does not exist, or when `newAttribute.fieldKey` is already used by a different attribute.

### Update Attribute Definition Example

```bash
curl -X PUT "{{API_URL}}/v1/business/attributes" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "oldAttribute": "tags",
    "newAttribute": { "fieldKey": "tags", "dataType": "tags", "tagOptions": ["vip", "newsletter", "churn-risk"] }
  }'
```

---

:::api
method: DELETE
endpoint: /v1/business/attributes
title: Delete Attribute Definition
description: Remove an attribute definition and delete that key from every contact that has it.

## Query Parameters

- attribute: string [required] - The `fieldKey` to delete

## Response

```response
{
  "message": "Successfully Deleted Attribute: orderValue",
  "data": [
    { "fieldKey": "city", "dataType": "text" },
    {
      "fieldKey": "tags",
      "dataType": "tags",
      "tagOptions": ["vip", "newsletter"]
    }
  ]
}
```

:::

Returns `400` when `attribute` is missing, when it is `tags`, or when no such attribute exists.

### Delete Attribute Definition Example

```bash
curl -X DELETE "{{API_URL}}/v1/business/attributes?attribute=orderValue" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

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

- isOpen: boolean [required] - true to open, false to close (the strings `"true"` and `"false"` are also accepted)

```request
{
  "isOpen": true
}
```

## Response

```response
{
  "message": "Client chat status updated successfully"
}
```

:::

Returns `404` when the contact does not exist.

### Toggle Chat Status Example

```bash
curl -X PUT "{{API_URL}}/v1/clients/chat/toggle/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isOpen": false }'
```

---

:::api
method: POST
endpoint: /v1/clients/chat/assign
title: Assign Chat
description: Assign a chat to one agent by email, replacing any current assignees. Omit `email` to auto-assign the chat to an active agent.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number
- email: string - Email of an agent in your organisation. When omitted or `null`, the chat is auto-assigned to one of the currently active agents

```request
{
  "clientWaNumber": "919876543210",
  "email": "agent@company.com"
}
```

## Response

```response
{
  "message": "Successfully assigned John Doe Priya Sharma"
}
```

:::

The assigned agent receives an in-app notification. Returns `404` when the contact does not exist, `400` with `"agent@company.com not exists!"` when the email is not an agent of your organisation, and `400` with `"No active employee found to assign chat!"` when auto-assignment finds nobody online.

### Assign Chat Example

```bash
curl -X POST "{{API_URL}}/v1/clients/chat/assign" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "clientWaNumber": "919876543210", "email": "agent@company.com" }'
```

---

:::api
method: POST
endpoint: /v1/clients/chat/multiassign
title: Assign Chat to Multiple Agents
description: Replace a chat's assignees with the given list of agents. Send an empty list to unassign everyone.

## Body Parameters

- clientWaNumber: string [required] - WhatsApp number
- emails: array [required] - Agent emails (case-insensitive). Every email must belong to an agent in your organisation. An empty array removes all assignees

```request
{
  "clientWaNumber": "919876543210",
  "emails": ["agent@company.com", "lead@company.com"]
}
```

## Response

```response
{
  "message": "Successfully assigned John Doe to Priya Sharma, Rahul Verma"
}
```

:::

Each assigned agent receives an in-app notification. Returns `404` when the contact does not exist. When any email is unknown, the request returns `400` with `"Some employees do not exist!"` and `errorRaw.emails` lists the unknown ones; nothing is changed.

### Assign Chat to Multiple Agents Example

```bash
curl -X POST "{{API_URL}}/v1/clients/chat/multiassign" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "clientWaNumber": "919876543210", "emails": [] }'
```

---

## Blocking

:::api
method: PUT
endpoint: /v1/clients/chat/block/:clientWaNumber
title: Block or Unblock Contact
description: Block a contact so they can no longer message you, or lift an existing block. The block is applied on WhatsApp as well as in your inbox.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number

## Body Parameters

- isBlocked: boolean [required] - true to block, false to unblock (the strings `"true"` and `"false"` are also accepted)

```request
{
  "isBlocked": true
}
```

## Response

```response
{
  "message": "Client blocked successfully"
}
```

:::

WhatsApp only accepts a block within 24 hours of the contact's last message to you. If that window has passed, the block is still saved on your side and is applied on WhatsApp automatically the next time the contact messages you. Unblocking returns `"Client unblocked successfully"`.

While a contact is blocked:

- they are excluded from `GET /v1/clients` and listed by `GET /v1/clients/blocked`; `GET /v1/clients/:clientWaNumber` still returns them with `isBlocked: true`
- a template message to them is recorded as failed with the reason `Client is blocked` and is not delivered
- any other message type to them is rejected with `400 Client is blocked`

Returns `404` when the contact does not exist, and `400` when your WhatsApp number is not connected yet.

### Block Contact Example

```bash
curl -X PUT "{{API_URL}}/v1/clients/chat/block/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isBlocked": true }'
```

---

:::api
method: GET
endpoint: /v1/clients/blocked
title: List Blocked Contacts
description: Returns every blocked contact of the business, sorted by name. The list is not paginated.

## Response

```response
{
  "message": "Blocked clients fetched successfully",
  "data": [
    {
      "id": "8a1f3c2e-5b6d-4e7f-9a0b-1c2d3e4f5a6b",
      "clientWaNumber": "919876543299",
      "username": "Unknown Caller"
    }
  ]
}
```

:::

### List Blocked Contacts Example

```bash
curl -X GET "{{API_URL}}/v1/clients/blocked" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

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

- isBotReply: boolean [required] - true to enable, false to disable (the strings `"true"` and `"false"` are also accepted)

```request
{
  "isBotReply": true
}
```

## Response

```response
{
  "message": "Client bot status active successfully"
}
```

:::

Disabling the bot discards any flow the contact was in the middle of, so re-enabling it starts a fresh conversation; the response then reads `"Client bot status inactive successfully"`. Each change is recorded as a private note in the chat. Returns `404` when the contact does not exist. When the chat is being handled by a Meta AI agent, turning the bot off is refused with `400` until the agent hands the conversation over.

To pin a specific chatbot to a contact or reset its conversation memory, see [Assign Chatbot to Contact](/docs/api/chatbot) and [Clear Bot Session](/docs/api/chatbot).

### Toggle Bot Example

```bash
curl -X PUT "{{API_URL}}/v1/clients/bot/toggle/919876543210" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isBotReply": false }'
```

---

## Unified profile

A contact is one channel thread (a WhatsApp number, an RCS thread, a web-chat visitor). The unified profile is the person behind those threads: one record per organisation with a primary phone, an email, its own free-form attributes, and the list of channel threads that belong to it. Threads are linked to a profile automatically as they are matched by phone or email.

:::api
method: GET
endpoint: /v1/clients/:clientWaNumber/profile
title: Get Unified Profile
description: Returns the person behind a contact and every channel thread linked to them.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number (or any other contact identifier) of one of the person's threads

## Response

```response
{
  "message": "Unified profile retrieved",
  "data": {
    "masterClientId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "primaryPhone": "919876543210",
    "email": "john@example.com",
    "attributes": { "crmId": "C-12345" },
    "channels": [
      {
        "clientWaNumber": "919876543210",
        "channel": "whatsapp",
        "username": "John Doe",
        "latestMessageTimestamp": "2026-09-09T12:30:00.000Z"
      },
      {
        "clientWaNumber": "919876543210@rcs",
        "channel": "rcs",
        "username": "John Doe",
        "latestMessageTimestamp": null
      }
    ]
  }
}
```

:::

`channel` is one of `whatsapp`, `rcs`, `web`, or `other`. `masterClientId` is `null` and `channels` is empty when no profile exists yet for that number; the call does not return `404`. Profile `attributes` are separate from the per-contact `attributes` and are not validated against attribute definitions.

### Get Unified Profile Example

```bash
curl -X GET "{{API_URL}}/v1/clients/919876543210/profile" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: PUT
endpoint: /v1/clients/:clientWaNumber/profile
title: Update Unified Profile
description: Set the email, primary phone, or profile attributes of the person behind a contact. A profile is created if none exists. Omit a field to leave it unchanged; send `null` to clear it.

## Path Parameters

- clientWaNumber: string [required] - WhatsApp number (or any other contact identifier) of one of the person's threads

## Body Parameters

- email: string - Email address (normalised to lower case), or `null` to clear
- primaryPhone: string - Phone number; everything except digits is stripped and at least 7 digits must remain. `null` clears it
- attributes: object - Profile attributes, merged key by key into the existing ones

```request
{
  "email": "john@example.com",
  "primaryPhone": "+91 98765 43210",
  "attributes": { "crmId": "C-12345" }
}
```

## Response

```response
{
  "message": "Profile updated",
  "data": {
    "masterClientId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "primaryPhone": "919876543210",
    "email": "john@example.com",
    "attributes": { "crmId": "C-12345" },
    "channels": [
      {
        "clientWaNumber": "919876543210",
        "channel": "whatsapp",
        "username": "John Doe",
        "latestMessageTimestamp": "2026-09-09T12:30:00.000Z"
      }
    ]
  }
}
```

:::

Unknown body fields are rejected with `400`. If the `email` or `primaryPhone` you send already belongs to another profile in your organisation, this contact's threads are moved into that profile (the existing profile keeps its own values and fills in only blanks) and the merged profile is returned. Returns `400` with `"This email address is already linked to another contact"` if the merge cannot complete.

### Update Unified Profile Example

```bash
curl -X PUT "{{API_URL}}/v1/clients/919876543210/profile" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "email": "john@example.com", "attributes": { "crmId": "C-12345" } }'
```

---

## Opt-in / opt-out status

Every contact carries an `optedIn` boolean (default `true`). It is returned in `GET /v1/clients`, `GET /v1/clients/:clientWaNumber`, and in the `POST /v1/clients` response for contacts that already existed.

**It cannot be set through the API.** `POST /v1/clients` ignores an `optedIn` field in the body, `PUT /v1/clients/attributes-and-tags` would store it as an ordinary custom attribute with no effect on the flag, and `PUT /v1/clients/:clientWaNumber/profile` rejects unknown fields. The flag changes only when the contact messages you:

- while a contact is opted in, each incoming text, media caption, or interactive reply is checked against your opt-out keyword rules; a match sets `optedIn` to `false` and, if configured, sends the contact a confirmation template
- while a contact is opted out, each incoming message is checked against your opt-in keyword rules; a match sets `optedIn` back to `true`

The keyword rules (`isEqualTo`, `contains`, `startsWith`, `endsWith`, combined with `AND`/`OR`) and the optional confirmation template are configured with `PUT /v1/business/opt-rules`; see [Business](/docs/api/business).

What happens to an opted-out contact:

- a template message sent to them, whether through `POST /v1/messages/send` or a campaign, is recorded as failed and not delivered; the failure reason is `Client has not opted in` for a direct send and `Client did not opt-in` for a campaign
- any other message type sent to them is rejected with `400 Client has not opted in`
- chatbots do not reply to them

---

## Contact Fields Reference

| Field                    | Type    | Description                                                                               |
| ------------------------ | ------- | ----------------------------------------------------------------------------------------- |
| `id`                     | string  | Unique identifier (UUID)                                                                  |
| `username`               | string  | Contact display name                                                                      |
| `clientWaNumber`         | string  | WhatsApp number with country code                                                         |
| `countryCode`            | number  | Country calling code (e.g., 91)                                                           |
| `attributes`             | string  | Custom attributes as JSON string (includes the `tags` array)                              |
| `unreadMessages`         | number  | Count of unread messages; `-1` when the chat was manually marked unread                   |
| `isOpen`                 | boolean | Whether chat is open (true) or closed (false)                                             |
| `isBotReply`             | boolean | Whether chatbot is enabled for this contact                                               |
| `optedIn`                | boolean | Marketing opt-in status (see [Opt-in / opt-out status](#opt-in-opt-out-status))           |
| `isBlocked`              | boolean | Whether the contact is blocked                                                            |
| `businessEmployees`      | array   | Assigned agents as `{ id, name, email }`; empty when unassigned                           |
| `assignedChatbotId`      | string  | Chatbot pinned to this contact, or `null`                                                 |
| `masterClientId`         | string  | Unified profile the contact is linked to, or `null`                                       |
| `sessionClearedAt`       | string  | When the bot session was last cleared, or `null`                                          |
| `conversationExpire`     | string  | ISO 8601 timestamp when 24-hour window expires                                            |
| `latestMessageTimestamp` | string  | Timestamp of most recent message; `null` for a contact that has never exchanged a message |
| `latestMessage`          | object  | Summary of the most recent message: `{ text, type, timestamp, historyText }`, or `null`   |
| `createdAt`              | string  | When the contact was created                                                              |
| `updatedAt`              | string  | When the contact was last changed                                                         |

---

## Errors

Errors use the shared envelope `{ "errorType", "errorMessage", "errorsValidation", "errorRaw" }`.

| Status | When                                                                                                                                                                                                                                                                 |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | Body or query validation failed (`errorMessage` names the field); one or more contacts failed in `POST /v1/clients`; every entry failed in `PUT /v1/clients/attributes-and-tags`; unknown agent email; no active agent for auto-assignment; attribute rules violated |
| 403    | API key lacks `clients:read` / `clients:write`, or is not a Full access / Read-only key for `/v1/business/attributes`                                                                                                                                                |
| 404    | Contact not found (`"Client Details not found with 919876543210"`)                                                                                                                                                                                                   |
| 409    | `POST /v1/business/attributes` with a `fieldKey` that already exists, or with `tags`                                                                                                                                                                                 |

---

## WhatsApp contact book

:::api
method: DELETE
endpoint: /v1/clients/:clientWaNumber/contact-book
title: Delete Contact Book Entry
description: Remove a contact from WhatsApp's contact book so their phone number stops being included in webhooks.

## Path Parameters

- clientWaNumber: string [required] - The contact's WhatsApp user ID, for example `BD.1068713429041673`

WhatsApp keeps a contact book for your business so that a contact who hides
their phone number behind a username can still be recognised. Deleting an entry
stops their phone number from being included in webhooks for every business
phone number in your portfolio, until a new interaction records it again.

```response
{
  "success": true,
  "message": "Contact book entry deleted",
  "data": { "messaging_product": "whatsapp", "success": true, "deleted": true }
}
```

:::

Returns `400` when the path value is a phone number or a parent user ID rather than a contact's standard WhatsApp user ID.

### Delete Contact Book Entry Example

```bash
curl -X DELETE "{{API_URL}}/v1/clients/BD.1068713429041673/contact-book" \
  -H "Authorization: Bearer YOUR_API_KEY"
```
