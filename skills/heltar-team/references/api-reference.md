---
title: Team
description: Manage team members, their roles, business access and chat assignment
icon: Users
order: 15
---

# Team API

Use the Team API to see who is on your team, invite new team members, change their role, remove or restore them, decide which businesses each member can open, configure how incoming chats are shared out, maintain per-member quick replies, and read or edit the permissions behind each role.

The list endpoint is the one most integrations need: [List Team Members](#list-team-members) returns every member with their email, role and status, and those emails are what you pass to `POST /v1/clients/chat/assign` on the [Contacts](/docs/api/contacts) page to route a conversation to a person.

---

## Authentication

All endpoints on this page require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

See [Authentication](/docs/api/authentication) for full setup instructions.

> [!NOTE]
> The `/v1/auth/business-employees/*` and `/v1/role-permission` endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests). A key without the right preset receives `403 API key does not have the required scope (auth:write)` (or `auth:read`, `role-permission:read`, `role-permission:write`).

> [!IMPORTANT]
> Two layers of access apply on this page. The key's preset (above) decides whether the request is accepted at all. On top of that, when the request comes from a signed-in team member (the dashboard), the caller's own role must grant the permission each endpoint names, for example "requires `employeeManagement`"; otherwise the member receives `403 You do not have permission to access employee management feature. Please contact the account owner if access is required.`
> An API key is not a team member: it carries no email and no role. Endpoints that act on "you" or that are reserved for the `OWNER` role therefore work from the dashboard only and are marked **Dashboard session only** below. Everything else works with a Full access key.

---

## How team membership works

Team members belong to your **organisation**, not to a single WhatsApp number. One login (email) has one membership per organisation, and everything on this page is read and written on that membership:

