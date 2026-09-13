---
title: Link Tracker
description: Create short, trackable links for your messages
icon: Link
order: 14
---

# Link Tracker API

Turn any URL into a short, trackable link. Put the short link in a template button, a message body, or anywhere else, and every click on it is recorded with browser, device and location details.

The same short links are generated automatically when you send a template whose URL button uses a link tracker URL type. The endpoints on this page let you create and list links yourself, outside of a template send.

---

## How Tracked Links Work

**Short URL.** Every tracked link is a short code appended to a tracker domain. By default that is the API domain:

```
{{API_URL}}/aB3xY9kQ
```

If you have registered a custom domain, links on that domain resolve the same way, so `https://links.yourbrand.com/aB3xY9kQ` opens the same destination. See [Custom Domain for Link Tracker](/docs/guides/link-tracker-custom-domain) for the DNS and certificate setup.

**Redirect.** When someone opens the short URL they are sent to the destination URL. The `redirectType` you choose at creation time controls how:

| redirectType       | Behaviour                                                                                                                                                                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `static` (default) | An HTTP redirect to the destination. The visitor's browser lands on the destination URL.                                                                                                                                                            |
| `dynamic`          | The platform fetches the destination on the visitor's behalf and serves that response from the short URL, so the short URL stays in the address bar. If the destination itself responds with a redirect, the visitor is forwarded to that location. |

**Click tracking.** Each open of a short URL by a real visitor records a click with the browser, operating system, device type, referrer and the location derived from the visitor's IP address (city, region, country, timezone). Link previews and automated fetchers are still redirected but are not counted, so WhatsApp's own link preview, search crawlers, scripted HTTP clients and `HEAD` requests do not inflate your numbers.

You can attribute a click to a recipient and a group by appending two optional path segments to the short URL: `{{API_URL}}/aB3xY9kQ/919876543210/summer-sale`. The first segment is stored as the click's identifier (for example the recipient's phone number) and the second as its group (for example a campaign ID). Links generated during a template send get these values from the message automatically.

**Where clicks show up.**

- Links generated automatically for a template message are tied to that message. The first click moves the message status to `clicked`, or to `clicked_responded` if the contact had already replied. Later clicks are recorded but do not change the status again. The status is visible on the message itself (see [Messages](/docs/api/messages)) and counted in campaign statistics as `statsClicked` and `statsClickedResponded` (see [Campaigns](/docs/api/campaigns)).
- Links created through this API are not tied to a message, so clicking them does not change any message status. Their clicks are available in the dashboard under **Integrations -> Link Tracker**, where selecting a link opens its click analytics.

**Switching link tracking on.** Automatic shortening of URLs in template sends is controlled per business with `PUT /v1/business/link-tracking` (documented on [Business](/docs/api/business)) or the toggle in **Settings -> Template Link Tracker**. The endpoints on this page and the redirects themselves work regardless of that toggle; it only decides whether template sends shorten URLs.

> [!TIP]
> A destination must be a full URL with a scheme, for example `https://www.example.com/offers`. Do not point a tracked link at another tracked link.

---

## Authentication

All link tracker endpoints require a valid API key in the `Authorization` header.

```bash
Authorization: Bearer YOUR_API_KEY
```

See [Authentication](/docs/api/authentication) for full setup instructions.

> [!NOTE]
> These endpoints are outside the per-resource scope picker. Use an API key created with the **Full access** preset (or **Read-only** for GET requests).

---

:::api
method: POST
endpoint: /v1/link-tracker/create
title: Create Link
description: Create one short, trackable link for a destination URL.

## Body Parameters

- destinationLink: string [required] - Full destination URL including the scheme (`http://` or `https://`)
- hashLength: number [required] - Length of the generated short code. Letters and digits only. Also accepted as a numeric string. `8` to `12` is a good range
- redirectType: string - `static` (default) or `dynamic`. See How Tracked Links Work above

```request
{
  "destinationLink": "https://www.example.com/offers/summer-sale",
  "hashLength": 8,
  "redirectType": "static"
}
```

## Response

```response
{
  "message": "Link successfully created.",
  "data": {
    "dataHash": "aB3xY9kQ"
  }
}
```

:::

`dataHash` is the short code. Build the short URL by appending it to your tracker domain: `{{API_URL}}/aB3xY9kQ`, or `https://links.yourbrand.com/aB3xY9kQ` on a custom domain.

If a link already exists for the same `destinationLink` in your account, the existing short code is returned and no new link is created. `hashLength` and `redirectType` are not applied in that case.

### Create Link Example

:::code-group

```bash
curl -X POST "{{API_URL}}/v1/link-tracker/create" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "destinationLink": "https://www.example.com/offers/summer-sale",
    "hashLength": 8
  }'
```

```javascript
const response = await fetch('{{API_URL}}/v1/link-tracker/create', {
  method: 'POST',
  headers: {
    Authorization: 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    destinationLink: 'https://www.example.com/offers/summer-sale',
    hashLength: 8,
  }),
});

const { data } = await response.json();
const shortUrl = `{{API_URL}}/${data.dataHash}`;
```

