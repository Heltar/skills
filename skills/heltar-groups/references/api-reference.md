---
title: Groups
description: Create and list WhatsApp groups
icon: Users
order: 5
---

# Groups API

Use the Groups API to create WhatsApp groups from your connected business number and fetch active groups directly from Meta.

`POST /v1/groups` creates the group on Meta and returns the Meta creation result. Local persistence for groups will be handled separately through lifecycle webhooks.

`GET /v1/groups` is Meta-backed and returns the current live group list for the authenticated business phone number ID.

---

## Authentication

All groups endpoints require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

See [Authentication](/docs/api/authentication) for full setup instructions.

---

:::api
method: POST
endpoint: /v1/groups
title: Create Group
description: Create a new WhatsApp group on Meta.

## Body Parameters

- subject: string [required] - Group subject shown in WhatsApp
- description: string - Optional group description
- joinApprovalMode: string - Optional join mode, either `approval_required` or `auto_approve`

```request
{
  "subject": "Order #12345 Coordination",
  "description": "Customer, RM, and service advisor coordination group",
  "joinApprovalMode": "approval_required"
}
```

## Response

```response
{
  "message": "Group creation request accepted by Meta. The group ID will be sent via webhook once the group is created successfully.",
  "data": {
    "messaging_product": "whatsapp",
    "request_id": "A24EA888AE86139F9A1ECFE4463E7186"
  }
}
```

:::

> [!NOTE]
> This endpoint currently forwards Meta's create response inside `data` and returns `202 Accepted`.

### Create Group Example

```bash
curl -X POST "{{API_URL}}/v1/groups" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Order #12345 Coordination",
    "description": "Customer, RM, and service advisor coordination group",
    "joinApprovalMode": "approval_required"
  }'
```

### Create Group Notes

- The group is created on Meta using the business phone number configured in your account.
- This endpoint currently returns `202 Accepted` after Meta accepts the request.
- The raw Meta create payload is returned inside `data`.
- `request_id` confirms that Meta accepted the group creation request.
- The actual `group_id` is delivered later via the `group_lifecycle_update` webhook once the group is created successfully.

---

:::api
method: GET
endpoint: /v1/groups
title: List Groups
description: Fetch the current page of groups associated with the authenticated business phone number ID.

## Query Parameters

- limit: number - Optional page size passed to Meta. Min `1`, max `1024`, default `25`
- after: string - Optional cursor for the next page
- before: string - Optional cursor for the previous page

## Response

```response
{
  "message": "Successfully retrieved group list",
  "data": [
    {
      "id": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI6MTIwMzYzNDA4NDUyMjIwMDY5",
      "creation_timestamp": 1775686897,
      "subject": "Order #12345 Coordination"
    },
    {
      "id": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI6MTIwMzYzNDA3ODQwODcyMDk4",
      "creation_timestamp": 1775684834,
      "subject": "Order #12345 Coordination"
    },
    {
      "id": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI6MTIwMzYzNDI3ODg1OTc2NTQ0",
      "creation_timestamp": 1775684356,
      "subject": "Order #12345 Coordination"
    }
  ],
  "paging": {
    "cursors": {
      "before": "eyJvZAmZAzZAXQiOjAsInZAlcnNpb25JZACI6IjE3NzU2ODc1NTQwODgxMTk2MDcifQZDZD",
      "after": "eyJvZAmZAzZAXQiOjYsInZAlcnNpb25JZACI6IjE3NzU2ODc1NTQwODgxMTk2MDcifQZDZD"
    }
  }
}
```

:::

### List Groups Example

```bash
curl -X GET "{{API_URL}}/v1/groups?limit=25" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```bash
curl -X GET "{{API_URL}}/v1/groups?limit=25&after=MTAxNTExOTQ1MjAwNzI5NDE=" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### List Response Fields

