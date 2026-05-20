---
title: Templates
description: Manage message templates
icon: FileText
order: 5
---

# Templates API

Create and manage WhatsApp message templates. Templates are required to initiate conversations outside the 24-hour customer service window.

> [!NOTE]
> All templates must be approved by Meta before they can be used. Approval typically takes 24-48 hours.

---

:::api
method: POST
endpoint: /v1/templates
title: Create Template
description: Submit a new message template for Meta approval.

## Body Parameters

- name: string [required] - Template name (lowercase, underscores only)
- category: string [required] - UTILITY, MARKETING, or AUTHENTICATION
- language: string [required] - Language code (e.g., en, hi, es)
- components: array [required] - Template components (header, body, footer, buttons)

```request
{
  "name": "order_confirmation",
  "category": "UTILITY",
  "language": "en",
  "components": [
    {
      "type": "HEADER",
      "format": "TEXT",
      "text": "Order Confirmed!"
    },
    {
      "type": "BODY",
      "text": "Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.",
      "example": {
        "body_text": [["John", "ORD-123", "Jan 20"]]
      }
    },
    {
      "type": "FOOTER",
      "text": "Thank you for shopping with us!"
    },
    {
      "type": "BUTTONS",
      "buttons": [
        { "type": "URL", "text": "Track Order", "url": "https://example.com/track/{{1}}" },
        { "type": "QUICK_REPLY", "text": "Contact Support" }
      ]
    }
  ]
}
```

## Response

```response
{
  "code": "OK",
  "message": "Template submitted for approval",
  "data": {
    "id": "1234567890",
    "name": "order_confirmation",
    "status": "PENDING"
  }
}
```

:::

---

## Component Types

### Header

| Field    | Type   | Required | Description                                   |
| -------- | ------ | -------- | --------------------------------------------- |
| `type`   | string | Yes      | `HEADER`                                      |
| `format` | string | Yes      | `TEXT`, `IMAGE`, `VIDEO`, `DOCUMENT`          |
| `text`   | string | No       | Header text (max 60 chars, required for TEXT) |

### Body

| Field     | Type   | Required | Description                  |
| --------- | ------ | -------- | ---------------------------- |
| `type`    | string | Yes      | `BODY`                       |
| `text`    | string | Yes      | Body text (max 1024 chars)   |
| `example` | object | No       | Example values for variables |

### Footer

| Field  | Type   | Required | Description                |
| ------ | ------ | -------- | -------------------------- |
| `type` | string | Yes      | `FOOTER`                   |
| `text` | string | Yes      | Footer text (max 60 chars) |

### Buttons

```json
{
  "type": "BUTTONS",
  "buttons": [
    {
      "type": "PHONE_NUMBER",
      "text": "Call Us",
      "phone_number": "+919876543210"
    },
    { "type": "URL", "text": "Visit", "url": "https://example.com/{{1}}" },
    { "type": "QUICK_REPLY", "text": "Yes" },
    { "type": "COPY_CODE", "example": "DISCOUNT20" }
  ]
}
```

**Button Limits:** Max 3 buttons for QUICK_REPLY, max 2 for URL/PHONE.

---

:::api
method: GET
endpoint: /v1/templates
title: List All Templates
description: Get all message templates for your business, including their approval status.

## Response

```response
{
  "data": [
    {
      "id": "1234567890",
      "name": "order_confirmation",
      "category": "UTILITY",
      "language": "en",
      "status": "APPROVED",
      "components": [...]
    }
  ]
}
```

:::

---

:::api
method: GET
endpoint: /v1/templates/:templateName
title: Get Template by Name
description: Retrieve a specific template by its name.

## Path Parameters

- templateName: string [required] - Template name

## Response

```response
{
  "data": {
    "id": "1234567890",
    "name": "order_confirmation",
    "category": "UTILITY",
    "language": "en",
    "status": "APPROVED",
    "components": [...]
  }
}
```

:::

---

:::api
method: DELETE
endpoint: /v1/templates/:templateName/:templateId
title: Delete Template
description: Delete a message template you no longer want to use.

## Path Parameters

- templateName: string [required] - Template name
- templateId: string [required] - Template ID from Meta

## Response

```response
{
  "code": "OK",
  "message": "Successfully delete template name is (order_confirmation)!",
  "data": {
    "success": true
  }
}
```

:::

---

:::api
method: GET
endpoint: /v1/templates/analytics
title: Get Template Analytics
description: Get delivery and engagement statistics for your templates.

## Query Parameters

- from: string - Start date (YYYY-MM-DD)
- to: string - End date (YYYY-MM-DD)
- templateName: string - Filter by specific template

## Response

```response
{
  "data": [
    {
      "templateName": "order_confirmation",
      "sent": 1000,
      "delivered": 980,
      "read": 750,
      "failed": 20
    }
  ]
}
```

:::

---

## Categories

| Category         | Use Case      | Examples                                        |
| ---------------- | ------------- | ----------------------------------------------- |
| `UTILITY`        | Transactional | Order updates, shipping, receipts, appointments |
| `MARKETING`      | Promotional   | Offers, announcements, re-engagement            |
| `AUTHENTICATION` | Verification  | OTP, login codes, 2FA                           |

> [!TIP]
> UTILITY templates have higher delivery rates and lower costs than MARKETING templates.

---

## Template Status

| Status     | Description          |
| ---------- | -------------------- |
| `PENDING`  | Under review by Meta |
| `APPROVED` | Ready to use         |
| `REJECTED` | Rejected by Meta     |
| `PAUSED`   | Temporarily paused   |
| `DISABLED` | Permanently disabled |