```python
import requests

response = requests.post(
    "{{API_URL}}/v1/link-tracker/create",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={
        "destinationLink": "https://www.example.com/offers/summer-sale",
        "hashLength": 8,
    },
)

short_url = f"{{API_URL}}/{response.json()['data']['dataHash']}"
```

:::

---

:::api
method: POST
endpoint: /v1/link-tracker/create-bulk
title: Create Links in Bulk
description: Create a short, trackable link for each destination URL in one request.

## Body Parameters

- destinationLinks: array [required] - Array of full destination URLs, each including the scheme
- hashLength: number [required] - Length of every generated short code. Also accepted as a numeric string
- redirectType: string - `static` (default) or `dynamic`. Applied to every link in the request

```request
{
  "destinationLinks": [
    "https://www.example.com/orders/12345",
    "https://www.example.com/orders/12346"
  ],
  "hashLength": 8
}
```

## Response

```response
{
  "message": "Links successfully created.",
  "data": [
    {
      "mainUrl": "https://www.example.com/orders/12345",
      "hash": "aB3xY9kQ",
      "redirectLink": "{{API_URL}}/aB3xY9kQ"
    },
    {
      "mainUrl": "https://www.example.com/orders/12346",
      "hash": "Zt7pLm2W",
      "redirectLink": "{{API_URL}}/Zt7pLm2W"
    }
  ]
}
```

:::

`data` keeps the order of `destinationLinks`. Unlike the single create endpoint, bulk creation does not reuse an existing link for a destination you have shortened before; every entry gets a new short code.

`redirectLink` is built on the host you sent the request to. If you use a custom domain, replace the host with your domain, for example `https://links.yourbrand.com/aB3xY9kQ`.

### Create Links in Bulk Example

```bash
curl -X POST "{{API_URL}}/v1/link-tracker/create-bulk" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "destinationLinks": [
      "https://www.example.com/orders/12345",
      "https://www.example.com/orders/12346"
    ],
    "hashLength": 8
  }'
```

---

:::api
method: GET
endpoint: /v1/link-tracker
title: List Links
description: List the tracked links in your account, newest first, one page at a time.

## Query Parameters

- limit: number - Page size. Default `100`, maximum `500`
- cursor: number - `nextCursor` from the previous page. Omit for the first page

## Response

```response
{
  "message": "Links successfully retrieved.",
  "data": {
    "links": [
      {
        "id": 98765,
        "hash": "aB3xY9kQ",
        "destinationLink": "https://www.example.com/offers/summer-sale",
        "redirectType": "static",
        "businessId": 12345,
        "messageWamid": null,
        "createdAt": "2026-09-09T08:15:42.000Z"
      },
      {
        "id": 98764,
        "hash": "Qw8eRt5yUi2o",
        "destinationLink": "https://www.example.com/orders/12345",
        "redirectType": "static",
        "businessId": 12345,
        "messageWamid": "wamid.HBgMOTE5ODc2NTQzMjEwFQIAERgSQzU...",
        "createdAt": "2026-09-08T14:02:10.000Z"
      }
    ],
    "nextCursor": 98764
  }
}
```

:::

Pages are ordered by creation, newest first. `nextCursor` is the id of the last link on the page; pass it back as `cursor` to fetch the next page, and stop when it is `null`. The list includes links created through this API and links generated automatically during template sends. API keys may call this endpoint 60 times per 15 minutes per business.

### List Links Example

```bash
curl -X GET "{{API_URL}}/v1/link-tracker?limit=100" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```bash
curl -X GET "{{API_URL}}/v1/link-tracker?limit=100&cursor=98764" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### List Response Fields

- `data.links[].id`: numeric identifier of the link
- `data.links[].hash`: the short code. Append it to your tracker domain to get the short URL
- `data.links[].destinationLink`: the URL the short link redirects to
- `data.links[].redirectType`: `static` or `dynamic`
- `data.links[].businessId`: your business ID
- `data.links[].messageWamid`: WhatsApp message ID of the template message the link was generated for, or `null` for links created through this API
- `data.links[].createdAt`: ISO 8601 creation time

> [!NOTE]
> The list does not include click counts. Per-link click analytics are available in the dashboard under **Integrations -> Link Tracker**. For template messages, clicks are also reflected in the message status and in campaign statistics as described above.

---

## Errors

| Status | When                                                                                                                                                             |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400    | `destinationLink` (or an entry in `destinationLinks`) is not a valid URL, `hashLength` is missing or not numeric, or `redirectType` is not `static` or `dynamic` |
| 401    | Missing, invalid, expired or revoked API key                                                                                                                     |
| 403    | The API key does not cover this endpoint. Use a Full access key, or a Read-only key for `GET /v1/link-tracker`                                                   |
| 409    | The generated short code already exists. Retry the request, or use a longer `hashLength`                                                                         |

Opening a short URL whose code does not exist returns `404`.
