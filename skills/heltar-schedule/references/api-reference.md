---
title: Schedule
description: Schedule messages, campaigns, and nudges
icon: Clock
order: 8
---

# Schedule API

Schedule messages, campaigns, and nudges. Schedule actions for future delivery or trigger chatbot follow-ups for contacts who haven't responded.

---

## Schedule Nudge

:::api
method: POST
endpoint: /v1/schedule/nudge
title: Schedule Nudge
description: Schedule a chatbot nudge for a specific contact. Any existing pending nudges for the same client and chatbot are automatically cancelled before the new one is created. If no chatbot is specified, the client's currently assigned chatbot is used — or one is selected automatically via weighted assignment.

## Body Parameters

- clientWaNumber: string [required] - Contact's WhatsApp number in international format (without +)
- delaySeconds: integer [required] - Seconds to wait before sending the nudge (min: 1, max: 10000000)
- chatbotId: string - UUID of a specific chatbot to use (overrides the client's current assignment)

```request
{
  "clientWaNumber": "919876543210",
  "delaySeconds": 300,
  "chatbotId": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Response

```response
{
  "code": "OK",
  "message": "Nudge scheduled successfully",
  "data": {
    "scheduleId": 42
  }
}
```

:::

---

## List Chatbot Nudges

:::api
method: GET
endpoint: /v1/schedule/nudges
title: List Chatbot Nudges
description: Get all scheduled chatbot nudges for your business.

## Response

```response
{
  "code": "OK",
  "message": "Success",
  "data": [
    {
      "id": 42,
      "identifier": "550e8400-e29b-41d4-a716-446655440000_919876543210",
      "status": "schedule",
      "scheduleTime": "2025-01-15T10:05:00Z",
      "payload": {
        "followUpType": "manual",
        "followUpNumber": 1,
        "followUpTime": "300 seconds",
        "followUpReplied": false,
        "followUpRepliedAt": null
      }
    }
  ]
}
```

:::

---

## Schedule Message

:::api
method: POST
endpoint: /v1/schedule/message
title: Schedule Message
description: Schedule one or more messages to be sent at a future time.

## Body Parameters

- messages: array [required] - Array of messages to send (same format as the Send Messages API)
- scheduleTime: number [required] - Unix timestamp for when to send (must be in the future, within 2 years)

```request
{
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "messageType": "text",
      "message": "Hi! Just following up on your order."
    }
  ],
  "scheduleTime": 1735689600
}
```

## Response

```response
{
  "code": "OK",
  "message": "Successfully scheduled messages!",
  "data": {
    "id": 42,
    "scheduleType": "message",
    "status": "schedule",
    "scheduleTime": "2025-01-01T00:00:00Z"
  }
}
```

:::

---

## Schedule Campaign

:::api
method: POST
endpoint: /v1/schedule/campaign
title: Schedule Campaign
description: Schedule a bulk template message campaign to be sent at a future time.

## Body Parameters

- campaignName: string [required] - Campaign name for identification
- templateName: string [required] - Approved template name to use
- languageCode: string [required] - Template language code
- messages: array [required] - Array of recipients with personalized variables
- scheduleTime: number [required] - Unix timestamp for when to send (must be in the future, within 2 years)
- campaignDesc: string - Campaign description

```request
{
  "campaignName": "New Year Sale",
  "templateName": "promo_template",
  "languageCode": "en",
  "messages": [
    {
      "clientWaNumber": "919876543210",
      "variables": [{ "type": "text", "text": "John" }]
    }
  ],
  "scheduleTime": 1735689600
}
```

## Response

```response
{
  "code": "OK",
  "message": "Successfully schedule campaign - New Year Sale!",
  "data": {
    "campaign": {
      "id": 42,
      "name": "New Year Sale",
      "status": "schedule",
      "templateName": "promo_template",
      "statsTotal": 1,
      "statsSent": 0,
      "statsDelivered": 0,
      "statsRead": 0,
      "statsFailure": 0,
      "createdAt": "2025-01-15T10:00:00Z",
      "scheduleTime": "2025-01-01T00:00:00Z"
    }
  }
}
```

:::

---

## Delete Schedule

:::api
method: DELETE
endpoint: /v1/schedule/:id
title: Delete Schedule
description: Cancel a scheduled action (nudge, message, or campaign) by its ID.

## Path Parameters

- id: string [required] - Schedule ID

## Response

```response
{
  "code": "OK",
  "message": "Schedule deleted successfully"
}
```

:::

---

## Nudge Behavior

| Scenario                          | What happens                                                                              |
| --------------------------------- | ----------------------------------------------------------------------------------------- |
| Client has assigned chatbot       | Existing pending nudges for that chatbot are cancelled, new nudge is scheduled            |
| `chatbotId` provided in request   | Client's assigned chatbot is updated, then nudge is scheduled with the new chatbot        |
| No chatbot assigned or provided   | A chatbot is auto-selected via weighted assignment, client is updated, nudge is scheduled |
| Client replies before nudge fires | The nudge is marked as replied (handled internally by webhook)                            |

> [!TIP]
> Use `delaySeconds` strategically — short delays (60-300s) work well for active conversations, while longer delays (hours/days) suit re-engagement flows.