| Field                   | Type    | Meaning                                                                                                                                                                                                                                     |
| ----------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                    | number  | The member's ID. Stable across every business of the organisation.                                                                                                                                                                          |
| `name`                  | string  | Display name shown in the inbox and in assignment messages.                                                                                                                                                                                 |
| `email`                 | string  | Login email, always lower-case. This is the identifier every other endpoint on this page uses. Pass it lower-case, and URL-encoded when it is part of the path (`agent%40example.com`).                                                     |
| `countryCode`           | number  | Country calling code of the member's phone.                                                                                                                                                                                                 |
| `contact`               | string  | The member's phone number with country code.                                                                                                                                                                                                |
| `status`                | string  | `invited` until the person opens the invitation link and activates their account, then `active`.                                                                                                                                            |
| `isActive`              | boolean | The on/off switch set by [Switch a Member On or Off](#switch-a-member-on-or-off). Off means the member is skipped by automatic chat assignment. It does not remove their access.                                                            |
| `accessibleBusinessIds` | array   | IDs of the businesses (WhatsApp numbers) in the organisation the member may open. Managed under [Business Access](#business-access).                                                                                                        |
| `rolePermission`        | object  | `{ "id", "role" }`: the role assigned to the member. Roles are described under [Roles and Permissions](#roles-and-permissions).                                                                                                             |
| `is2faEnabled`          | boolean | Whether the member has two-factor authentication turned on.                                                                                                                                                                                 |
| `metaData`              | object  | Per-member settings: `quickReplies` (see [Quick Replies](#quick-replies)), `templateEmailNotification` and `webhookFailureEmailNotification` (see [Update Your Own Settings](#update-your-own-settings)). `null` when nothing has been set. |
| `createdAt`             | string  | When the login was created.                                                                                                                                                                                                                 |
| `updatedAt`             | string  | When the membership was last changed.                                                                                                                                                                                                       |
| `deletedAt`             | string  | Only present when you pass `includeDeleted=true` to the list endpoint: when the member was removed from the organisation, or `null`.                                                                                                        |

Removing a member is a **soft delete**: the membership is marked removed, their sessions in your organisation are ended, and an `OWNER` can bring them back later with all history intact. A pending invitation, on the other hand, is cancelled outright.

---

## Team Members

### List Team Members

:::api
method: GET
endpoint: /v1/auth/business-employees
title: List Team Members
description: Return every member of your organisation with their role, status, business access and settings. Most recently changed membership first.

## Query Parameters

- includeDeleted: boolean - Pass `true` to also return members who were removed from the organisation. Every entry then carries a `deletedAt` field (`null` for current members). Default `false`

## Response

```response
{
  "message": "Successfully Fetched List of Business Employees!",
  "data": [
    {
      "id": 4021,
      "name": "Priya Sharma",
      "email": "priya@example.com",
      "countryCode": 91,
      "contact": "919876543210",
      "createdAt": "2025-01-10T08:30:00.000Z",
      "updatedAt": "2026-09-01T12:00:00.000Z",
      "metaData": {
        "templateEmailNotification": true,
        "quickReplies": [
          {
            "shortcut": "hi",
            "messageType": "text",
            "message": "Hello! How can I help you today?"
          }
        ]
      },
      "is2faEnabled": true,
      "isActive": true,
      "status": "active",
      "accessibleBusinessIds": [12345, 12346],
      "rolePermission": { "id": 301, "role": "OWNER" }
    },
    {
      "id": 4022,
      "name": "Rahul Verma",
      "email": "agent@example.com",
      "countryCode": 91,
      "contact": "919876500000",
      "createdAt": "2026-09-08T10:15:00.000Z",
      "updatedAt": "2026-09-08T10:15:00.000Z",
      "metaData": null,
      "is2faEnabled": false,
      "isActive": false,
      "status": "invited",
      "accessibleBusinessIds": [12345],
      "rolePermission": { "id": 303, "role": "OPERATOR" }
    }
  ]
}
```

:::

No role permission is required to list members. The response never includes passwords or two-factor secrets.

#### List Team Members Example

:::code-group

```curl
curl -X GET "{{API_URL}}/v1/auth/business-employees" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```javascript
const response = await fetch('{{API_URL}}/v1/auth/business-employees', {
  headers: { Authorization: 'Bearer YOUR_API_KEY' },
});
const { data: members } = await response.json();

// Emails you can hand to POST /v1/clients/chat/assign
const assignable = members
  .filter(m => m.status === 'active' && m.isActive)
  .map(m => m.email);
```

```python
import requests

response = requests.get(
    "{{API_URL}}/v1/auth/business-employees",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
)
members = response.json()["data"]

# Emails you can hand to POST /v1/clients/chat/assign
assignable = [
    m["email"] for m in members if m["status"] == "active" and m["isActive"]
]
```

:::

To include removed members as well:

```bash
curl -X GET "{{API_URL}}/v1/auth/business-employees?includeDeleted=true" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

### Invite a Team Member

:::api
method: POST
endpoint: /v1/auth/business-employees
title: Invite a Team Member
description: Add a person to your organisation and email them an invitation link. The member appears in the list immediately with status `invited` and becomes `active` when they accept. Requires `employeeManagement`.

## Body Parameters

- name: string [required] - Display name, e.g. `Priya Sharma`
- email: string [required] - Login email. Stored lower-case; must not already be an active member of your organisation
- countryCode: number [required] - Country calling code of the member's phone, e.g. `91`
- contact: string [required] - Phone number with country code, e.g. `919876543210`. `+`, spaces and dashes are stripped
- role: string [required] - Name of an existing role in your organisation, e.g. `OPERATOR`. See [Roles and Permissions](#roles-and-permissions)
- accessibleBusinessIds: array - Business IDs the member may open. Defaults to every business in the organisation. IDs outside your organisation are ignored
- password: string - Accepted for backward compatibility and ignored. The invitee chooses their own password when accepting

```request
{
  "name": "Rahul Verma",
  "email": "agent@example.com",
  "countryCode": 91,
  "contact": "919876500000",
  "role": "OPERATOR",
  "accessibleBusinessIds": [12345]
}
```

## Response

```response
{
  "message": "Invitation sent to agent@example.com. They'll set their own password to activate the account.",
  "data": {
    "email": "agent@example.com",
    "name": "Rahul Verma",
    "role": "OPERATOR",
    "accessibleBusinessIds": [12345],
    "inviteLink": "https://app.example.com/accept-invite/INVITE_TOKEN",
    "emailSent": true
  }
}
```

:::

#### Invite a Team Member Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/auth/business-employees" \
  -H "Authorization: Bearer YOUR_API_KEY" \
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

```javascript
const response = await fetch('{{API_URL}}/v1/auth/business-employees', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
    Origin: 'https://app.example.com',
  },
  body: JSON.stringify({
    name: 'Rahul Verma',
    email: 'agent@example.com',
    countryCode: 91,
    contact: '919876500000',
    role: 'OPERATOR',
    accessibleBusinessIds: [12345],
  }),
});
const { data } = await response.json();

if (!data.emailSent) {
  // Email delivery failed; share data.inviteLink with the person yourself.
}
```

```python
import requests

response = requests.post(
    "{{API_URL}}/v1/auth/business-employees",
    headers={
        "Authorization": "Bearer YOUR_API_KEY",
        "Origin": "https://app.example.com",
    },
    json={
        "name": "Rahul Verma",
        "email": "agent@example.com",
        "countryCode": 91,
        "contact": "919876500000",
        "role": "OPERATOR",
        "accessibleBusinessIds": [12345],
    },
)
data = response.json()["data"]

if not data["emailSent"]:
    # Email delivery failed; share data["inviteLink"] with the person yourself.
    print(data["inviteLink"])
```

:::

#### How the invitation flow works

1. **The member is created immediately** with `status: "invited"`, the role you chose and the business access you granted. They show up in [List Team Members](#list-team-members) right away, but cannot sign in to your organisation yet.
2. **An email with an invitation link is sent** to the address. The link is valid for **7 days from the first invitation**; re-sending it does not extend that.
3. **The person opens the link** and sets a password. That activates the account: `status` becomes `active`, `isActive` becomes `true`, and they can sign in. If the person already has a login with another organisation on the platform, they keep their existing password and simply join yours with one click.
4. **The response always contains the link.** `emailSent` tells you whether the email actually went out. When it is `false` (for example a bounced address), copy `inviteLink` from the response and send it through any channel you like; it is the same link the email would have carried.

> [!TIP]
> The host in `inviteLink` is taken from the `Origin` (or `Referer`) header of your request, falling back to the API host. Send `Origin: https://<your dashboard host>` with the request so the link opens the dashboard the member will use.

Other behaviour worth knowing:

- **Inviting an email that is still pending** does not create a duplicate. The name, phone and role are refreshed, the business access is replaced, and the invitation is sent again. The message reads `Invitation re-sent to agent@example.com.`
- **Default business access** is every business in your organisation. If the caller is a signed-in team member who is not an `OWNER`, the new member's access is additionally capped to the businesses the caller can open; a request that would leave the invitee with no business at all is rejected. An API key has no such cap.
- **Role names** must already exist in your organisation. Roles cannot be created by this endpoint (see [Roles and Permissions](#roles-and-permissions)).

#### Invite Errors

| Status | Message                                                                                                                                                                                      | When                                                                                                                        |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 400    | Validation message from the schema                                                                                                                                                           | A required field is missing, `contact` is not a valid phone number, or an unknown key was sent.                             |
| 400    | `agent@example.com already exists!`                                                                                                                                                          | The email is already an active member of your organisation.                                                                 |
| 400    | `The account for agent@example.com was deleted. Restore it instead of inviting again: open Settings → Employees, find the row marked "Deleted", and press Restore (needs OWNER permission).` | The email belongs to a removed member. Use [Restore a Removed Member](#restore-a-removed-member) instead of inviting again. |
| 400    | `You can only grant access to businesses you can access.`                                                                                                                                    | A non-`OWNER` caller picked businesses they cannot open themselves, leaving the invitee with none.                          |
| 404    | `This role name SUPPORT not found!`                                                                                                                                                          | `role` does not match a role in your organisation.                                                                          |
| 403    | `You do not have permission to access employee management feature. ...`                                                                                                                      | The signed-in caller's role lacks `employeeManagement`.                                                                     |

---

### Get Your Own Record

:::api
method: GET
endpoint: /v1/auth/business-employees/:emailId
title: Get Your Own Record
description: Read the signed-in team member's own record, including their full role. Dashboard session only.

## Path Parameters

- emailId: string [required] - The caller's own email, URL-encoded (`priya%40example.com`). Any other email returns 403

## Response

```response
{
  "message": "Successfully fetched Employee Details!",
  "data": {
    "id": 4021,
    "name": "Priya Sharma",
    "email": "priya@example.com",
    "countryCode": 91,
    "contact": "919876543210",
    "metaData": {
      "templateEmailNotification": true
    },
    "isActive": true,
    "is2faEnabled": true,
    "canViewCost": false,
    "createdAt": "2025-01-10T08:30:00.000Z",
    "updatedAt": "2026-09-01T12:00:00.000Z",
    "status": "active",
    "accessibleBusinessIds": [12345, 12346],
    "deletedAt": null,
    "rolePermission": {
      "id": 301,
      "role": "OWNER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "contactsManagement": true,
      "viewAllContacts": true,
      "exportAllContacts": true,
      "attributeAndTagsManagement": true,
      "createNewCampaign": true,
      "exportCampaignStats": true,
      "addNewApp": true,
      "viewWabaApiDetails": true,
      "manageWabaApiDetails": true,
      "permissionManagement": true,
      "employeeManagement": true,
      "webhookManagement": true,
      "templateManagement": true,
      "wabaProfileManagement": true,
      "viewApiKey": true,
      "createApiKey": true,
      "automaticChatAssignment": true,
      "quickReplyManagement": true,
      "optInOutManagement": true,
      "readReceiptManagement": true,
      "registerMetaAPI": true,
      "registerLinkTracker": true,
      "callRecording": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:00.000Z"
    }
  }
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/auth/business-employees/priya%40example.com" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN"
```

This endpoint is **self-only**: it returns the record of the person making the request, and `emailId` must match their own email (case-insensitive). It is what the dashboard uses to load the signed-in user's permissions. Because an API key has no email, a request made with an API key always receives `403 You can only fetch your own employee record.` To read other members, use [List Team Members](#list-team-members).

`rolePermission` here is the complete role object, the same shape [Get Roles](#get-roles) returns. `canViewCost` says whether per-message cost is shown to this member in the dashboard.

---

### Change a Member's Role

:::api
method: PUT
endpoint: /v1/auth/business-employees/:emailId
title: Change a Member's Role
description: Assign a different role to a team member. Only the role changes; name, phone and business access stay as they are. Requires `employeeManagement`.

## Path Parameters

- emailId: string [required] - Email of the member, URL-encoded

## Body Parameters

- role: string [required] - Name of an existing role in your organisation, e.g. `MANAGER`

```request
{
  "role": "MANAGER"
}
```

## Response

```response
{
  "message": "Successfully updated Employee Details!",
  "data": {
    "id": 4022,
    "name": "Rahul Verma",
    "email": "agent@example.com",
    "countryCode": 91,
    "contact": "919876500000",
    "metaData": null,
    "isActive": true,
    "status": "active",
    "is2faEnabled": false,
    "canViewCost": false,
    "accessibleBusinessIds": [12345],
    "rolePermission": {
      "id": 302,
      "role": "MANAGER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "contactsManagement": true,
      "viewAllContacts": true,
      "exportAllContacts": true,
      "attributeAndTagsManagement": true,
      "createNewCampaign": true,
      "exportCampaignStats": true,
      "addNewApp": true,
      "viewWabaApiDetails": true,
      "manageWabaApiDetails": true,
      "permissionManagement": true,
      "employeeManagement": true,
      "webhookManagement": true,
      "templateManagement": true,
      "wabaProfileManagement": true,
      "viewApiKey": true,
      "createApiKey": true,
      "automaticChatAssignment": true,
      "quickReplyManagement": true,
      "optInOutManagement": true,
      "readReceiptManagement": true,
      "registerMetaAPI": true,
      "registerLinkTracker": true,
      "callRecording": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:10.000Z"
    },
    "createdAt": "2026-09-08T10:15:00.000Z",
    "updatedAt": "2026-09-08T10:15:00.000Z"
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/agent%40example.com" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "role": "MANAGER" }'
```

`data` is the member record with the updated role as a full role object (shortened above; the same shape as [Get Roles](#get-roles)). The new role takes effect on the member's next request. A change to your own role is picked up by the dashboard on its next token refresh.

| Status | Message                                                                                                                                                                                      | When                                                                                                    |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 400    | `Employee with email agent@example.com does not exist.`                                                                                                                                      | The email is not a member of your organisation.                                                         |
| 400    | `The account for agent@example.com was deleted. Restore it instead of inviting again: open Settings → Employees, find the row marked "Deleted", and press Restore (needs OWNER permission).` | The email belongs to a removed member. An `OWNER` must [restore](#restore-a-removed-member) them first. |
| 400    | `The account with the email priya@example.com cannot have its role changed because it is the sole account assigned the 'OWNER' role.`                                                        | You tried to demote the only active `OWNER`. Promote someone else to `OWNER` first.                     |
| 404    | `This role name SUPPORT not found!`                                                                                                                                                          | `role` does not match a role in your organisation.                                                      |
| 403    | `You do not have permission to access employee management feature. ...`                                                                                                                      | The signed-in caller's role lacks `employeeManagement`.                                                 |

---

### Remove a Team Member

:::api
method: DELETE
endpoint: /v1/auth/business-employees/:emailId
title: Remove a Team Member
description: Remove a member from your organisation. An active member is soft-deleted and can be restored by an OWNER; a pending invitation is cancelled outright. Requires `employeeManagement`.

## Path Parameters

- emailId: string [required] - Email of the member, URL-encoded

## Response

```response
{
  "message": "Successfully removed Business Employee with emailId = agent@example.com",
  "data": {
    "id": 4022,
    "name": "Rahul Verma",
    "email": "agent@example.com",
    "countryCode": 91,
    "contact": "919876500000",
    "metaData": null,
    "isActive": true,
    "status": "active",
    "is2faEnabled": false,
    "canViewCost": false,
    "accessibleBusinessIds": [12345],
    "rolePermission": { "id": 303, "role": "OPERATOR" },
    "createdAt": "2026-09-08T10:15:00.000Z",
    "updatedAt": "2026-09-08T10:15:00.000Z",
    "deletedAt": null
  }
}
```

:::

```bash
curl -X DELETE "{{API_URL}}/v1/auth/business-employees/agent%40example.com" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

What happens depends on the member's status:

- **Active member (`status: "active"`).** The membership is soft-deleted: the member disappears from the list (unless you pass `includeDeleted=true`), every dashboard session they had in your organisation is ended, and their email stays reserved. Nothing else is touched. Chats that were assigned to them keep the assignment until you reassign them with `POST /v1/clients/chat/assign`, so their name may still appear on those chats. If the person also belongs to another organisation, that membership is unaffected. An `OWNER` can undo the removal with [Restore a Removed Member](#restore-a-removed-member).
- **Pending invitation (`status: "invited"`).** The invitation is cancelled and the emailed link stops working immediately. The message reads `Cancelled the pending invitation for agent@example.com`. The same email can be invited again right away.

`data` is the member record as it was before removal. `rolePermission` in this response is the full role object (shortened above).

| Status | Message                                                                                                                                                                                      | When                                                                                                    |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 400    | `Employee with email agent@example.com does not exist.`                                                                                                                                      | The email is not a member of your organisation.                                                         |
| 400    | `The account for agent@example.com was deleted. Restore it instead of inviting again: open Settings → Employees, find the row marked "Deleted", and press Restore (needs OWNER permission).` | The email belongs to a removed member. An `OWNER` must [restore](#restore-a-removed-member) them first. |
| 400    | `The account for priya@example.com cannot be deleted as it is the only account with the 'OWNER' role.`                                                                                       | You tried to remove the only active `OWNER`.                                                            |
| 403    | `You do not have permission to access employee management feature. ...`                                                                                                                      | The signed-in caller's role lacks `employeeManagement`.                                                 |

---

### Restore a Removed Member

:::api
method: PUT
endpoint: /v1/auth/business-employees/:emailId/restore
title: Restore a Removed Member
description: Bring back a soft-deleted member with their role, business access, chat assignments and history intact. OWNER role only; dashboard session only. No request body.

## Path Parameters

- emailId: string [required] - Email of the removed member, URL-encoded

## Response

```response
{
  "message": "Successfully restored Business Employee with emailId = agent@example.com",
  "data": {
    "id": 4022,
    "name": "Rahul Verma",
    "email": "agent@example.com",
    "countryCode": 91,
    "contact": "919876500000",
    "metaData": null,
    "isActive": true,
    "status": "active",
    "is2faEnabled": false,
    "canViewCost": false,
    "accessibleBusinessIds": [12345],
    "rolePermission": { "id": 303, "role": "OPERATOR" },
    "createdAt": "2026-09-08T10:15:00.000Z",
    "updatedAt": "2026-09-09T09:00:00.000Z",
    "deletedAt": null
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/agent%40example.com/restore" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN"
```

Find removable candidates with `GET /v1/auth/business-employees?includeDeleted=true` and look for a non-null `deletedAt`. After restoring, the member can sign in again with their old password.

Only a signed-in member with the `OWNER` role can call this. An API key, or a member with any other role, receives `403 Only an OWNER can restore a deleted employee.` A `400 No deleted employee with email agent@example.com found.` means the email is not a removed member of your organisation.

---

### Resend an Invitation

:::api
method: POST
endpoint: /v1/auth/business-employees/:emailId/resend-invite
title: Resend an Invitation
description: Email the invitation link again to a member who has not accepted yet. Requires `employeeManagement`. No request body.

## Path Parameters

- emailId: string [required] - Email of the invited member, URL-encoded

## Response

```response
{
  "message": "Invitation re-sent to agent@example.com.",
  "data": {
    "inviteLink": "https://app.example.com/accept-invite/INVITE_TOKEN",
    "emailSent": true
  }
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/auth/business-employees/agent%40example.com/resend-invite" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Origin: https://app.example.com"
```

If the original link is still valid it is sent again unchanged, keeping its original 7-day expiry. If it has expired, a fresh link valid for 7 days is issued and the old one stays dead. As with the invite endpoint, `inviteLink` is always returned and `emailSent` tells you whether the email went out.

| Status | Message                                                                                                                                                                                      | When                                                                                                    |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 400    | `Employee with email agent@example.com does not exist.`                                                                                                                                      | The email is not a member of your organisation.                                                         |
| 400    | `The account for agent@example.com was deleted. Restore it instead of inviting again: open Settings → Employees, find the row marked "Deleted", and press Restore (needs OWNER permission).` | The email belongs to a removed member. An `OWNER` must [restore](#restore-a-removed-member) them first. |
| 400    | `agent@example.com has already activated their account.`                                                                                                                                     | The member is already `active`; there is nothing to resend.                                             |
| 403    | `You do not have permission to access employee management feature. ...`                                                                                                                      | The signed-in caller's role lacks `employeeManagement`.                                                 |

---

### Switch a Member On or Off

:::api
method: PUT
endpoint: /v1/auth/business-employees/toggle-status
title: Switch a Member On or Off
description: Set a member's `isActive` flag. Off means automatic chat assignment skips them; their login and role are unchanged.

## Body Parameters

- email: string [required] - Email of the member. Case-insensitive
- isActive: boolean [required] - `true` to mark the member available, `false` to mark them unavailable

```request
{
  "email": "agent@example.com",
  "isActive": false
}
```

## Response

```response
{
  "message": "Employee Rahul Verma is now inactive",
  "data": {
    "email": "agent@example.com",
    "isActive": false
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/toggle-status" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "email": "agent@example.com", "isActive": false }'
```

Use this to take a member out of rotation (end of shift, leave) without removing them. The flag is per organisation and is read by:

- [Automatic chat assignment](#automatic-chat-assignment) when `method` is `forActiveEmployees`.
- `POST /v1/clients/chat/assign` called **without** an email, which picks one of the active members with access to the business (see [Contacts](/docs/api/contacts)). With no active member it fails with `No active employee found to assign chat!`.

No role permission is required. The message reads `Employee Rahul Verma is now active` when you pass `true`. A `500` is returned when the email is not a member of your organisation.

---

### Update Your Own Settings

:::api
method: PUT
endpoint: /v1/auth/business-employees/me
title: Update Your Own Settings
description: Change the signed-in member's own notification preferences. Fields you omit are left unchanged. Dashboard session only.

## Body Parameters

- metaData: object - `{ "templateEmailNotification": boolean, "webhookFailureEmailNotification": boolean }`. Both keys are optional; no other keys are accepted

```request
{
  "metaData": {
    "templateEmailNotification": true,
    "webhookFailureEmailNotification": false
  }
}
```

## Response

```response
{
  "message": "Settings updated",
  "data": {
    "metaData": {
      "templateEmailNotification": true,
      "webhookFailureEmailNotification": false
    }
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/me" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "metaData": { "templateEmailNotification": true } }'
```

- `templateEmailNotification`: email this member when a template's review status changes (approved, rejected, paused).
- `webhookFailureEmailNotification`: email this member when webhook deliveries to your endpoint keep failing.

The target is always the caller: there is no email in the body or path. An API key has no member identity and receives `401 Authenticated email missing`. Quick replies are not editable here; use [Quick Replies](#quick-replies). Unknown keys, inside or outside `metaData`, fail validation with a `400`.

---

## Business Access

If your organisation has more than one WhatsApp number (business), each member has a list of the businesses they may open: `accessibleBusinessIds` in the member record. A member cannot switch to, or act on, a business that is not in their list, and a `?business_id=` swap on any API call is refused for them with `403 You do not have access to this business. Contact your account owner.`

Both endpoints here are **`OWNER` only and dashboard session only**: an API key, or a signed-in member with any other role, receives `403 Only an OWNER can manage business access.` When inviting a member you can set the initial list with `accessibleBusinessIds` on [Invite a Team Member](#invite-a-team-member). Business IDs come from `GET /v1/business` (`data.id`) or from `GET /v1/business/account-status?scope=org` on the [Business](/docs/api/business) page.

:::api
method: PUT
endpoint: /v1/auth/business-employees/:emailId/businesses/:bizId/access
title: Grant or Revoke Access to One Business
description: Add a single business to, or remove it from, a member's accessible list. OWNER role only; dashboard session only.

## Path Parameters

- emailId: string [required] - Email of the member, URL-encoded
- bizId: number [required] - ID of a business in your organisation

## Body Parameters

- hasAccess: boolean [required] - `true` to grant access, `false` to revoke it

```request
{
  "hasAccess": true
}
```

## Response

```response
{
  "message": "Granted agent@example.com access to business.",
  "data": {
    "emailId": "agent@example.com",
    "businessId": 12346,
    "accessibleBusinessIds": [12345, 12346]
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/agent%40example.com/businesses/12346/access" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "hasAccess": true }'
```

The message reads `Revoked agent@example.com access to business.` when you pass `false`. Granting a business the member already has, or revoking one they do not have, succeeds and returns the unchanged list.

---

:::api
method: PUT
endpoint: /v1/auth/business-employees/:emailId/businesses/access
title: Replace a Member's Business Access
description: Set a member's accessible businesses to exactly the given list in one call. Backs "select all" and "clear all". OWNER role only; dashboard session only.

## Path Parameters

- emailId: string [required] - Email of the member, URL-encoded

## Body Parameters

- businessIds: array [required] - The complete list of business IDs the member may open. IDs that are not businesses of your organisation are dropped silently; duplicates are collapsed. Pass `[]` to remove all access

```request
{
  "businessIds": [12345, 12346]
}
```

## Response

```response
{
  "message": "Updated business access for agent@example.com.",
  "data": {
    "emailId": "agent@example.com",
    "accessibleBusinessIds": [12345, 12346]
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/agent%40example.com/businesses/access" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "businessIds": [12345, 12346] }'
```

`accessibleBusinessIds` in the response is the list as stored, which is the source of truth after sanitising; compare it with what you sent if you need to detect dropped IDs.

### Business Access Errors

| Status | Message                                                                   | When                                                                                                                               |
| ------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 400    | `Invalid business id.`                                                    | `bizId` in the path is not a number.                                                                                               |
| 400    | `hasAccess must be a boolean.`                                            | `hasAccess` is missing or not `true`/`false`.                                                                                      |
| 400    | `businessIds must be an array.`                                           | `businessIds` is missing or not an array.                                                                                          |
| 400    | `Cannot revoke — at least one OWNER must retain access to each business.` | The member is an `OWNER` and removing the business would leave it with no active `OWNER`. Give another `OWNER` access to it first. |
| 404    | `Business not found in your organization.`                                | `bizId` is not a business of your organisation.                                                                                    |
| 404    | `Employee agent@example.com not found in your organization.`              | The email is not a member of your organisation.                                                                                    |
| 403    | `Only an OWNER can manage business access.`                               | The caller is an API key or a signed-in member without the `OWNER` role.                                                           |

---

## Chat Assignment Settings

### Automatic chat assignment

When automatic chat assignment is on, every incoming WhatsApp message that starts a new conversation, or arrives on a conversation nobody is assigned to, is handed to one team member automatically. The member sees it in their inbox and the chat shows up under `assigned=true` on the [Contacts](/docs/api/contacts) list. The setting is per business and is visible as `integrations.chatAssignment` in `GET /v1/business`.

:::api
method: PUT
endpoint: /v1/auth/business-employees/auto-chat-assign
title: Configure Automatic Chat Assignment
description: Turn automatic assignment of unassigned incoming chats on or off for this business and choose how the member is picked. Requires `automaticChatAssignment`.

## Body Parameters

- isAutomaticChatAssignment: boolean [required] - `true` to assign unassigned incoming chats automatically, `false` to leave them unassigned
- method: string [required] - How a member is picked: `forActiveEmployees`, `roundRobin`, `leastBusy` or `random`. See the mode table below

```request
{
  "isAutomaticChatAssignment": true,
  "method": "forActiveEmployees"
}
```

## Response

```response
{
  "message": "Successfully automatic chat assignment on!",
  "data": {
    "isAutomaticChatAssignment": true,
    "method": "forActiveEmployees"
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/auto-chat-assign" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "isAutomaticChatAssignment": true, "method": "forActiveEmployees" }'
```

The message reads `Successfully automatic chat assignment off!` when you pass `false`. `method` is required even when turning the feature off; it is stored and used the next time you turn it on.

#### How a member is picked

Assignment rotates: among the eligible members, the one who has **never** been auto-assigned a chat is picked first, then the one whose last assignment is the oldest. Each pick stamps that member's last-assigned time, so consecutive chats go to different people. Only members who have accepted their invitation (`status: "active"`) and have not been removed are eligible.

| `method`             | Eligible members                                                                                                                                                                               |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `forActiveEmployees` | Members whose `isActive` flag is `true` (see [Switch a Member On or Off](#switch-a-member-on-or-off)). Recommended: switch people off at the end of their shift and they stop receiving chats. |
| `roundRobin`         | Every accepted member, regardless of the `isActive` flag.                                                                                                                                      |
| `leastBusy`          | Same as `roundRobin` today: every accepted member, in rotation by last assignment. Accepted so you can set it now; the pool may be refined in future.                                          |
| `random`             | Same as `roundRobin` today.                                                                                                                                                                    |

A chat that already has an assignee is never reassigned by this feature; use `POST /v1/clients/chat/assign` or `POST /v1/clients/chat/multiassign` to change it. If no eligible member exists, the chat simply stays unassigned. Chats created by outbound campaigns or API sends are not auto-assigned until the contact replies.

---

### Quick Replies

Quick replies are canned messages a team member can insert in the inbox by typing a shortcut. They are stored per member, in `metaData.quickReplies` of the member record, and this endpoint replaces a member's whole list.

:::api
method: PUT
endpoint: /v1/auth/business-employees/quick-replies
title: Set a Member's Quick Replies
description: Replace the full list of quick replies for one team member. Requires `quickReplyManagement`.

## Body Parameters

- email: string [required] - Email of the member whose quick replies to set. Case-insensitive
- quickReplies: array [required] - The complete list. Each entry is a message payload in the same shape `POST /v1/messages/send` accepts, without `clientWaNumber`, plus a non-empty `shortcut`. Pass `[]` to clear the list

```request
{
  "email": "agent@example.com",
  "quickReplies": [
    {
      "shortcut": "hi",
      "messageType": "text",
      "message": "Hello! Thanks for contacting Acme Retail. How can I help you today?"
    },
    {
      "shortcut": "catalog",
      "messageType": "media",
      "mediaType": "document",
      "url": "https://cdn.acme.com/catalog-2026.pdf",
      "name": "catalog-2026.pdf",
      "mimeType": "application/pdf",
      "caption": "Here is our latest catalog."
    },
    {
      "shortcut": "order",
      "messageType": "template",
      "templateName": "order_status_update",
      "languageCode": "en",
      "variables": []
    }
  ]
}
```

## Response

```response
{
  "message": "Quick Replies added successfully",
  "data": {
    "email": "agent@example.com",
    "quickReplies": [
      {
        "shortcut": "hi",
        "messageType": "text",
        "message": "Hello! Thanks for contacting Acme Retail. How can I help you today?"
      },
      {
        "shortcut": "catalog",
        "messageType": "media",
        "mediaType": "document",
        "url": "https://cdn.acme.com/catalog-2026.pdf",
        "name": "catalog-2026.pdf",
        "mimeType": "application/pdf",
        "caption": "Here is our latest catalog."
      },
      {
        "shortcut": "order",
        "messageType": "template",
        "templateName": "order_status_update",
        "languageCode": "en",
        "variables": []
      }
    ]
  }
}
```

:::

```bash
curl -X PUT "{{API_URL}}/v1/auth/business-employees/quick-replies" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agent@example.com",
    "quickReplies": [
      { "shortcut": "hi", "messageType": "text", "message": "Hello! How can I help you today?" }
    ]
  }'
```

Each quick reply is one of the message types documented on the [Messages](/docs/api/messages) page (`text`, `media`, `template`, `interactive`, `contacts` or `location`) with the same required fields for that type, minus the recipient. `text`, `media` and `template` entries reject unknown fields with a `400`. Because the list is replaced on every call, read the current list from [List Team Members](#list-team-members) first, modify it, and send the whole thing back. A `404 Employee Details not found with agent@example.com` means the email is not a member of your organisation.

---

### Assigning chats by email

The emails returned by [List Team Members](#list-team-members) are the identifiers used to route conversations on the [Contacts](/docs/api/contacts) page:

- `POST /v1/clients/chat/assign` with `{ "clientWaNumber", "email" }` assigns a chat to one member, replacing any current assignees. Omit `email` to auto-assign to an active member with access to the business.
- `POST /v1/clients/chat/multiassign` with `{ "clientWaNumber", "emails": [...] }` assigns a chat to several members, or unassigns everyone with `[]`.
- `POST /v1/clients` accepts `assignTo` (an email) on each contact when creating or updating contacts.

An email is accepted only if it belongs to a member of your organisation who has accepted their invitation and has not been removed. Removing a member does not unassign their chats; reassign them with one of the calls above.

---

## Roles and Permissions

Every team member has exactly one **role**, and a role is a named set of on/off **permissions**. Permissions control what the member can see and do in the dashboard; several of them are also enforced by the API when the request comes from a signed-in member (the endpoints on this page name theirs).

Every organisation starts with three roles: `OWNER`, `MANAGER` and `OPERATOR`. All three begin with every permission on except `contactNumberMasking` (off) and `hideCodeEditorAiAgent` (on); you then tune each role from the dashboard or with the endpoint below. `OWNER` is special: it is the only role allowed to restore removed members and to manage business access, and the organisation must always keep at least one active `OWNER`. Role names are stored with spaces replaced by underscores.

Roles are managed as a set through two endpoints. Neither endpoint creates or deletes roles; they only read and change the permissions of the roles your organisation already has.

### Get Roles

:::api
method: GET
endpoint: /v1/role-permission
title: Get Roles
description: Return every role of your organisation with its full permission set, oldest role first.

## Response

```response
{
  "message": "Successfully Fetched List of permission manager!",
  "data": [
    {
      "id": 301,
      "role": "OWNER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "contactsManagement": true,
      "viewAllContacts": true,
      "exportAllContacts": true,
      "attributeAndTagsManagement": true,
      "createNewCampaign": true,
      "exportCampaignStats": true,
      "addNewApp": true,
      "viewWabaApiDetails": true,
      "manageWabaApiDetails": true,
      "permissionManagement": true,
      "employeeManagement": true,
      "webhookManagement": true,
      "templateManagement": true,
      "wabaProfileManagement": true,
      "viewApiKey": true,
      "createApiKey": true,
      "automaticChatAssignment": true,
      "quickReplyManagement": true,
      "optInOutManagement": true,
      "readReceiptManagement": true,
      "registerMetaAPI": true,
      "registerLinkTracker": true,
      "callRecording": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:00.000Z"
    },
    {
      "id": 302,
      "role": "MANAGER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "contactsManagement": true,
      "viewAllContacts": true,
      "exportAllContacts": true,
      "attributeAndTagsManagement": true,
      "createNewCampaign": true,
      "exportCampaignStats": true,
      "addNewApp": true,
      "viewWabaApiDetails": true,
      "manageWabaApiDetails": true,
      "permissionManagement": false,
      "employeeManagement": true,
      "webhookManagement": true,
      "templateManagement": true,
      "wabaProfileManagement": true,
      "viewApiKey": false,
      "createApiKey": false,
      "automaticChatAssignment": true,
      "quickReplyManagement": true,
      "optInOutManagement": true,
      "readReceiptManagement": true,
      "registerMetaAPI": false,
      "registerLinkTracker": true,
      "callRecording": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:10.000Z"
    },
    {
      "id": 303,
      "role": "OPERATOR",
      "businessId": 12345,
      "contactNumberMasking": true,
      "viewAllChat": false,
      "contactsManagement": false,
      "viewAllContacts": false,
      "exportAllContacts": false,
      "attributeAndTagsManagement": false,
      "createNewCampaign": false,
      "exportCampaignStats": false,
      "addNewApp": false,
      "viewWabaApiDetails": false,
      "manageWabaApiDetails": false,
      "permissionManagement": false,
      "employeeManagement": false,
      "webhookManagement": false,
      "templateManagement": false,
      "wabaProfileManagement": false,
      "viewApiKey": false,
      "createApiKey": false,
      "automaticChatAssignment": false,
      "quickReplyManagement": true,
      "optInOutManagement": false,
      "readReceiptManagement": false,
      "registerMetaAPI": false,
      "registerLinkTracker": false,
      "callRecording": false,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:20.000Z"
    }
  ]
}
```

:::

```bash
curl -X GET "{{API_URL}}/v1/role-permission" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

No role permission is required to read roles. `businessId` is the business the role was created under; the role itself applies to every business in the organisation. The values shown for `MANAGER` and `OPERATOR` above are an example of a tuned setup, not the initial defaults.

---

### Update Roles

:::api
method: POST
endpoint: /v1/role-permission
title: Update Roles
description: Change permissions on one or more existing roles. Send only the roles and keys you want to change; everything else is left as it is. Returns the full updated role list. Requires `permissionManagement`.

## Body Parameters

- role: string [required] - The body is an array of objects, one per role to change. `role` names an existing role in your organisation. Put any of the permission keys from the table below next to it, each `true` or `false`; keys you omit are unchanged

```request
[
  {
    "role": "OPERATOR",
    "viewAllChat": false,
    "contactNumberMasking": true,
    "quickReplyManagement": true
  },
  {
    "role": "MANAGER",
    "createApiKey": false
  }
]
```

## Response

```response
{
  "message": "Successfully updated list of permission manager!",
  "data": [
    {
      "id": 301,
      "role": "OWNER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "permissionManagement": true,
      "employeeManagement": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:00.000Z"
    },
    {
      "id": 302,
      "role": "MANAGER",
      "businessId": 12345,
      "contactNumberMasking": false,
      "viewAllChat": true,
      "permissionManagement": false,
      "createApiKey": false,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:10.000Z"
    },
    {
      "id": 303,
      "role": "OPERATOR",
      "businessId": 12345,
      "contactNumberMasking": true,
      "viewAllChat": false,
      "quickReplyManagement": true,
      "hideCodeEditorAiAgent": true,
      "createdAt": "2025-01-10T08:30:20.000Z"
    }
  ]
}
```

:::

```bash
curl -X POST "{{API_URL}}/v1/role-permission" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    { "role": "OPERATOR", "viewAllChat": false, "contactNumberMasking": true },
    { "role": "MANAGER", "createApiKey": false }
  ]'
```

The request body is a JSON **array**, one object per role to change. The response `data` is the complete role list with every permission key, in the same shape as [Get Roles](#get-roles) (shortened above). Changes apply to every member holding the role from their next request; a signed-in member picks them up on their next token refresh.

#### Update Roles Errors

| Status | Message                                                                   | When                                                                                                    |
| ------ | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 400    | Validation message from the schema                                        | The body is not an array, an entry has no `role`, or a permission value is not a boolean.               |
| 400    | `The 'OWNER' role must have 'permissionManagement' enabled.`              | You tried to switch `permissionManagement` off for `OWNER`, which would lock everyone out of this page. |
| 400    | `Roles not found: SUPPORT, SALES`                                         | One or more `role` names do not exist in your organisation. Nothing is changed.                         |
| 403    | `You do not have permission to access permission management feature. ...` | The signed-in caller's role lacks `permissionManagement`.                                               |

---

### Permission keys

Every role carries all of the keys below. Each is `true` (allowed) or `false` (denied).

| Key                          | Area            | Allows the member to                                                                                         |
| ---------------------------- | --------------- | ------------------------------------------------------------------------------------------------------------ |
| `contactNumberMasking`       | Global          | See contact phone numbers masked (`9177*****143`) everywhere in the dashboard. `true` hides the full number. |
| `hideCodeEditorAiAgent`      | Global          | Hide the AI Studio and AI Agent entries from the navigation. `true` hides them.                              |
| `viewAllChat`                | Inbox           | See every conversation in the inbox, not only the chats assigned to them.                                    |
| `contactsManagement`         | Inbox, Contacts | Add, edit and delete contacts, and manage WhatsApp groups.                                                   |
| `viewAllContacts`            | Contacts        | Open the full contact list.                                                                                  |
| `exportAllContacts`          | Contacts        | Download the full contact list.                                                                              |
| `attributeAndTagsManagement` | Contacts        | Create, change and delete contact attributes and tags.                                                       |
| `createNewCampaign`          | Bulk messaging  | Create and send campaigns.                                                                                   |
| `exportCampaignStats`        | Bulk messaging  | Download detailed campaign statistics.                                                                       |
| `addNewApp`                  | Integrations    | Connect third-party applications from the app store.                                                         |
| `viewWabaApiDetails`         | Settings        | View the WhatsApp Business API connection details.                                                           |
| `manageWabaApiDetails`       | Settings        | Add or change the WhatsApp Business API connection details.                                                  |
| `permissionManagement`       | Settings        | Edit roles and permissions (this page's [Update Roles](#update-roles)). Always on for `OWNER`.               |
| `employeeManagement`         | Settings        | Invite, update, remove and re-invite team members.                                                           |
| `webhookManagement`          | Settings        | Create, change and delete webhook URLs.                                                                      |
| `templateManagement`         | Settings        | Create, change and delete message templates.                                                                 |
| `wabaProfileManagement`      | Settings        | Update the WhatsApp business profile (about, address, picture).                                              |
| `viewApiKey`                 | Settings        | View existing API keys.                                                                                      |
| `createApiKey`               | Settings        | Create new API keys.                                                                                         |
| `registerMetaAPI`            | Settings        | Register the phone number with the WhatsApp Cloud API.                                                       |
| `registerLinkTracker`        | Settings        | Enable link tracking and set a custom tracking domain.                                                       |
| `callRecording`              | Settings        | Turn call recording on for voice calls.                                                                      |
| `automaticChatAssignment`    | Communication   | Configure [automatic chat assignment](#automatic-chat-assignment).                                           |
| `quickReplyManagement`       | Communication   | Create and delete [quick replies](#quick-replies).                                                           |
| `optInOutManagement`         | Communication   | Configure opt-in and opt-out rules (see [Business](/docs/api/business)).                                     |
| `readReceiptManagement`      | Communication   | Turn read receipts on or off (see [Business](/docs/api/business)).                                           |

Note the two inverted keys: `contactNumberMasking` and `hideCodeEditorAiAgent` restrict when `true`; every other key grants when `true`.

---

## Related

- [Contacts](/docs/api/contacts) - assign chats to team members by email, list chats by assignment, and set `assignTo` when creating contacts.
- [Business](/docs/api/business) - `integrations.chatAssignment` in the business details, opt-in/opt-out rules and read receipts governed by the permissions above.
- [Messages](/docs/api/messages) - the message shapes accepted as quick replies.
- [Authentication](/docs/api/authentication) - API key presets and scopes.
- [Team Management](/docs/features/settings/team) - the same features from the dashboard.
