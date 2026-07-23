---
title: Web chat widget
description: Embed the HeltarChat chat widget on your website
icon: MessageSquare
order: 10
---

# Web chat widget

Paste one `<script>` on your site and visitors get an in-page chat that lands in your HeltarChat inbox — same AI agents and chatbots as WhatsApp. History persists per device, grouped by day like WhatsApp Web.

---

## 1. Allowlist your domain

In **Settings → Web Chat Widget**, add every domain you'll embed on:

```
https://yoursite.com
https://*.yoursite.com
```

Wildcard (`*.`) covers subdomains. HTTPS only.

## 2. Paste the snippet

Your settings page shows this snippet **pre-filled** with your exact values — copy it from there. It looks like:

```html
<script src="{{DASHBOARD_URL}}/web-widget.js" defer></script>
<script>
  window.addEventListener('DOMContentLoaded', function () {
    HeltarChat.initBubble({
      businessId: <YOUR_BUSINESS_ID>,
      apiHost: '{{API_URL}}',
      theme: {
        primaryColor: '#008069',
        headerTitle: 'Acme Support',
        headerSubtitle: 'We typically reply in 5 minutes',
        welcomeMessage: 'Hi! Ask us anything.',
      },
    });
  });
</script>
```

The two hosts are filled in automatically with your account's values — both are served for you; you host neither:

- `{{DASHBOARD_URL}}` — the dashboard that serves the script bundle. This is where `/web-widget.js` lives.
- `{{API_URL}}` — the API the widget talks to. Usually a **different** host from the dashboard.

The floating bubble appears in the bottom-right corner.

## 3. Test it

Open the page, click the bubble, send a message. It should appear in your HeltarChat inbox. Agent / AI replies show up in the panel in real time.

---

## Configuration