- `message`: success message for the request
- `data`: the current page returned by Meta
- `data[].id`: group identifier returned by Meta
- `data[].subject`: group subject, if returned by Meta
- `data[].creation_timestamp`: UNIX creation timestamp returned by Meta
- `paging`: pagination object returned by Meta
- `paging.cursors.before`: cursor for the previous page
- `paging.cursors.after`: cursor for the next page

---

:::api
method: GET
endpoint: /v1/groups/:groupId
title: Get Group Info
description: Fetch live group metadata from Meta (subject, description, participants, etc.).

## Path Parameters

- groupId: string [required] - The group identifier returned by `group_lifecycle_update` or `GET /v1/groups`

## Query Parameters

- fields: string - Comma-separated list of fields to fetch. Allowed values: `subject`, `description`, `join_approval_mode`, `participants`, `total_participant_count`, `suspended`, `creation_timestamp`, `admins`. Defaults to a standard subset if omitted. Use `GET /v1/groups/:groupId/invite_link` for the invite link; profile picture metadata is delivered via the `group_settings_update` webhook.

## Response

```response
{
  "message": "Group info retrieved",
  "data": {
    "subject": "Order #12345 Coordination",
    "description": "Customer + RM + advisor coordination",
    "join_approval_mode": "approval_required",
    "total_participant_count": 3,
    "participants": [
      { "wa_id": "919999911111", "role": "admin" },
      { "wa_id": "919999922222" }
    ],
    "suspended": false,
    "creation_timestamp": 1775686897
  }
}
```

:::

### Get Group Info Example

```bash
curl -X GET "{{API_URL}}/v1/groups/Y2FwaV9ncm91cDo.../?fields=subject,participants,total_participant_count" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: POST
endpoint: /v1/groups/:groupId
title: Update Group Settings
description: Update the group subject, description, and/or profile picture on Meta. Accepts JSON for text-only updates and `multipart/form-data` when a profile picture file is included.

## Path Parameters

- groupId: string [required] - The group identifier

## Body Parameters

At least one of `subject`, `description`, or `file` is required.

- subject: string - New group subject (1-128 chars)
- description: string - New group description (max 2048 chars)
- file: binary [multipart only] - JPEG image for the group profile picture. Per Meta's requirements: `image/jpeg` only, max 5MB, square (height = width), minimum 192×192. Send as `multipart/form-data` with field name `file` (the API forwards it to Meta as `profile_picture_file`, which is the field name Meta's parser actually accepts despite their curl example showing `file`).

### JSON request (subject / description only)

```request
{
  "subject": "Order #12345 – Updated Subject",
  "description": "Customer + RM + advisor coordination"
}
```

### Multipart request (with profile picture)

```bash
curl -X POST "{{API_URL}}/v1/groups/Y2FwaV9ncm91cDo..." \
  -H "Authorization: Bearer <JWT>" \
  -F "subject=Order #12345 – Updated Subject" \
  -F "file=@/path/to/group_pic.jpg;type=image/jpeg"
