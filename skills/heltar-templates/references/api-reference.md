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

This page covers the full template lifecycle:

| Section                                                    | What it does                                                                                        |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [Create](#create-template) / [Update](#update-template)    | Submit a new template to Meta, or edit an existing one                                              |
| [List](#list-all-templates) / [Get](#get-template-by-name) | Read your templates and their approval status                                                       |
| [Delete](#delete-template)                                 | Remove a template (all languages, or one language version)                                          |
| [Template library](#template-library)                      | Browse Meta's pre-approved UTILITY and AUTHENTICATION templates and create from them                |
| [Media headers](#upload-media-for-a-template-header)       | Upload a sample file and get the media handle needed for IMAGE, VIDEO and DOCUMENT headers          |
| [Media links](#template-media-links)                       | Store the media URL(s) used when a media-header template is sent                                    |
| [Category updates](#template-category-updates)             | See which templates Meta recategorised, and when                                                    |
| [Fallback templates](#template-fallback)                   | Automatically send a replacement template when the original is paused or recategorised to MARKETING |
| [Pause marketing templates](#pause-marketing-templates)    | Block every MARKETING template send for your business with one switch                               |
| [Analytics](#get-template-analytics)                       | Sent and delivered counts from Meta                                                                 |

---

## Authentication

All template endpoints require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

Endpoints under `/v1/templates` need the `templates:read` scope for `GET` requests and `templates:write` for `POST` and `DELETE` requests. A key created with the **Full access** or **Read-only** preset covers these automatically. See [Authentication](/docs/api/authentication) for full setup instructions.

---

## Create Template

:::api
method: POST
endpoint: /v1/templates
title: Create Template
description: Submit a new message template for Meta approval.

## Body Parameters

- name: string [required] - Template name, 1-512 characters (lowercase, underscores only)
- category: string [required] - `UTILITY`, `MARKETING` or `AUTHENTICATION` (case-insensitive)
- language: string [required] - Language code, 2-5 characters (e.g., `en`, `hi`, `en_US`)
- components: array [required] - Template components. Must contain a `BODY` component. Optional only when `library_template_name` is set
- allow_category_change: boolean - Let Meta change the category during review if it disagrees with yours (default `true`)
- library_template_name: string - Name of a template from the template library (see Template Library below) to create from. When set, `components` is optional
- library_template_button_inputs: array - Button inputs (URLs, phone numbers) for the library template's buttons

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
  "message": "Successfully create template (order_confirmation)!",
  "data": {
    "id": "1234567890123456",
    "status": "PENDING",
    "category": "UTILITY"
  }
}
```

:::

`data` is Meta's creation result: the new template `id`, its initial `status` (usually `PENDING`) and the `category` Meta assigned. If `allow_category_change` is `true`, the returned category can differ from the one you sent.

### Create Template Example

:::code-group

```curl
curl -X POST "{{API_URL}}/v1/templates" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "order_confirmation",
    "category": "UTILITY",
    "language": "en",
    "components": [
      { "type": "HEADER", "format": "TEXT", "text": "Order Confirmed!" },
      {
        "type": "BODY",
        "text": "Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.",
        "example": { "body_text": [["John", "ORD-123", "Jan 20"]] }
      },
      { "type": "FOOTER", "text": "Thank you for shopping with us!" },
      {
        "type": "BUTTONS",
        "buttons": [
          { "type": "URL", "text": "Track Order", "url": "https://example.com/track/{{1}}" },
          { "type": "QUICK_REPLY", "text": "Contact Support" }
        ]
      }
    ]
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/templates', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'order_confirmation',
    category: 'UTILITY',
    language: 'en',
    components: [
      { type: 'HEADER', format: 'TEXT', text: 'Order Confirmed!' },
      {
        type: 'BODY',
        text: 'Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.',
        example: { body_text: [['John', 'ORD-123', 'Jan 20']] },
      },
      { type: 'FOOTER', text: 'Thank you for shopping with us!' },
      {
        type: 'BUTTONS',
        buttons: [
          {
            type: 'URL',
            text: 'Track Order',
            url: 'https://example.com/track/{{1}}',
          },
          { type: 'QUICK_REPLY', text: 'Contact Support' },
        ],
      },
    ],
  }),
});
const result = await response.json();
console.log(result.data.id, result.data.status);
```

```python
import requests

response = requests.post(
    "{{API_URL}}/v1/templates",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={
        "name": "order_confirmation",
        "category": "UTILITY",
        "language": "en",
        "components": [
            {"type": "HEADER", "format": "TEXT", "text": "Order Confirmed!"},
            {
                "type": "BODY",
                "text": "Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.",
                "example": {"body_text": [["John", "ORD-123", "Jan 20"]]},
            },
            {"type": "FOOTER", "text": "Thank you for shopping with us!"},
            {
                "type": "BUTTONS",
                "buttons": [
                    {"type": "URL", "text": "Track Order", "url": "https://example.com/track/{{1}}"},
                    {"type": "QUICK_REPLY", "text": "Contact Support"},
                ],
            },
        ],
    },
)
result = response.json()
print(result["data"]["id"], result["data"]["status"])
```

:::

### Create Template Errors

| Status | `errorMessage`                                                        | Cause                                                                                                                  |
| ------ | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 400    | Validation error                                                      | A field failed validation (missing `BODY`, header text over 60 characters, unknown category, and so on)                |
| 400    | `Business details are missing. So please add first business details!` | Your WhatsApp Business Account is not fully connected yet                                                              |
| 400    | `Failed to create template`                                           | Meta rejected the request. Meta's error is returned in `errorRaw` (for example a duplicate name or an invalid example) |
| 403    | Scope error                                                           | The API key does not have `templates:write`                                                                            |

---

## Component Types

Component `type` and header `format` values are case-insensitive.

### Header

| Field     | Type   | Required | Description                                                                                                                                                                                             |
| --------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type`    | string | Yes      | `HEADER`                                                                                                                                                                                                |
| `format`  | string | Yes      | `TEXT`, `IMAGE`, `VIDEO`, `DOCUMENT`, `LOCATION` or `PRODUCT`                                                                                                                                           |
| `text`    | string | No       | Header text (1-60 chars, required for `TEXT`)                                                                                                                                                           |
| `example` | object | No       | `header_text`: sample values for a `TEXT` header variable. `header_handle`: the media handle from [resumable upload](#upload-media-for-a-template-header), required for `IMAGE`, `VIDEO` and `DOCUMENT` |

### Body

| Field                         | Type    | Required | Description                                                      |
| ----------------------------- | ------- | -------- | ---------------------------------------------------------------- |
| `type`                        | string  | Yes      | `BODY`                                                           |
| `text`                        | string  | No       | Body text (1-1024 chars). Omit only for AUTHENTICATION templates |
| `example`                     | object  | No       | `body_text`: array of sample value arrays, one per variable      |
| `add_security_recommendation` | boolean | No       | AUTHENTICATION templates only: adds Meta's "do not share" line   |

### Footer

| Field                     | Type   | Required | Description                                                  |
| ------------------------- | ------ | -------- | ------------------------------------------------------------ |
| `type`                    | string | Yes      | `FOOTER`                                                     |
| `text`                    | string | No       | Footer text (1-60 chars)                                     |
| `code_expiration_minutes` | number | No       | AUTHENTICATION templates only: how long the code stays valid |

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

### Other components

| Component                 | Fields                                                                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `CAROUSEL`                | `cards`: array of cards, each with its own `components` (a media `HEADER`, a `BODY`, optional `BUTTONS`). Every card must contain a `BODY`. |
| `LIMITED_TIME_OFFER`      | `limited_time_offer`: `{ "text": "...", "has_expiration": true }`. `text` is 1-16 characters.                                               |
| `CALL_PERMISSION_REQUEST` | Optional `text` (1-256 characters). Asks the customer for permission to receive business calls.                                             |

---

## Update Template

:::api
method: POST
endpoint: /v1/templates/:templateId
title: Update Template
description: Edit the category or components of an existing template. Both fields are optional, but send at least one.

## Path Parameters

- templateId: string [required] - The template ID returned when the template was created or listed

## Body Parameters

- category: string - New category: `UTILITY`, `MARKETING` or `AUTHENTICATION`
- components: array - Full replacement component list. Must contain a `BODY` component. Same structure as Create Template

```request
{
  "components": [
    {
      "type": "BODY",
      "text": "Hi {{1}}, your order {{2}} is confirmed. Expected delivery: {{3}}.",
      "example": {
        "body_text": [["John", "ORD-123", "Jan 20"]]
      }
    },
    {
      "type": "FOOTER",
      "text": "Thank you for shopping with us!"
    }
  ]
}
```

## Response

```response
{
  "message": "Successfully update template Id:(1234567890123456)!",
  "data": {
    "success": true
  }
}
```

:::

> [!IMPORTANT]
> `components` replaces the whole component list, not just the parts you changed. Editing an approved template sends it back to Meta for review, and Meta limits how often a template can be edited. Media headers need a fresh `header_handle` from [resumable upload](#upload-media-for-a-template-header); the display URL returned by List Templates is not accepted as a sample.

### Update Template Example

```bash
curl -X POST "{{API_URL}}/v1/templates/1234567890123456" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "components": [
      {
        "type": "BODY",
        "text": "Hi {{1}}, your order {{2}} is confirmed. Expected delivery: {{3}}.",
        "example": { "body_text": [["John", "ORD-123", "Jan 20"]] }
      },
      { "type": "FOOTER", "text": "Thank you for shopping with us!" }
    ]
  }'
```

### Update Template Errors

| Status | `errorMessage`                                                        | Cause                                                                 |
| ------ | --------------------------------------------------------------------- | --------------------------------------------------------------------- |
| 400    | Validation error                                                      | `components` is present but has no `BODY`, or a field is out of range |
| 400    | `Business details are missing. So please add first business details!` | Your WhatsApp Business Account is not fully connected yet             |
| 400    | `Failed to update template`                                           | Meta rejected the edit. Meta's error is returned in `errorRaw`        |

---

## List All Templates

:::api
method: GET
endpoint: /v1/templates
title: List All Templates
description: Get all message templates for your business, including their approval status. Results are served from the platform's template cache and kept in sync with Meta.

## Query Parameters

- refresh: boolean - Set to `true` to bypass the cache and re-fetch the full list from Meta

## Response

```response
{
  "message": "Successfully retrieved 2 templates!",
  "data": [
    {
      "id": "1234567890123456",
      "name": "order_confirmation",
      "language": "en",
      "status": "APPROVED",
      "category": "UTILITY",
      "last_updated_time": "2026-08-20T10:15:00+0000",
      "quality_score": { "score": "GREEN", "date": 1755684000 },
      "components": [
        { "type": "HEADER", "format": "TEXT", "text": "Order Confirmed!" },
        {
          "type": "BODY",
          "text": "Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.",
          "example": { "body_text": [["John", "ORD-123", "Jan 20"]] }
        },
        { "type": "FOOTER", "text": "Thank you for shopping with us!" },
        {
          "type": "BUTTONS",
          "buttons": [
            { "type": "URL", "text": "Track Order", "url": "https://example.com/track/{{1}}" },
            { "type": "QUICK_REPLY", "text": "Contact Support" }
          ]
        }
      ]
    },
    {
      "id": "1234567890123457",
      "name": "order_confirmation",
      "language": "hi",
      "status": "REJECTED",
      "rejected_reason": "INVALID_FORMAT",
      "category": "UTILITY",
      "last_updated_time": "2026-08-21T08:00:00+0000",
      "components": [{ "type": "BODY", "text": "..." }]
    }
  ]
}
```

:::

### List Templates Example

```bash
curl -X GET "{{API_URL}}/v1/templates" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```bash
curl -X GET "{{API_URL}}/v1/templates?refresh=true" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### List Response Fields

- `data[].id`: Meta's template ID (unique per language version)
- `data[].name`: template name
- `data[].language`: language code of this version
- `data[].status`: `APPROVED`, `PENDING`, `REJECTED`, `PAUSED` or `DISABLED` (see [Template Status](#template-status))
- `data[].rejected_reason`: only present when Meta rejected the template
- `data[].category`: current category, which can differ from the one you submitted if Meta recategorised it
- `data[].previous_category`: the category before Meta's last change, when applicable
- `data[].last_updated_time`: when Meta last changed the template
- `data[].quality_score`: Meta's quality rating (`GREEN`, `YELLOW`, `RED` or `UNKNOWN`) and the timestamp it was set
- `data[].components`: the template's components as stored by Meta. For media headers, `example.header_handle[0]` holds a Meta display URL

A template that exists in several languages appears once per language. If your WhatsApp Business Account is not connected yet, the response is `200` with `"message": "Please setup account first"` and an empty `data` array.

---

## Get Template by Name

:::api
method: GET
endpoint: /v1/templates/:templateName
title: Get Template by Name
description: Retrieve every language version of a template by its name, or a single version when `templateLang` is given.

## Path Parameters

- templateName: string [required] - Template name (case-insensitive)

## Query Parameters

- templateLang: string - Language code to return only that version (e.g., `en`, `en_US`)

## Response

```response
{
  "message": "Successfully retrieved template (order_confirmation)!",
  "data": [
    {
      "id": "1234567890123456",
      "name": "order_confirmation",
      "language": "en",
      "status": "APPROVED",
      "category": "UTILITY",
      "last_updated_time": "2026-08-20T10:15:00+0000",
      "components": [
        { "type": "HEADER", "format": "TEXT", "text": "Order Confirmed!" },
        {
          "type": "BODY",
          "text": "Hi {{1}}, your order {{2}} has been confirmed and will be delivered by {{3}}.",
          "example": { "body_text": [["John", "ORD-123", "Jan 20"]] }
        }
      ]
    }
  ]
}
```

:::

`data` is always an array. When no template matches the name (and language, if given), the response is `200` with an empty `data` array rather than a `404`.

### Get Template Example

```bash
curl -X GET "{{API_URL}}/v1/templates/order_confirmation?templateLang=en" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Delete Template

:::api
method: DELETE
endpoint: /v1/templates/:templateName/:templateId
title: Delete Template
description: Delete a message template you no longer want to use. Pass only the name to delete every language version, or add the template ID to delete one language version.

## Path Parameters

- templateName: string [required] - Template name
- templateId: string - Optional. Template ID of one language version. When omitted, all language versions of `templateName` are deleted

## Response

```response
{
  "message": "Successfully delete template name is (order_confirmation)!",
  "data": {
    "success": true
  }
}
```

:::

Both forms are supported:

| Request                                                    | Effect                                                       |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| `DELETE /v1/templates/order_confirmation`                  | Deletes `order_confirmation` in every language               |
| `DELETE /v1/templates/order_confirmation/1234567890123456` | Deletes only the language version with ID `1234567890123456` |

### Delete Template Example

```bash
curl -X DELETE "{{API_URL}}/v1/templates/order_confirmation" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```bash
curl -X DELETE "{{API_URL}}/v1/templates/order_confirmation/1234567890123456" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Delete Template Errors

| Status | `errorMessage`              | Cause                                                                                                 |
| ------ | --------------------------- | ----------------------------------------------------------------------------------------------------- |
| 400    | `Failed to delete template` | Meta rejected the delete (unknown name or ID, or the ID does not belong to that name). See `errorRaw` |

> [!WARNING]
> A deleted template name cannot be reused for 30 days. Messages already queued with that template will fail.

---

## Template Library

Meta maintains a library of pre-approved UTILITY and AUTHENTICATION templates for common use cases such as order confirmations, delivery updates, payment reminders and one-time passcodes. Creating from the library skips most of the review wait because the wording is already approved.

:::api
method: GET
endpoint: /v1/templates/library
title: List Library Templates
description: Browse Meta's template library. Returns up to 500 templates matching the filters, limited to templates whose variables are all numbered placeholders and that do not use an ORDER_DETAILS button.

## Query Parameters

- language: string - Language code (default `en`)
- topic: string - `ACCOUNT_UPDATES`, `CUSTOMER_FEEDBACK`, `ORDER_MANAGEMENT`, `PAYMENTS`, `EVENT_REMINDER`, `IDENTITY_VERIFICATION` or `CALL_PERMISSIONS`
- usecase: string - A use case such as `ORDER_CONFIRMATION`, `DELIVERY_UPDATE`, `PAYMENT_DUE_REMINDER`, `APPOINTMENT_REMINDER` or `FRAUD_ALERT` (see the table below)
- industry: string - `E_COMMERCE`, `FINANCIAL_SERVICES` or `TELECOMMUNICATION`
- search: string - Free-text search across the library

## Response

```response
{
  "message": "Retrieved 42 templates from library",
  "data": [
    {
      "id": "1512823919195657",
      "name": "order_confirmation_1",
      "language": "en",
      "category": "UTILITY",
      "topic": "ORDER_MANAGEMENT",
      "usecase": "ORDER_CONFIRMATION",
      "industry": ["E_COMMERCE"],
      "header": "Order confirmed",
      "body": "Hi {{1}}, thanks for your order! Your order {{2}} has been received and is being processed.",
      "body_params": ["John", "ORD-123"],
      "body_param_types": ["TEXT", "TEXT"],
      "buttons": [{ "type": "URL", "text": "Track order", "url": "https://example.com/track" }]
    }
  ]
}
```

:::

`topic`, `usecase` and `industry` are upper-cased before they are sent to Meta, so `payments` and `PAYMENTS` behave the same. The count in `message` is the number Meta returned before filtering, so `data` can be shorter.

### Library Templates Example

```bash
curl -X GET "{{API_URL}}/v1/templates/library?language=en&topic=PAYMENTS&usecase=PAYMENT_CONFIRMATION" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Library use cases

| Topic                   | Use cases                                                                                                                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ACCOUNT_UPDATES`       | `ACCOUNT_CREATION_CONFIRMATION`, `FRAUD_ALERT`, `LOW_BALANCE_WARNING`, `TRANSACTION_ALERT`, `STATEMENT_AVAILABLE`, `STATEMENT_ATTACHMENT`                                                                                 |
| `CUSTOMER_FEEDBACK`     | `FEEDBACK_SURVEY`                                                                                                                                                                                                         |
| `ORDER_MANAGEMENT`      | `ORDER_CONFIRMATION`, `ORDER_ACTION_NEEDED`, `ORDER_DELAY`, `ORDER_OR_TRANSACTION_CANCEL`, `ORDER_PICK_UP`, `SHIPMENT_CONFIRMATION`, `DELIVERY_CONFIRMATION`, `DELIVERY_UPDATE`, `DELIVERY_FAILED`, `RETURN_CONFIRMATION` |
| `PAYMENTS`              | `PAYMENT_CONFIRMATION`, `PAYMENT_DUE_REMINDER`, `PAYMENT_OVERDUE`, `PAYMENT_ACTION_REQUIRED`, `PAYMENT_REJECT_FAIL`, `PAYMENT_SCHEDULED`, `AUTO_PAY_REMINDER`, `RECEIPT_ATTACHMENT`                                       |
| `EVENT_REMINDER`        | `APPOINTMENT_CONFIRMATION`, `APPOINTMENT_REMINDER`, `APPOINTMENT_CANCELLATION`, `APPOINTMENT_SCHEDULEING`                                                                                                                 |
| `IDENTITY_VERIFICATION` | `IN_PERSON_VERIFICATION`                                                                                                                                                                                                  |
| `CALL_PERMISSIONS`      | `CALL_PERMISSION_REQUEST`                                                                                                                                                                                                 |

### Creating a template from the library

Call [Create Template](#create-template) with `library_template_name` set to the library template's `name`. Provide your own `name`, `category` and `language`; `components` can be omitted. If the library template has URL or phone buttons, supply their values in `library_template_button_inputs`.

```bash
curl -X POST "{{API_URL}}/v1/templates" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "order_confirmation",
    "category": "UTILITY",
    "language": "en",
    "library_template_name": "order_confirmation_1",
    "library_template_button_inputs": [
      { "type": "URL", "url": { "base_url": "https://example.com/track/{{1}}", "url_suffix_example": "ORD-123" } }
    ]
  }'
```

---

## Upload media for a template header

Templates with an `IMAGE`, `VIDEO` or `DOCUMENT` header (including carousel cards) must be submitted with a sample file. Upload the file here first, then put the returned handle in the header's `example.header_handle` when you create or update the template.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: POST
endpoint: /v1/business/resumable-upload
title: Upload Template Media
description: Upload a sample file through Meta's resumable upload API and get back the media handle used in a template header. Send the request as `multipart/form-data`.

## Body Parameters

- file: file [required] - The sample file. Multipart field name must be `file`
- fileLength: number - File size in bytes. Defaults to the uploaded file's size
- fileType: string - MIME type of the file. Defaults to the uploaded file's type

## Response

```response
{
  "message": "Successfully uploaded through Resumable API!",
  "data": {
    "h": "4::aW1hZ2UvanBlZw==:ARZbd3Yz9mPzUE7dZpDq..."
  }
}
```

:::

`data.h` is the media handle. It is an opaque string, not a URL, and it is only valid as a template sample. Use it like this:

```json
{
  "type": "HEADER",
  "format": "IMAGE",
  "example": {
    "header_handle": ["4::aW1hZ2UvanBlZw==:ARZbd3Yz9mPzUE7dZpDq..."]
  }
}
```

### Upload limits

| Rule              | Value                                                                                                                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Max file size     | 100 MB                                                                                                                                                                                         |
| Files per request | 1                                                                                                                                                                                              |
| Images            | `image/jpeg`, `image/jpg`, `image/png`, `image/gif`, `image/webp`                                                                                                                              |
| Video             | `video/mp4`, `video/3gp`, `video/3gpp`, `video/mpeg`, `video/quicktime`                                                                                                                        |
| Audio             | `audio/aac`, `audio/mp3`, `audio/mpeg`, `audio/amr`, `audio/ogg`, `audio/mp4`, `audio/wav`                                                                                                     |
| Documents         | `application/pdf`, Word (`.doc`, `.docx`), Excel (`.xls`, `.xlsx`), PowerPoint (`.ppt`, `.pptx`), `text/plain`, `text/csv`, `application/rtf`, OpenDocument text, spreadsheet and presentation |
| File name         | Max 255 characters. No path separators, none of the characters `<`, `>`, `:`, `"`, `?`, `*` or a vertical bar, and it must not start with a dot                                                |
| Content check     | The file bytes must match the declared type. A file declared as an image must be a real JPEG, PNG, GIF or WebP; other media must not be HTML, SVG or XML                                       |

WhatsApp itself only renders `IMAGE` headers as JPEG or PNG, `VIDEO` headers as MP4 and `DOCUMENT` headers as PDF, so upload those formats for template samples.

### Upload Example

```bash
curl -X POST "{{API_URL}}/v1/business/resumable-upload" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "file=@/path/to/sample.jpg;type=image/jpeg"
```

### Upload Errors

| Status | `errorMessage`                                                                                   | Cause                                                            |
| ------ | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| 400    | `File not found in request body!`                                                                | No `file` field in the multipart body                            |
| 400    | `File type ... is not allowed. Allowed types: ...`                                               | MIME type is not in the lists above                              |
| 400    | `File too large. Please upload a smaller file.`                                                  | Over 100 MB                                                      |
| 400    | `Invalid filename. ...` / `Filename is too long. ...`                                            | File name failed the rules above                                 |
| 400    | `Business details are missing. So please add first business details!`                            | Your WhatsApp Business Account is not fully connected yet        |
| 403    | `Business does not have a Facebook App ID. So please add Facebook App ID in WhatsApp API Setup!` | Add the Facebook App ID in your WhatsApp API setup               |
| 400    | `Failed to upload through Resumable API`                                                         | Meta rejected the upload. Meta's error is returned in `errorRaw` |

---

## Template media links

A media handle is only a sample for review. When a media-header template is actually sent, the message needs a public URL for the image, video or document. The platform stores one media link record per template so the dashboard and inbox can fill in the header media automatically when the template is sent. For carousel templates, store one entry per card, in card order.

:::api
method: POST
endpoint: /v1/templates/media-link
title: Set Template Media Link
description: Store (or replace) the single media URL used for a template's header. Creates the record if none exists for this template, otherwise overwrites it.

## Body Parameters

- templateId: string [required] - Meta's template ID (from Create Template or List Templates)
- link: string [required] - Public HTTPS URL of the media file
- fileName: string [required] - File name to show, e.g. `brochure.pdf`

```request
{
  "templateId": "1234567890123456",
  "link": "https://cdn.example.com/media/brochure.pdf",
  "fileName": "brochure.pdf"
}
```

## Response

```response
{
  "message": "Template media link successfully saved."
}
```

:::

The message reads `Template media link successfully updated.` when a record already existed. You can get a hosted URL for your own file with [Get Presigned URL for Upload](/docs/api/messages#get-presigned-url-for-upload) on the Messages API.

### Set Media Link Example

```bash
curl -X POST "{{API_URL}}/v1/templates/media-link" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "templateId": "1234567890123456",
    "link": "https://cdn.example.com/media/brochure.pdf",
    "fileName": "brochure.pdf"
  }'
```

---

:::api
method: POST
endpoint: /v1/templates/bulk-media-link
title: Set Template Media Links (Bulk)
description: Store several media URLs for one template, for example one per carousel card. Replaces any previously stored list for the template.

## Body Parameters

- templateId: string [required] - Meta's template ID
- mediaAttachment: array [required] - Ordered list of `{ "mediaUrl": "<https URL>", "fileName": "<name>" }` objects. At least one item. Item `n` is used for card `n` of a carousel; the first item is also used as the template's main header media

```request
{
  "templateId": "1234567890123456",
  "mediaAttachment": [
    { "mediaUrl": "https://cdn.example.com/media/card-1.jpg", "fileName": "card-1.jpg" },
    { "mediaUrl": "https://cdn.example.com/media/card-2.jpg", "fileName": "card-2.jpg" },
    { "mediaUrl": "https://cdn.example.com/media/card-3.jpg", "fileName": "card-3.jpg" }
  ]
}
```

## Response

```response
{
  "message": "Template media link successfully saved."
}
```

:::

### Bulk Media Link Example

```bash
curl -X POST "{{API_URL}}/v1/templates/bulk-media-link" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "templateId": "1234567890123456",
    "mediaAttachment": [
      { "mediaUrl": "https://cdn.example.com/media/card-1.jpg", "fileName": "card-1.jpg" },
      { "mediaUrl": "https://cdn.example.com/media/card-2.jpg", "fileName": "card-2.jpg" }
    ]
  }'
```

---

:::api
method: GET
endpoint: /v1/templates/media-link
title: List Template Media Links
description: Return every stored media link record for your business.

## Response

```response
{
  "message": "Template media link successfully fetched.",
  "data": [
    {
      "templateId": "1234567890123456",
      "link": "https://cdn.example.com/media/card-1.jpg",
      "fileName": "card-1.jpg",
      "mediaAttachment": [
        { "mediaUrl": "https://cdn.example.com/media/card-1.jpg", "fileName": "card-1.jpg" },
        { "mediaUrl": "https://cdn.example.com/media/card-2.jpg", "fileName": "card-2.jpg" }
      ]
    }
  ]
}
```

:::

`link` and `fileName` always mirror the first `mediaAttachment` entry.

### List Media Links Example

```bash
curl -X GET "{{API_URL}}/v1/templates/media-link" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Template category updates

Meta can change a template's category after approval (most often UTILITY to MARKETING, which changes what each send costs). Every such change the platform is notified about is recorded. This endpoint returns those changes for all WhatsApp Business Accounts in your organisation.

:::api
method: GET
endpoint: /v1/templates/category-updates
title: List Category Updates
description: Return template category changes recorded in a date range, newest first.

## Query Parameters

- startDate: string [required] - First day to include, `YYYY-MM-DD`
- endDate: string [required] - Last day to include, `YYYY-MM-DD`. Must not be before `startDate`

## Response

```response
{
  "message": "Template category updates fetched successfully",
  "data": [
    {
      "businessAccountId": "102938475610234",
      "templateId": "1234567890123456",
      "templateName": "order_confirmation",
      "language": "en",
      "previousCategory": "UTILITY",
      "newCategory": "MARKETING",
      "createdAt": "2026-08-21T09:32:11.000Z",
      "businessId": 12345,
      "businessName": "Acme Stores",
      "bizWhatsappNumber": "919876543210",
      "countryCode": 91
    }
  ]
}
```

:::

Days are interpreted in Indian Standard Time (UTC+05:30) and both ends of the range are inclusive. One row is returned per template and category change; if Meta sends the same change more than once, only the latest is kept. `previousCategory` is `null` when Meta did not report the earlier category.

### Category Updates Example

```bash
curl -X GET "{{API_URL}}/v1/templates/category-updates?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Category Updates Errors

| Status | `errorMessage`                                                          | Cause                       |
| ------ | ----------------------------------------------------------------------- | --------------------------- |
| 400    | `Invalid date format. Expected YYYY-MM-DD format (e.g., "2025-11-01").` | Wrong date format           |
| 400    | `startDate and endDate must be valid dates.`                            | A date such as `2026-02-30` |
| 400    | `endDate must not be before startDate.`                                 | Range is reversed           |

---

## Template fallback

A fallback config sends a different template automatically when the one you asked for can no longer be sent as intended. The platform checks this on every template send, whether it comes from the API, a campaign or the inbox. Two trigger conditions are supported:

| `triggerCondition`     | Fires when                                                                                                                      | Fallback requirement         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `PAUSED`               | The source template's status is `PAUSED` (Meta pauses templates with poor quality ratings)                                      | Any compatible template      |
| `UTILITY_TO_MARKETING` | The source template's current category is `MARKETING`, typically because Meta recategorised a template you created as `UTILITY` | Must be a `UTILITY` template |

How it works:

- A config is keyed on `sourceTemplateName` + `sourceLanguageCode` + `triggerCondition`. Saving the same key again updates that config instead of creating a second one.
- The fallback is sent in the same language as the source, using the parameters you supplied for the source template. That is why the fallback must have the same variable signature: the same header format and header variable count, the same number of body variables, the same number of buttons with matching types and URL-variable usage, and the same carousel card count and card layout.
- Only one substitution happens per send. If the fallback template is itself paused, no second fallback is applied.
- A config with `isEnabled: false` is kept but ignored.
- Configs cannot form a loop (A falls back to B, B falls back to A).
- Fallback is resolved before the [marketing pause](#pause-marketing-templates) check, so a `UTILITY_TO_MARKETING` fallback keeps messages flowing even while marketing templates are paused.

:::api
method: GET
endpoint: /v1/templates/fallback
title: List Fallback Configs
description: Return all fallback configs for your business, newest first.

## Response

```response
{
  "message": "Fallback configs fetched successfully",
  "data": [
    {
      "id": 12345,
      "businessId": 12345,
      "sourceTemplateName": "order_confirmation",
      "sourceLanguageCode": "en",
      "triggerCondition": "UTILITY_TO_MARKETING",
      "fallbackTemplateName": "order_confirmation_v2",
      "isEnabled": true,
      "createdAt": "2026-08-21T09:32:11.000Z",
      "updatedAt": "2026-08-21T09:32:11.000Z"
    }
  ]
}
```

:::

### List Fallback Configs Example

```bash
curl -X GET "{{API_URL}}/v1/templates/fallback" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

:::api
method: POST
endpoint: /v1/templates/fallback
title: Create or Update Fallback Config
description: Create a fallback config, or update the fallback template and enabled flag of the config with the same source template, language and trigger. Unknown fields are rejected.

## Body Parameters

- sourceTemplateName: string [required] - Name of the template that may need a fallback
- sourceLanguageCode: string [required] - Language code of the source template (2-10 characters). The fallback is sent in this language
- triggerCondition: string [required] - `PAUSED` or `UTILITY_TO_MARKETING`
- fallbackTemplateName: string [required] - Name of the template to send instead. Must differ from `sourceTemplateName`
- isEnabled: boolean - Whether the config is active. Defaults to `true` on create; on update, omitting it keeps the current value

```request
{
  "sourceTemplateName": "order_confirmation",
  "sourceLanguageCode": "en",
  "triggerCondition": "UTILITY_TO_MARKETING",
  "fallbackTemplateName": "order_confirmation_v2",
  "isEnabled": true
}
```

## Response

```response
{
  "message": "Fallback config saved successfully",
  "data": {
    "id": 12345,
    "businessId": 12345,
    "sourceTemplateName": "order_confirmation",
    "sourceLanguageCode": "en",
    "triggerCondition": "UTILITY_TO_MARKETING",
    "fallbackTemplateName": "order_confirmation_v2",
    "isEnabled": true,
    "createdAt": "2026-08-21T09:32:11.000Z",
    "updatedAt": "2026-08-21T09:32:11.000Z"
  }
}
```

:::

Both templates must already exist in `sourceLanguageCode`. They are fetched and validated for compatibility before saving; the change takes effect on the next send.

### Save Fallback Config Example

```bash
curl -X POST "{{API_URL}}/v1/templates/fallback" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "sourceTemplateName": "order_confirmation",
    "sourceLanguageCode": "en",
    "triggerCondition": "UTILITY_TO_MARKETING",
    "fallbackTemplateName": "order_confirmation_v2"
  }'
```

### Save Fallback Config Errors

| Status | `errorMessage`                                                                              | Cause                                                                                            |
| ------ | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 400    | Validation error                                                                            | Missing field, unknown field, or an invalid `triggerCondition`                                   |
| 400    | `Business setup is incomplete`                                                              | Your WhatsApp Business Account is not connected yet                                              |
| 400    | `Source and fallback template cannot be the same`                                           | `sourceTemplateName` equals `fallbackTemplateName`                                               |
| 400    | `Loop detected: adding "a" → "b" would create a circular dependency.`                       | The new config would create a cycle with existing configs                                        |
| 404    | `Source template "order_confirmation" (en) not found`                                       | No template with that name in that language                                                      |
| 404    | `Fallback template "order_confirmation_v2" (en) not found`                                  | No template with that name in that language                                                      |
| 400    | `Fallback template must be UTILITY category for "Category Changed to Marketing" trigger...` | `UTILITY_TO_MARKETING` with a non-UTILITY fallback                                               |
| 400    | `Templates are not compatible: ...`                                                         | Variable signature mismatch. The message lists each difference (header, body, buttons, carousel) |

---

:::api
method: DELETE
endpoint: /v1/templates/fallback/:configId
title: Delete Fallback Config
description: Remove a fallback config. Sends of the source template stop being substituted immediately.

## Path Parameters

- configId: number [required] - The config `id` from List Fallback Configs

## Response

```response
{
  "message": "Fallback config deleted successfully",
  "data": {
    "id": 12345
  }
}
```

:::

### Delete Fallback Config Example

```bash
curl -X DELETE "{{API_URL}}/v1/templates/fallback/12345" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Delete Fallback Config Errors

| Status | `errorMessage`              | Cause                                           |
| ------ | --------------------------- | ----------------------------------------------- |
| 400    | `Invalid config ID`         | `configId` is not a number                      |
| 404    | `Fallback config not found` | No config with that ID belongs to your business |

---

## Pause marketing templates

A single switch that blocks every `MARKETING` template send for your business. Use it when you need to stop promotional traffic immediately (for example during a quality-rating drop) without pausing each campaign.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

:::api
method: PUT
endpoint: /v1/business/pause-marketing-templates
title: Pause or Resume Marketing Templates
description: Turn the marketing template pause on or off for your business. Takes effect on the next send.

## Body Parameters

- pauseMarketingTemplates: boolean [required] - `true` to block MARKETING template sends, `false` to allow them again

```request
{
  "pauseMarketingTemplates": true
}
```

## Response

```response
{
  "message": "Successfully enabled marketing template pause!"
}
```

:::

The message reads `Successfully disabled marketing template pause!` when you send `false`.

While the pause is on:

- Every template send re-checks the template's current category with Meta, so a template that Meta recategorised to MARKETING after you created it is caught too.
- `MARKETING` (and `MARKETING_LITE`) template messages are not sent. The message is recorded as cancelled with the reason `Marketing templates are paused for this business`, and the campaign itself keeps running for its non-marketing messages.
- If the category cannot be determined, the send is blocked as well (`Template category unavailable — cannot verify marketing pause`).
- `UTILITY` and `AUTHENTICATION` templates, free-form messages and [fallback](#template-fallback) substitutions to UTILITY templates are unaffected.

### Pause Marketing Templates Example

```bash
curl -X PUT "{{API_URL}}/v1/business/pause-marketing-templates" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "pauseMarketingTemplates": true }'
```

---

## Get Template Analytics

:::api
method: GET
endpoint: /v1/templates/analytics
title: Get Template Analytics
description: Get Meta's sent and delivered counts for your WhatsApp Business Account over a time range, bucketed by the granularity you choose.

## Query Parameters

- startDateTimestamp: number [required] - Range start as a UNIX timestamp in seconds
- endDateTimestamp: number [required] - Range end as a UNIX timestamp in seconds
- granularity: string [required] - Bucket size: `HALF_HOUR`, `DAY` or `MONTH`
- wabaNumber: string [required] - Phone number ID to report on

## Response

```response
{
  "message": "Successfully fetched analytics!",
  "data": {
    "analytics": {
      "phone_numbers": ["109876543210987"],
      "granularity": "DAY",
      "data_points": [
        { "start": 1754006400, "end": 1754092800, "sent": 1000, "delivered": 980 },
        { "start": 1754092800, "end": 1754179200, "sent": 1200, "delivered": 1174 }
      ]
    },
    "id": "102938475610234"
  }
}
```

:::

`data` is Meta's analytics payload passed through unchanged. For per-template delivery, read and click breakdowns, conversation and cost analytics, see the [Analytics API](/docs/api/analytics).

### Template Analytics Example

```bash
curl -X GET "{{API_URL}}/v1/templates/analytics?startDateTimestamp=1754006400&endDateTimestamp=1756684800&granularity=DAY&wabaNumber=109876543210987" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Template Analytics Errors

| Status | `errorMessage`              | Cause                                                                                                 |
| ------ | --------------------------- | ----------------------------------------------------------------------------------------------------- |
| 400    | `Failed to fetch analytics` | Meta rejected the query (range too wide for the granularity, unknown phone number ID). See `errorRaw` |

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