| Field                     | Type                | Default      | Notes                                                                                                                                                                                                                                          |
| ------------------------- | ------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `businessId`              | `number`            | —            | **Required.** From your settings page                                                                                                                                                                                                          |
| `apiHost`                 | `string`            | same origin  | Base URL of the HeltarChat API                                                                                                                                                                                                                 |
| `mode`                    | `string`            | `light`      | Colour scheme — `light`, `dark`, or `system` (follows the visitor's OS). Switchable live, see below                                                                                                                                            |
| `autoShowDelay`           | `number` ms         | —            | Auto-open the panel N ms after page-load                                                                                                                                                                                                       |
| `dynamicPrompt`           | `string`            | —            | Per-visitor context appended to your chatbot's system prompt on every AI reply (e.g. "Visitor is on the pricing page, premium tier"). Set it from your app; it's framed as background info, not as instructions that override the bot's rules. |
| `visitor.id`              | `string`            | —            | Identify the visitor from your own auth (phone, user id) — see "Identified visitors" below                                                                                                                                                     |
| `visitor.name`            | `string`            | —            | Display name shown to agents in the inbox                                                                                                                                                                                                      |
| `theme.primaryColor`      | `string`            | `#008069`    | Brand colour (bubble, header, send + reply buttons)                                                                                                                                                                                            |
| `theme.headerTitle`       | `string`            | `Chat`       | Chat header title                                                                                                                                                                                                                              |
| `theme.headerSubtitle`    | `string`            | —            | One-line subtitle                                                                                                                                                                                                                              |
| `theme.avatarUrl`         | `string`            | —            | Square ~40px header icon                                                                                                                                                                                                                       |
| `theme.welcomeMessage`    | `string`            | —            | Shown when there's no prior chat                                                                                                                                                                                                               |
| `theme.placement`         | `string`            | `right`      | Bubble position — `left` or `right`                                                                                                                                                                                                            |
| `theme.width`             | `number` / `string` | `380px`      | Chat panel width — a number is px, or any CSS length (`32rem`, `90vw`)                                                                                                                                                                         |
| `theme.height`            | `number` / `string` | `620px`      | Chat panel height — a number is px, or any CSS length                                                                                                                                                                                          |
| `theme.launcherSize`      | `number` / `string` | `56px`       | Size of the floating bubble button                                                                                                                                                                                                             |
| `theme.launcherIconUrl`   | `string`            | —            | Custom image on the launcher button (replaces the default chat icon)                                                                                                                                                                           |
| `theme.launcherHtml`      | `string`            | —            | Your launcher's HTML **and** CSS in one field — markup + an optional `<style>` tag (restyle the bubble, `:hover`, any surface — see below)                                                                                                     |
| `theme.headerColor`       | `string`            | primaryColor | Chat header background                                                                                                                                                                                                                         |
| `theme.headerTextColor`   | `string`            | white        | Header title / subtitle / close-icon colour                                                                                                                                                                                                    |
| `theme.footerColor`       | `string`            | —            | Composer (footer) bar background                                                                                                                                                                                                               |
| `theme.backgroundColor`   | `string`            | —            | Chat message-area background                                                                                                                                                                                                                   |
| `theme.incomingColor`     | `string`            | —            | Visitor's own (right-side) message-bubble colour                                                                                                                                                                                               |
| `theme.incomingTextColor` | `string`            | —            | Text colour inside the visitor's (right) bubbles                                                                                                                                                                                               |
| `theme.outgoingColor`     | `string`            | —            | Your / the bot's (left-side) message-bubble colour                                                                                                                                                                                             |
| `theme.outgoingTextColor` | `string`            | —            | Text colour inside the bot's (left) bubbles                                                                                                                                                                                                    |

## Customize the look

Everything below is optional — pass only what you want to change. Colours,
size and the launcher icon are all set through `theme`:

```html
<script src="{{DASHBOARD_URL}}/web-widget.js" defer></script>
<script>
  window.addEventListener('DOMContentLoaded', function () {
    HeltarChat.initBubble({
      businessId: 123,
      apiHost: '{{API_URL}}',
      mode: 'system', // 'light' | 'dark' | 'system'
      theme: {
        primaryColor: '#7c3aed', // brand accent (bubble, header, buttons)
        headerTitle: 'Acme Support',
        headerSubtitle: 'We typically reply in 5 minutes',
        welcomeMessage: 'Hi! Ask us anything.',
        avatarUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnRfT7addaMdH-yhhxl0fzpt4RxBO-rqz-Rbdt0mB-fg&s', // header avatar
        placement: 'right', // 'left' | 'right'

        // ── size ──
        width: 420, // panel width — a number is px…
        height: '80vh', // …or any CSS length
        launcherSize: 64, // floating bubble button

        // ── launcher icon ──
        launcherIconUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnRfT7addaMdH-yhhxl0fzpt4RxBO-rqz-Rbdt0mB-fg&s',
      },
    });
  });
</script>
```

Sizes accept a bare number (treated as pixels) or any CSS length string
(`'32rem'`, `'90vw'`). On **phones** the panel ignores `width`/`height` and
opens as a **full-screen sheet** sized to the visible area — so the on-screen
keyboard never hides the composer and a large desktop size never overflows a
small screen. The floating panel + your `width`/`height` apply on tablets and up.

## Colours & full styling control

`primaryColor` is the quickest way to brand the widget, but you can recolour
each surface of the chat independently, and fully reshape the launcher.

### Per-surface colours

```js
HeltarChat.initBubble({
  businessId: 123,
  apiHost: '{{API_URL}}',
  theme: {
    headerColor: '#1f2937', // chat header background (defaults to primaryColor)
    headerTextColor: '#f9fafb', // header title / subtitle / close
    backgroundColor: '#0f172a', // chat message area
    footerColor: '#111827', // composer / footer bar
    incomingColor: '#2563eb', // the visitor's own (right) bubbles
    incomingTextColor: '#ffffff',
    outgoingColor: '#1e293b', // your / the bot's (left) bubbles
    outgoingTextColor: '#e2e8f0',
  },
});
```

> Set a bubble's **background and its text colour together**. If you set only
> the background, the text keeps the palette default and may not contrast —
> especially under `mode: 'dark'` / `'system'`.

### Launcher: your own HTML + CSS (one field)

The floating bubble is fully customizable through a single `launcherHtml` field —
put your markup **and** a `<style>` tag in it. Because it's injected into the
widget's own Shadow DOM, that `<style>` can do what inline styles can't: restyle
the bubble shell itself (shape, colour, size, shadow), add `:hover` / animations,
and even style the rest of the widget (`.hcw-panel`, the `--hcw-*` vars …):

```js
theme: {
  launcherHtml: `
    <style>
      .hcw-bubble-btn { background: #ff5722; border-radius: 50%; }
      .hcw-bubble-btn:hover { transform: scale(1.08); }
    </style>
    <span style="font-size:24px">💬</span>
  `,
}
```

The `<style>` is scoped to the widget — it can't leak onto your page, and your
page's CSS can't reach in. Leave `launcherHtml` empty for the default bubble.

## Light / dark mode

The widget has built-in light, dark and system palettes. Pick one with `mode`, and it follows your site **live** — no reload:

```js
// follow the visitor's OS setting
HeltarChat.initBubble({ businessId: 123, mode: 'system' });

// or bind it to your own light/dark toggle
HeltarChat.setMode('dark'); // 'light' | 'dark' | 'system'
```

If you use the declarative element, flip the attribute instead and the widget re-paints:

```js
document.querySelector('heltar-chat-bubble').setAttribute('mode', 'dark');
```

`theme.primaryColor` re-brands the accent colour in both palettes; `HeltarChat.setTheme({ primaryColor: '#7c3aed' })` changes it live.

## Greet visitors first (optional)

By default the bot only replies after the visitor writes. To have it **open the
conversation itself**, turn on **Bot Sends First Message** in your chatbot's
settings (Playground → Advanced). Then, when a first-time visitor opens the
widget, the bot sends an AI-generated greeting right away — no visitor message
needed.

It fires once, and only when the visitor has **no prior conversation**, so it
never interrupts an ongoing chat or repeats on reload. This is the web chat
widget only — WhatsApp threads are unaffected (there the customer must message
first).

## Trigger the chat from your site (not just the icon)

The floating icon isn't the only way in — your site can open the chat itself,
from any button or page event. Everything below works with the standard
snippet; no extra setup on the HeltarChat side.

### Open the chat from your own button

Add `onclick="HeltarChat.open()"` to any element on your page:

```html
<button onclick="HeltarChat.open()">Chat with us</button>
```

Clicking it opens the chat panel exactly like a click on the floating icon —
same conversation, same chatbot. `HeltarChat.close()` collapses it (the ✕ in
the panel header and the Esc key already work, so you rarely need it).

You can also call `open()` from any JavaScript event — a timer, a scroll
position, a specific page, exit intent:

```js
// e.g. open automatically after 5 seconds on the pricing page
setTimeout(() => HeltarChat.open(), 5000);
```

The only rule: call `HeltarChat.open()` **after** the widget script has loaded
and your `initBubble` snippet has run. A button `onclick` is always safe —
by the time a visitor can click, the widget is ready.

### Hide the floating pill — your button as the only launcher

If your own button should be the _only_ way in, hide the default floating
launcher with two theme fields in your existing snippet:

```html
<script src="{{DASHBOARD_URL}}/web-widget.js" defer></script>
<script>
  window.addEventListener('DOMContentLoaded', function () {
    HeltarChat.initBubble({
      businessId: <YOUR_BUSINESS_ID>,
      apiHost: '{{API_URL}}',
      theme: {
        // Hides the floating pill — your own button is the only launcher.
        launcherHtml: '<style>.hcw-bubble-btn{display:none}</style>',
        launcherSize: 0,
      },
    });
  });
</script>

<button onclick="HeltarChat.open()">Chat with us</button>
```

With this, the widget has no visible footprint until `open()` is called — no
pill, no bubble. Visitors close the panel with the ✕ in its header (or Esc),
and if they reload mid-conversation the panel reopens where they left off.

### Open automatically after N seconds

No code needed — set `autoShowDelay` (milliseconds) in your snippet and the
panel opens by itself after page load:

```js
HeltarChat.initBubble({
  businessId: <YOUR_BUSINESS_ID>,
  apiHost: '{{API_URL}}',
  autoShowDelay: 3000, // opens 3s after page load
});
```

### Have the bot speak first

Turn on **Bot Sends First Message** in your chatbot's settings (Playground →
Advanced), as described in "Greet visitors first" above. The greeting fires
whenever the panel opens — via the icon, your button, `open()`, or
`autoShowDelay` — so the visitor is welcomed without typing anything.

### Testing checklist

- Click your button → the panel opens; send a message → it appears in your
  HeltarChat inbox.
- The bot's first message goes only to **new visitors** (no prior
  conversation). Test the greeting in a fresh incognito window each time —
  otherwise it can look like it isn't firing.
