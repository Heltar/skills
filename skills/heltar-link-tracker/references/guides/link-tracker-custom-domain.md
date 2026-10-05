---
title: Custom Domain for Link Tracker
description: Set up your own branded domain for shortened, trackable links in template messages
icon: Link
order: 3
---

# Custom Domain for Link Tracker

By default, shortened links in your template messages use Heltar's domain (e.g. `https://api.heltar.com/aB3xY9`). With a custom domain, your links carry your own brand instead:

```
https://links.yourbrand.com/aB3xY9
```

Branded links look more trustworthy to your customers, which typically improves click-through rates.

Setting this up is a short back-and-forth between you and the Heltar team. This guide walks through the whole process — what you need to prepare, what we'll send you, and the DNS mistakes to avoid so it works on the first try.

---

## How the Process Works

| Step | Who    | What happens                                                                  |
| ---- | ------ | ----------------------------------------------------------------------------- |
| 1    | You    | Choose a subdomain and send it to us                                          |
| 2    | Heltar | We send you one CNAME record (Name + Value) for the TLS certificate           |
| 3    | You    | Add that CNAME record in your DNS                                             |
| 4    | Heltar | We confirm the certificate is issued and send you the Heltar endpoint address |
| 5    | You    | Point your subdomain to that address with a second CNAME record               |
| 6    | You    | Register the domain in the Heltar dashboard and start using it in templates   |

End to end this usually takes less than a day. The longest waits are DNS propagation (minutes to a few hours) and certificate issuance (usually under an hour once the record is correct).

---

## Before You Start

**1. Choose a subdomain — not your main domain.**

Pick a dedicated subdomain that isn't used for anything else, for example:

- `links.yourbrand.com`
- `go.yourbrand.com`
- `wa.yourbrand.com`

Why a subdomain?

- The setup points the **entire hostname** at Heltar. Your main domain (`yourbrand.com`) already serves your website, so it can't be used.
- Root domains technically can't have CNAME records (a DNS standard limitation), and this setup requires CNAMEs.
- A dedicated subdomain means **zero impact** on your website, email, or anything else on your domain.

**2. Make sure the subdomain is unused.**

The subdomain must not already have any DNS records (A, AAAA, or CNAME). If it currently points somewhere, pick a different name.

**3. Know who manages your DNS.**

You'll need to add two DNS records during this process. Make sure you (or your IT/dev team) can log in to wherever your domain's DNS is managed — GoDaddy, Cloudflare, Namecheap, Route 53, your hosting provider, etc.

---

## Step 1: Send Us Your Subdomain

Email or message your Heltar point of contact (or [support@heltar.com](mailto:support@heltar.com)) with the subdomain you've chosen, e.g.:

> "We'd like to set up `links.yourbrand.com` as our custom link tracker domain."

---

## Step 2: Add the Certificate Verification Record

We'll reply with **one CNAME record** that proves you control the domain, so a TLS certificate can be issued for it (this is what makes your links load over `https://` with a valid padlock). It will look something like:

| Field     | Example value                                           |
| --------- | ------------------------------------------------------- |
| **Type**  | CNAME                                                   |
| **Name**  | `_3f9a2b1c8d7e6f5a.links.yourbrand.com`                 |
| **Value** | `_9x8y7z6w5v4u3t2s.xyzvalidations.acm-validations.aws.` |

Add this record in your DNS provider's dashboard, then let us know it's done.

> [!IMPORTANT]
> **Do not delete this record after setup is complete.** The certificate renews automatically every year, and renewal re-checks this same record. If it's removed, your links will eventually break with a certificate error.

### Common Mistakes to Avoid

These cause almost all setup delays. Please double-check each one:

**1. Duplicating your domain in the Name field.**
Most DNS providers (GoDaddy, Namecheap, Hostinger, etc.) automatically append your domain to whatever you type in the Name field. If we send you the name `_3f9a2b1c8d7e6f5a.links.yourbrand.com`, you usually need to enter only:

```
_3f9a2b1c8d7e6f5a.links
```