```

## Response

```response
{
  "message": "Group settings update requested",
  "data": {
    "messaging_product": "whatsapp",
    "request_id": "B35FB999BF97240A0B2FDFF5574F8297"
  }
}
```

:::

Requires `contactsManagement` permission. Profile-picture metadata (`sha256`, `mime_type`) lands on the local group row asynchronously via the `group_settings_update` webhook — the response above only confirms that Meta accepted the upload.

---

:::api
method: DELETE
endpoint: /v1/groups/:groupId
title: Delete Group
description: Delete a WhatsApp group on Meta.

## Path Parameters

- groupId: string [required] - The group identifier

## Response

```response
{
  "message": "Group deletion requested",
  "data": { "success": true }
}
```

:::

Requires `contactsManagement` permission.

---

:::api
method: GET
endpoint: /v1/groups/:groupId/invite_link
title: Get Group Invite Link
description: Fetch the current invite link for a group.

## Path Parameters

- groupId: string [required] - The group identifier

## Response

```response
{
  "message": "Invite link retrieved",
  "data": {
    "messaging_product": "whatsapp",
    "invite_link": "https://chat.whatsapp.com/LINK_ID"
  }
}
```

:::

---

:::api
method: POST
endpoint: /v1/groups/:groupId/invite_link
title: Reset Group Invite Link
description: Revoke the current invite link and generate a new one.

## Path Parameters

- groupId: string [required] - The group identifier

## Response

```response
{
  "message": "Invite link reset",
  "data": {
    "messaging_product": "whatsapp",
    "invite_link": "https://chat.whatsapp.com/NEW_LINK_ID"
  }
}
```

:::

Requires `contactsManagement` permission. The old link stops working immediately.

---

:::api
method: DELETE
endpoint: /v1/groups/:groupId/participants
title: Remove Participants
description: Remove one or more members from the group.

## Path Parameters

- groupId: string [required] - The group identifier

## Body Parameters

- participants: array [required] - Members to remove. Min 1, max 8 per request. Each entry has a `user` field (phone number or `wa_id`).

```request
{
  "participants": [
    { "user": "919999922222" },
    { "user": "919999933333" }
  ]
}
```

## Response

```response
{
  "message": "Participant removal requested",
  "data": {
    "removed_participants": [{ "wa_id": "919999922222" }],
    "failed_participants": []
  }
}
```

:::

> [!NOTE]
> Meta may partially succeed — check `removed_participants[]` vs `failed_participants[]` in the response. The matching `group_participants_update` webhook (`type: "group_participants_remove"`) carries the final roster state.

Requires `contactsManagement` permission.

---

:::api
method: GET
endpoint: /v1/groups/:groupId/join_requests
title: List Join Requests
description: List pending join requests for a group with `approval_required` mode.

## Path Parameters

- groupId: string [required] - The group identifier

## Response

```response
{
  "message": "Join requests retrieved",
  "data": {
    "data": [
      { "join_request_id": "req-1", "wa_id": "919999933333", "created_at": "2026-04-20T10:00:00Z" },
      { "join_request_id": "req-2", "wa_id": "919999944444", "created_at": "2026-04-20T11:00:00Z" }
    ]
  }
}
```

:::

---

:::api
method: POST
endpoint: /v1/groups/:groupId/join_requests
title: Approve Join Requests
description: Approve one or more pending join requests in bulk.

## Path Parameters

- groupId: string [required] - The group identifier

## Body Parameters

- joinRequests: array [required] - List of `join_request_id` values to approve. Min 1.

```request
{
  "joinRequests": ["req-1", "req-2"]
}
```

## Response

```response
{
  "message": "Join requests approved",
  "data": {
    "approved_join_requests": ["req-1", "req-2"]
  }
}
```

:::

Requires `contactsManagement` permission.

---

:::api
method: DELETE
endpoint: /v1/groups/:groupId/join_requests
title: Reject Join Requests
description: Reject one or more pending join requests in bulk.

## Path Parameters

- groupId: string [required] - The group identifier

## Body Parameters

- joinRequests: array [required] - List of `join_request_id` values to reject. Min 1.

```request
{
  "joinRequests": ["req-3"]
}
```

## Response

```response
{
  "message": "Join requests rejected",
  "data": {
    "rejected_join_requests": ["req-3"]
  }
}
```

:::

Requires `contactsManagement` permission.

---

:::api
method: POST
endpoint: /v1/groups/:groupId/pin
title: Pin or Unpin Message
description: Pin or unpin a message in the group. Max 3 pinned messages per group.

## Path Parameters

- groupId: string [required] - The group identifier

## Body Parameters

- messageId: string [required] - The wamid of the message to pin/unpin
- action: string [required] - `pin` or `unpin`
- expirationDays: number - Required when `action=pin`. Valid range 1-30 days.

```request
{
  "messageId": "wamid.HBgMOTE5OTk5OTExMTExFQIAERgSQzU...",
  "action": "pin",
  "expirationDays": 7
}
```

## Response

```response
{
  "message": "Message pinned",
  "data": { "success": true }
}
```

:::

Requires `contactsManagement` permission. Pinning a 4th message evicts the oldest pin automatically.

---

## Notes

- `POST /v1/groups` currently creates only on Meta.
- `GET /v1/groups` fetches active groups directly from Meta, not from the local database.
- A newly created group should usually appear in Meta quickly, and list results follow Meta as the source of truth.

---

## Messaging in Groups

Groups use the same `POST /v1/messages/send` endpoint as 1:1 chats. Pass the group ID in the existing `clientWaNumber` field — no separate endpoint, no client migration. Group IDs (base64 strings) are automatically distinguished from phone numbers, and the message is delivered to the group.

### Send a text message to a group

```bash
curl -X POST "{{API_URL}}/v1/messages/send" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "clientWaNumber": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI6MTIwMzYzNDA4NDUyMjIwMDY5",
    "type": "text",
    "message": "Welcome to the group!"
  }'
