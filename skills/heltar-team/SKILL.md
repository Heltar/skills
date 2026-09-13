---
name: heltar-team
description: 'List the team members of a Heltar organisation, invite new ones with a role and business access, change roles, remove and restore members, resend invitations, switch members in or out of rotation, configure automatic chat assignment, set per-member quick replies, and read or tune the permissions behind each role. Use when building an agent roster for chat routing, provisioning or off-boarding team members, syncing roles from an identity system, or automating shift-based availability.'
metadata:
  author: Heltar
  version: 0.1.0
  category: Account
  tags: team, employees, agents, roles, permissions, invite, business-access, chat-assignment, quick-replies
  uses:
    - heltar-authentication
---

# Heltar Team

## Overview

Team members (called _business employees_ in the API) belong to your **organisation**, not to a single WhatsApp number. One login email has one membership per organisation; the membership carries a display name, a `status` (`invited` until the invitation is accepted, then `active`), an on/off `isActive` flag used by chat rotation, the list of businesses the member may open (`accessibleBusinessIds`), and exactly one **role**. A role is a named set of on/off permissions; every organisation starts with `OWNER`, `MANAGER` and `OPERATOR`.

The list endpoint is the one most integrations need: its emails are the identifiers you pass to `POST /v1/clients/chat/assign` ([`heltar-contacts`](../heltar-contacts/SKILL.md)) to route a conversation to a person.

## Agent Instructions

Match user intent:

| User intent                                                              | Endpoint                                                                                                                                                     |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| List every member (email, role, status, business access, settings)       | `GET /v1/auth/business-employees`                                                                                                                            |
| Also see removed members (`deletedAt` set)                               | `GET /v1/auth/business-employees?includeDeleted=true`                                                                                                        |
| Invite a new member with a role (+ optional business access)             | `POST /v1/auth/business-employees` (requires `employeeManagement`)                                                                                           |
| Re-send an invitation that has not been accepted                         | `POST /v1/auth/business-employees/:emailId/resend-invite` (requires `employeeManagement`; no body)                                                           |
| Change a member's role                                                   | `PUT /v1/auth/business-employees/:emailId` with `{ "role" }` (requires `employeeManagement`)                                                                 |
| Remove a member / cancel a pending invitation                            | `DELETE /v1/auth/business-employees/:emailId` (requires `employeeManagement`)                                                                                |
| Restore a removed member                                                 | `PUT /v1/auth/business-employees/:emailId/restore` — **Dashboard session only**, `OWNER` role                                                                |
| Take a member out of / back into rotation (end of shift, leave)          | `PUT /v1/auth/business-employees/toggle-status` with `{ "email", "isActive" }`                                                                               |
| Read the signed-in member's own record with full permissions             | `GET /v1/auth/business-employees/:emailId` — **Dashboard session only** (self only)                                                                          |
| Change the signed-in member's own notification preferences               | `PUT /v1/auth/business-employees/me` — **Dashboard session only**                                                                                            |
| Grant or revoke one business for a member                                | `PUT /v1/auth/business-employees/:emailId/businesses/:bizId/access` with `{ "hasAccess" }` — **Dashboard session only**, `OWNER` role                        |
| Replace a member's whole business list (select all / clear all)          | `PUT /v1/auth/business-employees/:emailId/businesses/access` with `{ "businessIds" }` — **Dashboard session only**, `OWNER` role                             |
| Turn automatic chat assignment on / off and choose how agents are picked | `PUT /v1/auth/business-employees/auto-chat-assign` with `{ "isAutomaticChatAssignment", "method" }` (requires `automaticChatAssignment`)                     |
| Set (replace) a member's quick replies                                   | `PUT /v1/auth/business-employees/quick-replies` with `{ "email", "quickReplies" }` (requires `quickReplyManagement`)                                         |
| List roles with their full permission sets                               | `GET /v1/role-permission`                                                                                                                                    |
| Change permissions on one or more existing roles                         | `POST /v1/role-permission` (JSON **array** body; requires `permissionManagement`)                                                                            |
| Assign a chat to a member by email / auto-assign / multi-assign          | `POST /v1/clients/chat/assign`, `POST /v1/clients/chat/multiassign`, `assignTo` on `POST /v1/clients` — see [`heltar-contacts`](../heltar-contacts/SKILL.md) |
| Find the business IDs to put in an access list                           | `GET /v1/business` (`data.id`) or `GET /v1/business/account-status?scope=org` — see [`heltar-business`](../heltar-business/SKILL.md)                         |

> **Dashboard session only** means the endpoint needs a signed-in team member: it either acts on "you" (own record, own settings) or is reserved for the `OWNER` role (restore, business access). An API key has no email and no role, so it always gets `403 You can only fetch your own employee record.`, `401 Authenticated email missing`, `403 Only an OWNER can restore a deleted employee.` or `403 Only an OWNER can manage business access.` **Never propose these five endpoints for a server-side integration.** From an API key, business access can only be set at invite time (`accessibleBusinessIds`), and a removed member can only be brought back by an `OWNER` in the dashboard. Every other endpoint on this page works with a Full access key.