- Test from a page served on an allowlisted domain (see "Allowlist your
  domain" above). Opening the HTML directly from disk (`file://`) won't work.

## Identified visitors (recommended for logged-in users)

If your site already knows the visitor (logged-in user, a phone you've verified, an internal user id, …), pass that identity to the widget. Agents will find the **same conversation across the visitor's devices and channels** — no surprise duplicate threads.

```js
HeltarChat.initBubble({
  businessId: 123,
  apiHost: '{{API_URL}}',
  visitor: {
    id: '919876543210', // a phone number, user id, or any stable identifier
    name: 'John Doe',
  },
});
```

What happens under the hood:

- The visitor's chats are saved against `<your-id>@web` (e.g. `919876543210@web`) instead of an anonymous random id.
- The same `visitor.id` from a different device → same conversation thread.
- Agents searching the inbox by phone / user id will find the chat instantly.

**Format constraints on `visitor.id`:**

- 4 – 128 characters
- Only `[A-Za-z0-9_-]` (letters, digits, underscore, hyphen)
- Phone numbers and UUIDs satisfy this; emails (because of `@` and `.`) do **not** — hash them first or use your own user id

**When to set it:**

Set `visitor.id` **before** calling `initBubble`. If you change it later in the page session, the widget won't switch threads automatically — call `HeltarChat.unmount()` then `HeltarChat.initBubble({...})` again with the new id.

> If your `visitor.id` is predictable (a sequential user id, a phone, an email), enable **identity verification** (see the section below) so another visitor can't load that conversation by guessing the id.

## Runtime control (`window.HeltarChat`)

After the script loads, drive the widget from your own UI:

| Method               | What it does                                                           |
| -------------------- | ---------------------------------------------------------------------- |
| `initBubble(props)`  | Mount the widget (see Configuration). Call once.                       |
| `open()` / `close()` | Expand / collapse the chat panel.                                      |
| `unmount()`          | Remove the widget entirely.                                            |
| `setMode(mode)`      | Switch between `light`, `dark` and `system` **live** — no re-init.     |
| `setTheme(theme)`    | Merge theme overrides (colour, size, icon, …) into the running widget. |

```js
HeltarChat.open(); // expand the panel
HeltarChat.close(); // collapse
HeltarChat.unmount(); // remove the widget

HeltarChat.setMode('dark'); // flip the colour scheme live
HeltarChat.setTheme({ primaryColor: '#7c3aed' }); // re-brand live
```

```html
<button onclick="HeltarChat.open()">Chat with us</button>
```

## Embed methods

| Method                       | Snippet                                                                                                                          |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Script tag** (most common) | `<script src=".../web-widget.js"></script>` + `HeltarChat.initBubble({...})`                                                     |
| **Declarative element**      | `<heltar-chat-bubble business-id="123" api-host="..."></heltar-chat-bubble>`                                                     |
| **Self-host the bundle**     | Build `dist/web.js` from the [web-widget repo](https://github.com/Heltar/web-widget) and serve it from your own host — see below |

### Self-host the bundle

By default the widget loads from your Heltar dashboard at `/web-widget.js`. To serve it yourself instead, build it from the public repo and host the output:

```bash
git clone https://github.com/Heltar/web-widget.git
cd web-widget && npm install && npm run build   # → dist/web.js
```

Host `dist/web.js` on your own CDN and point your `<script src>` at it. Self-hosting only changes where the _script_ is served from — `apiHost` must still point at the Heltar API, and the page's origin must still be allowlisted under **Settings → Web Chat Widget**.

---

## Visitor identity & history

The widget assigns a unique ID to each visitor and stores it in their browser's first-party storage. When the same device returns, the conversation history loads automatically — Safari ITP, Brave, and Chrome's third-party-cookie phaseout don't affect it.

Clearing the visitor's browser data starts a new thread.

## Security

- **Origin allowlist** — every request must come from a domain you've added in settings. All others are rejected.
- **Visitor identity is browser-local** — each visitor gets a random id stored only in their own browser's first-party storage; it never leaves their device except in requests from THEIR widget.
- **Disable instantly** — clear all domains in **Settings → Web Chat Widget** to disable the widget for every visitor immediately. No new visitor can connect; existing ones get cut off on their next request.

---

## Identity verification

Optional. By default a `visitor.id` you pass is trusted as-is — fine for opaque ids, but if the id is **predictable** (a sequential user id, an email, a phone number) anyone who guesses it could load that visitor's chat. Identity verification closes that gap: your server signs each id with a shared secret, the widget sends the signature, and HeltarChat rejects any id without a valid one. Same model as Intercom's "Identity Verification" — and anonymous visitors are never affected.

**Step 1 — Turn it on & get your secret.** In **Settings → Web Chat Widget → Identity verification**, click **Generate secret** (or paste your own — **minimum 32 characters**; Generate creates a strong 64-char one), copy it, and **Save**. Store it on your **server** (an environment variable) — never in client-side code.

**Step 2 — Sign the visitor id on your server.** Compute `HMAC-SHA256(visitorId, secret)`, hex-encoded, on each page render — never expose the secret to the browser:

```js
// Node.js
import { createHmac } from 'crypto';

const visitorHash = createHmac('sha256', process.env.HELTAR_WIDGET_SECRET)
  .update(visitorId) // the exact string you pass as visitor.id
  .digest('hex');
```

```python
# Python
import hmac, hashlib

visitor_hash = hmac.new(
    HELTAR_WIDGET_SECRET.encode(),
    visitor_id.encode(),
    hashlib.sha256,
).hexdigest()
```

```php
// PHP
$visitorHash = hash_hmac('sha256', $visitorId, $HELTAR_WIDGET_SECRET);
```

**Step 3 — Pass the id and its signature to the widget.**

```js
HeltarChat.initBubble({
  businessId: 123,
  apiHost: '{{API_URL}}',
  visitor: {
    id: 'user_8821', // must be the SAME string you signed
    name: 'John Doe',
    hash: serverComputedHash, // the value from Step 2
  },
});
```

The `id` you sign and the `id` you pass must match byte-for-byte — a signature is bound to one id and can't be reused for another.

**What gets rejected:**

| Request                               | Verification ON | Verification OFF |
| ------------------------------------- | --------------- | ---------------- |
| Anonymous visitor (no `visitor.id`)   | ✅ allowed      | ✅ allowed       |
| `visitor.id` + valid `hash`           | ✅ allowed      | ✅ allowed       |
| `visitor.id` + missing / wrong `hash` | ❌ rejected     | ✅ allowed       |

> Any stable identifier works — UUIDs, `user_<id>`, phone numbers. Just don't start ids with `wv_`: that prefix is reserved for the widget's own anonymous visitors.

**Turning it off.** Open the same settings and click **Disable** — the secret is removed and verification stops immediately (anonymous visitors keep working, and any `visitor.id` is accepted without a signature). Re-enabling generates a new secret, which invalidates the old one, so update your server too.

---

## Troubleshooting

| Symptom                             | Fix                                                                                                                               |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Bubble never appears                | Snippet running before `defer`-loaded script finished — wrap in `DOMContentLoaded`                                                |
| Requests rejected (403)             | The page's origin isn't in your allowlist (Step 1)                                                                                |
| Chat works, history doesn't persist | Visitor's browser is blocking storage (Safari Private mode, embedded webview). Expected — chat works for the current session only |
| AI agent doesn't reply              | Same setup as WhatsApp — enable your AI agent / chatbot for this business in their respective settings                            |

---

## Supported today

Text messages, images & files with captions, quick-reply buttons and list menus, identified visitors (cross-device history), realtime delivery, and read receipts all work — the web channel flows through the same inbox, chatbots and AI agents as WhatsApp.