```

### Supported message types in groups

| Type                       | Groups |
| -------------------------- | :----: |
| text                       |   ✅   |
| image/video/audio/document |   ✅   |
| text template              |   ✅   |
| media template             |   ✅   |
| interactive                |   ❌   |
| authentication template    |   ❌   |
| location / contacts        |   ❌   |
| commerce                   |   ❌   |
| view-once / disappearing   |   ❌   |
| calling (voice)            |   ❌   |

Meta rejects unsupported types with a 400.

### Group-specific constraints (from Meta)

- Maximum **8 participants** per group.
- Maximum **10,000 groups** per business phone number.
- Only **one** Cloud API business can be in a given group.
- Templates used in groups should be **dedicated group templates** — performance metrics are not collected for group-used templates.
- Requires an **Official Business Account (OBA)**. Not available on Coexistence or Multi-solution Conversations.

---

## Webhooks

Meta's Groups API emits **six** distinct webhook `field` values. The existing `messages` field still carries chat messages (now with a `group_id` field on the message payload — see below); four new fields carry group lifecycle + participant + settings + policy events; the `group_status_update` policy events and the per-message `statuses` field are separate.

Subscribe in your Meta App → WhatsApp → Configuration:

- `messages` (chat + status — you likely already subscribe to this)
- `group_lifecycle_update`
- `group_participants_update`
- `group_settings_update`
- `group_status_update`

Each event is routed by `entry[].changes[].field`.

### Incoming group message

When a participant posts in a group the business is part of, Meta delivers the standard `messages` webhook with a new `group_id` field alongside `from`:

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "15550001234",
              "phone_number_id": "106540352242922"
            },
            "contacts": [
              {
                "profile": { "name": "Alice" },
                "wa_id": "919999911111"
              }
            ],
            "messages": [
              {
                "from": "919999911111",
                "group_id": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI6MTIwMzYzNDA4NDUyMjIwMDY5",
                "id": "wamid...",
                "timestamp": "1745240000",
                "text": { "body": "Hello team!" },
                "type": "text"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

The group appears as a single conversation in your Inbox, and each message preserves the individual sender's identity (`from` + profile name) for per-member attribution. Chatbot auto-replies are disabled in group chats.

### Message status webhook

Status updates for group messages carry the group ID, a `recipient_type: "group"` discriminator, and **`recipient_participant_id`** identifying which member read/delivered:

```json
{
  "statuses": [
    {
      "id": "wamid...",
      "recipient_id": "Y2FwaV9ncm91cDo...",
      "recipient_type": "group",
      "recipient_participant_id": "919999911111",
      "status": "read",
      "timestamp": "1745240001",
      "conversation": { "id": "conv-1", "origin": { "type": "group_service" } }
    }
  ]
}
```

Meta aggregates statuses — one webhook can carry multiple `statuses[]` entries (many members read the same message, or one member read many messages). Aggregate on your side by `id` (message wamid) + `recipient_participant_id` to build per-member receipts.

### `group_lifecycle_update` — group created / deleted

Meta finishes creating the group asynchronously after your `POST /v1/groups` call and delivers the final `group_id` (with invite link and subject) via this webhook. The group appears in your Inbox automatically on this event — no manual hydration step required.

```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "changes": [{
      "value": {
        "messaging_product": "whatsapp",
        "metadata": { ... },
        "groups": [{
          "timestamp": "1745250000",
          "group_id": "Y2FwaV9ncm91cDo...",
          "type": "group_create",
          "request_id": "A24EA888AE86139F9A1ECFE4463E7186",
          "subject": "Order #12345 Coordination",
          "invite_link": "https://chat.whatsapp.com/LINK_ID",
          "join_approval_mode": "approval_required"
        }]
      },
      "field": "group_lifecycle_update"
    }]
  }]
}
```

**`type` values:**

- `group_create` — async completion of your `POST /v1/groups` call (carries the original `request_id`, the final `group_id`, invite link, and join approval mode).
- `group_delete` — group removed on WhatsApp. Existing message history on your side is retained.

Failures carry an `errors[]` array.

---

### `group_participants_update` — members / join requests

Tracks participant roster changes and join-request lifecycle.

```json
{
  "value": {
    "groups": [
      {
        "timestamp": "1745250100",
        "group_id": "Y2FwaV9ncm91cDo...",
        "type": "group_participants_add",
        "reason": "invite_link",
        "added_participants": [
          { "wa_id": "919999911111" },
          { "wa_id": "919999922222" }
        ]
      }
    ]
  },
  "field": "group_participants_update"
}
```

**`type` values:**

- `group_participants_add` — new members joined. Re-adds are idempotent.
- `group_participants_remove` — business-initiated or self-leave (check `initiated_by: "business" | "participant"`). Identifier comes from `wa_id` or `input`.
- `group_join_request_created` — a user is requesting to join (groups with `approval_required` mode). Carries `join_request_id` + `wa_id`.
- `group_join_request_revoked` — a previously pending join request was withdrawn.

Partial failures on remove carry `failed_participants[]` alongside `removed_participants[]`.

---

### `group_settings_update` — subject / description / picture

Each sub-update carries its own `update_successful` boolean so partial failures are handled cleanly. Only successful updates are applied to the row.

```json
{
  "value": {
    "groups": [
      {
        "timestamp": "1745250200",
        "group_id": "Y2FwaV9ncm91cDo...",
        "type": "group_settings_update",
        "request_id": "B35FB999BF97240A0B2FDFF5574F8297",
        "group_subject": {
          "text": "Order #12345 Updated Subject",
          "update_successful": true
        },
        "group_description": {
          "text": "Customer + RM + advisor coordination",
          "update_successful": true
        },
        "profile_picture": {
          "mime_type": "image/jpeg",
          "sha256": "PHOTO_HASH",
          "update_successful": true
        }
      }
    ]
  },
  "field": "group_settings_update"
}
```

Only sub-updates with `update_successful: true` are applied. Failures carry an `errors[]` array.

---

### `group_status_update` — policy enforcement (suspend)

Fires when Meta suspends or un-suspends a group for policy violations.

```json
{
  "value": {
    "groups": [
      {
        "timestamp": "1745250300",
        "type": "group_suspend",
        "group_id": "Y2FwaV9ncm91cDo..."
      }
    ]
  },
  "field": "group_status_update"
}
```

**`type` values:**

- `group_suspend` — Meta suspended the group for a policy violation. It is hidden from the chat list while suspended.
- `group_suspend_cleared` — suspension lifted; the group reappears.

---