If you paste the full name, the record becomes `_3f9a2b1c8d7e6f5a.links.yourbrand.com.yourbrand.com` — which fails silently. (Exception: some providers like AWS Route 53 do want the full name.) **After saving, check that the displayed record matches exactly the Name we sent — no more, no less.**

**2. Cloudflare users: turn the proxy OFF for these records.**
If your DNS is on Cloudflare, the record must be **DNS only** (grey cloud ☁️), not **Proxied** (orange cloud 🟠). Click the cloud icon to toggle it. A proxied record hides the real value and blocks both certificate verification and the final link setup.

**3. Wrong record type.**
It must be a **CNAME** record — not TXT, not A. If your provider asks for an IP address, you've selected the wrong type.

**4. Copy-paste errors.**
Copy the Name and Value exactly as we send them — watch out for trailing spaces, missing characters, or your email client breaking the value across lines. If your DNS provider rejects the trailing dot (`.`) at the end of the Value, it's safe to remove just that final dot.

**5. Not waiting for propagation.**
DNS changes take anywhere from a few minutes to a few hours to become visible (rarely up to 24–48 hours, depending on your provider). You can check whether your record is live at [dnschecker.org](https://dnschecker.org) — select **CNAME**, enter the record Name, and verify the Value we sent shows up.

Once the record is visible, the certificate is typically issued within the hour. We'll confirm when it's done.

---

## Step 3: Point Your Subdomain to Heltar

After the certificate is issued, we'll send you the **Heltar endpoint address** — it looks something like:

```
heltar-xxxxxxxxx.ap-south-1.elb.amazonaws.com
```

Add a second CNAME record pointing your subdomain to it:

| Field     | Example value                                         |
| --------- | ----------------------------------------------------- |
| **Type**  | CNAME                                                 |
| **Name**  | `links.yourbrand.com` (often entered as just `links`) |
| **Value** | the endpoint address we sent you                      |

The same mistakes from Step 2 apply here — especially the domain-duplication and Cloudflare proxy issues. Two extra ones for this step:

**1. Don't use your provider's "forwarding" or "redirect" feature.**
Many registrars offer "Domain Forwarding" or "URL Redirect" — that is **not** the same as a CNAME record and will not work. It must be a plain CNAME DNS record.

**2. Don't point it anywhere else.**
The subdomain should have exactly one record: the CNAME to the Heltar endpoint. Remove any other A/AAAA/CNAME records on that same subdomain if your provider allowed you to create them.

Let us know once the record is added. We'll verify that `https://links.yourbrand.com` resolves correctly with a valid certificate.

---

## Step 4: Register the Domain in Heltar

Once we confirm everything resolves:

1. In the Heltar dashboard, go to **Settings → Template Link Tracker**
2. Make sure the link tracking toggle is **ON**
3. Enter your full domain with `https://` — e.g. `https://links.yourbrand.com`
4. Click **Register Domain**

From now on, when you create a template with a URL button, the URL Type dropdown will show a **Custom domain URL link tracker** option. Select it and your shortened, trackable links will use your branded domain.

See [Template Link Tracker](/docs/features/settings/communication#template-link-tracker) for how link tracking and click analytics work in general.

---

## Verify It Works

Send yourself a test template that uses the custom domain link tracker and check that:

- The link in the message starts with `https://links.yourbrand.com/`
- Tapping it opens the destination page with no certificate warning
- The click appears in your link analytics (**Integrations → Link Tracker**)

---

## FAQ

**Will this affect my website or email?**
No. Only the specific subdomain you chose points to Heltar. Everything else on your domain is untouched.

**Can I use my root domain (`yourbrand.com`)?**
No — it already serves your website, and root domains can't have CNAME records. Use a subdomain.

**Can I change the domain later?**
Yes — the same process runs again for the new subdomain. Contact support.

**The certificate was issued — can I delete the verification record now?**
No. Keep both CNAME records permanently. The verification record is re-checked automatically at every certificate renewal; deleting it will break your links months later.

**How long until my links work?**
Typically the same day. The pacing depends on how quickly the DNS records are added correctly and propagate.