## Authentication

Bearer API key. `/v1/auth/business-employees/*` and `/v1/role-permission` are **outside the per-resource scope picker**: use a key created with the **Full access** preset, or **Read-only** for the `GET` endpoints. A key without the right preset gets `403 API key does not have the required scope (auth:write)` (or `auth:read`, `role-permission:read`, `role-permission:write`). See [`heltar-authentication`](../heltar-authentication/SKILL.md).

Two layers apply: the key's preset decides whether the request is accepted at all; on top of that, when the caller is a signed-in team member (the dashboard), their own role must grant the permission named next to each endpoint above (`employeeManagement`, `automaticChatAssignment`, `quickReplyManagement`, `permissionManagement`), otherwise `403 You do not have permission to access ... feature.` Listing members, toggling `isActive`, and reading roles need no role permission.

## Quick Start — list team members

```bash
curl -X GET "$API_URL/v1/auth/business-employees" \
  -H "Authorization: Bearer $HELTAR_API_KEY"
```

`data` is an array of member records, most recently changed first. To build the set of emails you can hand to `POST /v1/clients/chat/assign`, keep the members with `status === "active"` and `isActive === true`. Passwords and two-factor secrets are never included.

## Quick Start — invite a member with a role

```bash
curl -X POST "$API_URL/v1/auth/business-employees" \
  -H "Authorization: Bearer $HELTAR_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Origin: https://app.example.com" \
  -d '{
    "name": "Rahul Verma",
    "email": "agent@example.com",
    "countryCode": 91,
    "contact": "919876500000",
    "role": "OPERATOR",
    "accessibleBusinessIds": [12345]
  }'
```

`name`, `email`, `countryCode`, `contact` and `role` are required; `role` must be an existing role name (404 `This role name SUPPORT not found!` otherwise). `accessibleBusinessIds` defaults to every business in the organisation; IDs outside it are ignored. The member appears in the list immediately with `status: "invited"` and an invitation email goes out. `data.inviteLink` is always returned and `data.emailSent` says whether the email was delivered — when it is `false`, share the link yourself. The host in `inviteLink` comes from your `Origin` (or `Referer`) header, so send the dashboard host the member will use.

## Member record

