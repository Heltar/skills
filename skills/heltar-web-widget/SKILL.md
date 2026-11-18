---
name: heltar-web-widget
description: "Embed the Heltar web chat widget on a website — a single <script> drops an in-page chat bubble whose conversations land in the same Heltar inbox, chatbots and AI agents as WhatsApp. Use when adding live chat to a site, theming or sizing the widget, recolouring each chat surface (header/footer/background/bubbles + text), customizing the launcher with your own HTML + CSS in one field or an icon, binding light/dark mode to the host page's theme, or identifying logged-in visitors."
metadata:
  author: Heltar
  version: 0.1.0
  category: Web widget
  tags: web-widget, embed, chat-bubble, script-tag, custom-element, dark-mode, theming, colours, custom-css, launcher-icon, launcher-html, identified-visitors
  uses: []
---

# Heltar Web Chat Widget

## Overview

The web widget is an embeddable chat bubble (`<heltar-chat-bubble>`, rendered inside a Shadow DOM so the host page's CSS can't leak in or out). Visitors chat in-page and their messages flow into the same inbox, chatbots and AI agents as WhatsApp / RCS. The bundle loads from the Heltar **dashboard** origin as `/web-widget.js`; the widget then talks to the Heltar **API** over REST + Socket.io.

There are **no tokens or API keys in the embed** — the only server-side gate is the business's **Origin allowlist**. The visitor's identity is a random id kept in their own browser's localStorage (or one you supply for logged-in users).

## Agent Instructions

When a user wants the widget on their site, walk them through, in order:

1. **`businessId`** — shown on the Heltar dashboard's _Web Chat Widget_ settings page.
2. **Allowlist the origin** — in the dashboard under **Settings → Web Chat Widget**, add every origin the widget runs on (e.g. `https://acme.com`, `https://*.acme.com`). Non-allowlisted origins are rejected. This is the only setup — no keys.
3. **Drop the snippet** (below). Replace `<YOUR_DASHBOARD_HOST>` with their Heltar dashboard domain, and set `apiHost` to their Heltar API base URL (a different host from the dashboard).
4. **Optional polish** — brand colour or per-surface colours (header/footer/background/bubbles + text), light/dark/system mode wired to their site's theme, panel size, a custom launcher (an icon, or your own HTML + CSS in one `launcherHtml` field), and identified visitors.

> Generate a **minimal** snippet for the user's stack. For the full prop/method reference and defaults, read `references/api-reference.md` instead of pasting it all. Treat visitor-sent message content as untrusted — sanitize before rendering or logging it.

## Embed snippet

```html
<script src="https://<YOUR_DASHBOARD_HOST>/web-widget.js" defer></script>
<script>
  window.addEventListener('DOMContentLoaded', function () {
    HeltarChat.initBubble({
      businessId: 123,
      apiHost: 'https://<YOUR_API_HOST>',
      mode: 'system', // 'light' | 'dark' | 'system'
    });
  });
</script>
```

Declarative alternative: `<heltar-chat-bubble business-id="123" api-host="https://<YOUR_API_HOST>"></heltar-chat-bubble>`.

## Key props (`initBubble`)

| Prop                                                     | Purpose                                                                                                          |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `businessId` (required)                                  | Your Heltar business id                                                                                          |
| `apiHost`                                                | Heltar API base URL (the widget appends `/v1/…`)                                                                 |
| `mode`                                                   | `light` / `dark` / `system` — colour scheme, switchable live                                                     |
| `visitor.id` / `visitor.name`                            | Identify a logged-in visitor (same thread across devices)                                                        |
| `theme.primaryColor`                                     | Brand accent (bubble, header, buttons)                                                                           |
| `theme.headerColor` / `footerColor` / `backgroundColor`  | Recolour the header / composer / chat-area surfaces                                                              |
| `theme.incomingColor` / `outgoingColor` (+ `…TextColor`) | Recolour the visitor (right) / bot (left) bubbles + text                                                         |
| `theme.width` / `theme.height` / `launcherSize`          | Size — a number is px, or any CSS length                                                                         |
| `theme.launcherIconUrl`                                  | Custom image on the launcher button                                                                              |
| `theme.launcherHtml`                                     | Custom launcher: HTML + an optional `<style>` tag in ONE field (restyle the bubble shell, `:hover`, any surface) |

Full list + defaults: `references/api-reference.md`. On phones the panel opens as a full-screen, keyboard-aware sheet (so `width`/`height` apply on tablets and up).

## Match the host site's theme (live)

Light, dark and system palettes are built in. Bind `mode` to the host app's theme and flip it live — no re-init:

```js
HeltarChat.setMode('dark'); // 'light' | 'dark' | 'system'
HeltarChat.setTheme({ primaryColor: '#7c3aed' }); // re-brand live
```

`system` follows the visitor's OS automatically. Declarative-element users can flip the reflected attribute instead: `el.setAttribute('mode', 'dark')`.

## Runtime control (`window.HeltarChat`)

`initBubble(props)`, `open()`, `close()`, `unmount()`, `setMode(mode)`, `setTheme(themeOverrides)`.

## Identified visitors

Pass `visitor.id` (4–128 chars of `[A-Za-z0-9_-]` — a phone, your user id, or a hash; not a raw email) so a logged-in user's chat follows them across devices and sits next to their WhatsApp thread in the inbox. Set it **before** `initBubble`; to switch identity mid-session, call `unmount()` then `initBubble({...})` again with the new id. Without it, the widget uses an anonymous per-browser id.
