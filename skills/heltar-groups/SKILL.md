---
name: heltar-groups
description: 'Create, list, update, and manage WhatsApp groups on Heltar — including participant management, join requests, invite links, pinning messages, and group lifecycle webhooks. Use when working with WhatsApp groups via Cloud API.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Messaging
  tags: groups, whatsapp-groups, participants, join-requests, invite-link, pin, group-webhooks, cloud-api
  uses:
    - heltar-authentication
    - heltar-webhooks
---

# Heltar Groups

## Overview

Wraps Meta's WhatsApp Cloud API Groups surface. `POST /v1/groups` creates a group on Meta and returns a `request_id`; the actual `group_id` arrives **asynchronously** via the `group_lifecycle_update` webhook. `GET /v1/groups` is Meta-backed (live, not local DB).

## Agent Instructions

Surface the async creation flow up front — users often expect `group_id` in the create response, but it doesn't arrive there.

1. **`POST /v1/groups`** returns `202 Accepted` + a `request_id`. Store it.
2. **Subscribe to `group_lifecycle_update`** in Meta App config (see [`heltar-webhooks`](../heltar-webhooks/SKILL.md)).
3. The webhook for that `request_id` carries the final `group_id` + `invite_link` + `subject`.
4. From there, all other endpoints (`GET /v1/groups/:groupId`, `POST /v1/groups/:groupId`, etc.) work normally.

## Authentication

Bearer API key. Several endpoints (settings update, delete, invite-link reset, participant remove, join-request approve/reject, pin) require the `contactsManagement` permission — surface this if a 403 hits.

## Endpoints

| Method | Path                                | Purpose                                      |
| ------ | ----------------------------------- | -------------------------------------------- |
| POST   | `/v1/groups`                        | Create (async, returns `request_id`)         |
| GET    | `/v1/groups`                        | List live groups (Meta-backed, paginated)    |
| GET    | `/v1/groups/:groupId`               | Group metadata (subject, participants, etc.) |
| POST   | `/v1/groups/:groupId`               | Update subject / description / picture       |
| DELETE | `/v1/groups/:groupId`               | Delete on Meta                               |
| GET    | `/v1/groups/:groupId/invite_link`   | Fetch current invite link                    |
| POST   | `/v1/groups/:groupId/invite_link`   | Reset (revoke + new)                         |
| DELETE | `/v1/groups/:groupId/participants`  | Remove ≤8 members                            |
| GET    | `/v1/groups/:groupId/join_requests` | List pending                                 |
| POST   | `/v1/groups/:groupId/join_requests` | Approve in bulk                              |
| DELETE | `/v1/groups/:groupId/join_requests` | Reject in bulk                               |
| POST   | `/v1/groups/:groupId/pin`           | Pin / unpin a message (max 3 pins)           |

## Quick Start — create a group

```bash
curl -X POST "$API_URL/v1/groups" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Order #12345 Coordination",
    "description": "Customer + RM + advisor",
    "joinApprovalMode": "approval_required"
  }'
```

`joinApprovalMode` ∈ `approval_required` / `auto_approve`. The 202 response carries `data.request_id`. Wait for the `group_lifecycle_update` webhook to receive the actual `group_id`.

## List groups (Meta-backed)

```
GET /v1/groups?limit=25&after=<cursor>
```

`limit` 1–1024, default 25. Response carries `paging.cursors.before` / `after` for navigation. Newly-created groups should appear within seconds.

## Update settings

JSON for text-only updates:

```jsonc
POST /v1/groups/:groupId
{ "subject": "New Subject", "description": "New desc" }
```

Multipart when adding a profile picture (max 5 MB JPEG, square ≥192×192):

```bash
curl -X POST "$API_URL/v1/groups/<groupId>" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -F "subject=Updated Subject" \
  -F "file=@./pic.jpg;type=image/jpeg"
```

The 202 response only confirms Meta accepted the request — the picture metadata (`sha256`, `mime_type`) lands later via `group_settings_update` webhook.

## Send messages to a group

Groups use the **same** `POST /v1/messages/send` endpoint as 1:1 chats. Pass the group ID (a base64-style string) in the existing `clientWaNumber` field — the backend distinguishes group IDs from phone numbers automatically.

```bash
curl -X POST "$API_URL/v1/messages/send" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "clientWaNumber": "Y2FwaV9ncm91cDo5MTkyMTE3MTY5MDI...",
      "messageType": "text",
      "message": "Welcome to the group!"
    }]
  }'
```

### Supported in groups

| Type                                                                                            | Groups |
| ----------------------------------------------------------------------------------------------- | :----: |
| text                                                                                            |   ✅   |
| image / video / audio / document                                                                |   ✅   |
| text + media template                                                                           |   ✅   |
| interactive / authentication template / location / contacts / commerce / view-once / voice call |   ❌   |

## Meta constraints (worth surfacing to users)

- Max **8 participants** per group.
- Max **10,000 groups** per business phone number.
- Only **one** Cloud API business per group.
- Requires **Official Business Account (OBA)** — not available on Coexistence / Multi-solution Conversations.
- Performance metrics are **not** collected for templates used in groups; use dedicated group templates.

## Group webhooks

Meta describes **six** webhook `field` values for groups; five are subscribable, the sixth is the existing `messages` field which now also carries group-message statuses. Subscribe to all five in your Meta App → WhatsApp → Configuration:

| Field                       | Carries                                                                 |
| --------------------------- | ----------------------------------------------------------------------- |
| `messages`                  | Chat + status — group messages tagged with `group_id`                   |
| `group_lifecycle_update`    | `group_create` (carries `request_id`) / `group_delete`                  |
| `group_participants_update` | adds, removes, join requests                                            |
| `group_settings_update`     | subject / description / picture changes (per-field `update_successful`) |
| `group_status_update`       | `group_suspend` / `group_suspend_cleared` (Meta policy)                 |

Status webhooks for group messages carry `recipient_type: "group"` and **`recipient_participant_id`** identifying which member delivered/read. Aggregate by `(wamid, recipient_participant_id)` for per-member receipts.

## Common gotchas

- Calling `GET /v1/groups/:groupId` immediately after `POST /v1/groups` → 404. The group doesn't exist on Meta yet; wait for `group_lifecycle_update`.
- Multipart picture upload: the field name is **`file`** in the request to Heltar, but Meta's docs say `profile_picture_file`. Heltar handles the rename — just send `file`.
- Removing >8 participants in one call → 400. Batch into chunks of 8.
- Pinning a 4th message silently evicts the oldest pin.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