| Field                   | Type    | Meaning                                                                                                                                                            |
| ----------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`                    | number  | Stable across every business of the organisation                                                                                                                   |
| `email`                 | string  | Login email, always lower-case. The identifier every other endpoint uses; URL-encode it in paths (`agent%40example.com`)                                           |
| `status`                | string  | `invited` until the invitation link is opened and a password set, then `active`                                                                                    |
| `isActive`              | boolean | The rotation switch set by `toggle-status`. `false` means auto-assignment skips them; access and role are unchanged                                                |
| `accessibleBusinessIds` | array   | Businesses (WhatsApp numbers) the member may open. A `?business_id=` swap to any other business is refused with `403 You do not have access to this business. ...` |
| `rolePermission`        | object  | `{ id, role }` in the list; the full permission object (same shape as `GET /v1/role-permission`) in the role-change, remove and self endpoints                     |
| `metaData`              | object  | `quickReplies`, `templateEmailNotification`, `webhookFailureEmailNotification`; `null` when nothing has been set                                                   |
| `deletedAt`             | string  | Only present with `includeDeleted=true`: when the member was removed, or `null`                                                                                    |

## Automatic chat assignment

`PUT /v1/auth/business-employees/auto-chat-assign` is per business (visible as `integrations.chatAssignment` in `GET /v1/business`). When on, every incoming WhatsApp message that starts a new conversation, or lands on a conversation nobody is assigned to, is handed to one member. Both body fields are required — `method` even when switching the feature off (it is stored and used the next time you turn it on).

| `method`             | Eligible members                                                                                                                                     |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `forActiveEmployees` | Members whose `isActive` flag is `true`. Recommended: switch people off with `toggle-status` at the end of their shift and they stop receiving chats |
| `roundRobin`         | Every accepted member, regardless of `isActive`                                                                                                      |
| `leastBusy`          | Same as `roundRobin` today; accepted so you can set it now, the pool may be refined in future                                                        |
| `random`             | Same as `roundRobin` today                                                                                                                           |

Selection rotates: among eligible members, the one never auto-assigned a chat goes first, then the one whose last assignment is oldest; each pick stamps that member's last-assigned time. Only members with `status: "active"` who have not been removed are eligible. A chat that already has an assignee is never reassigned by this feature; if nobody is eligible, the chat stays unassigned. Chats created by outbound campaigns or API sends are not auto-assigned until the contact replies.

## Roles and permissions

Every organisation is seeded with three roles — `OWNER`, `MANAGER`, `OPERATOR` — all starting with every permission on except `contactNumberMasking` (off) and `hideCodeEditorAiAgent` (on). Role names are stored with spaces replaced by underscores. No endpoint creates or deletes roles: `GET /v1/role-permission` reads them (oldest first, `businessId` is merely where the role was created; it applies organisation-wide) and `POST /v1/role-permission` changes permissions on the ones that exist — send an **array** of `{ "role", ...permissionKeys }`; keys you omit are unchanged, and the response is the full updated list. Changes reach every member holding the role on their next request.

`OWNER` is special: only an `OWNER` can restore removed members and manage business access, `permissionManagement` cannot be switched off for it (400), and the organisation must always keep at least one active `OWNER`. Two keys are inverted — `contactNumberMasking` and `hideCodeEditorAiAgent` restrict when `true`; every other key grants when `true`. The full key table (inbox, contacts, campaigns, integrations, settings, communication) is in `references/api-reference.md`.

## Key Rules / Gotchas

- **Emails are the identifier.** Pass them lower-case; URL-encode when in the path. A member is a valid assignment target for `POST /v1/clients/chat/assign` / `multiassign` / `assignTo` only if they have accepted the invitation (`status: "active"`) and have not been removed.
- **Invitation link expiry.** Valid for **7 days from the first invitation**; re-sending does not extend it. `resend-invite` sends the same link while it is valid; once expired it issues a fresh 7-day link and the old one stays dead. Re-sending to an already `active` member → 400 `... has already activated their account.`
- **Inviting an email that is still pending** does not duplicate it: name, phone and role are refreshed, business access is replaced, and the invitation goes out again (`Invitation re-sent to ...`). Inviting an active member → 400 `... already exists!`; inviting a removed member → 400 telling you an `OWNER` must restore them instead.
- **Only the role changes** on `PUT /v1/auth/business-employees/:emailId`; name, phone and business access stay. Demoting or removing the sole active `OWNER` → 400. Promote someone else to `OWNER` first.
- **Removal is a soft delete** for active members: they vanish from the list (unless `includeDeleted=true`), their sessions end, their email stays reserved, and their chats **keep the assignment** until you reassign with `POST /v1/clients/chat/assign`. A pending invitation is cancelled outright (link dead immediately) and can be re-invited at once. Only an `OWNER` in the dashboard can restore.
- **`toggle-status`** changes only `isActive`; it is read by `forActiveEmployees` auto-assignment and by `POST /v1/clients/chat/assign` called without an `email` (which fails with `No active employee found to assign chat!` when nobody is on). A `500` means the email is not a member of your organisation.
- **Business access from an API key** is set only via `accessibleBusinessIds` on the invite call (default: every business). The single and bulk `/businesses/.../access` endpoints are `OWNER` + dashboard only; the bulk one drops IDs that are not businesses of your organisation silently, collapses duplicates, and accepts `[]` to remove all access — compare the returned `accessibleBusinessIds` with what you sent. Revoking the last active `OWNER` from a business → 400.
- **A signed-in non-`OWNER` inviter** can only grant businesses they can open themselves; a request that would leave the invitee with none → 400 `You can only grant access to businesses you can access.` An API key has no such cap.
- **Quick replies replace the whole list.** Read `metaData.quickReplies` from the list endpoint, modify, send it all back; `[]` clears. Each entry is a `POST /v1/messages/send` payload without `clientWaNumber` plus a non-empty `shortcut` (`text`, `media`, `template`, `interactive`, `contacts`, `location`; `text`/`media`/`template` reject unknown fields with 400). Unknown email → 404 `Employee Details not found with ...`.
- **`POST /v1/role-permission`** with a role name that does not exist → 400 `Roles not found: SUPPORT, SALES` and **nothing** is changed. Non-boolean permission values or a non-array body → 400.
- **Invite `password`** is accepted for backward compatibility and ignored — the invitee chooses their own. A person who already has a login with another organisation on the platform keeps their password and joins yours with one click.
- The `?business_id=` swap on any API call is refused for members without access to that business; an API key's own business is unaffected.

## Related Skills

- [`heltar-contacts`](../heltar-contacts/SKILL.md) — assign chats to members by email, list chats by `assigned`, `assignTo` on contact upsert.
- [`heltar-business`](../heltar-business/SKILL.md) — business IDs for access lists, `integrations.chatAssignment`, opt-in/opt-out and read-receipt settings governed by the permissions above.
- [`heltar-messaging`](../heltar-messaging/SKILL.md) — the message shapes accepted as quick replies.
- [`heltar-authentication`](../heltar-authentication/SKILL.md) — Full access vs Read-only vs scoped keys.

## References

- Full API spec: [`references/api-reference.md`](./references/api-reference.md)
