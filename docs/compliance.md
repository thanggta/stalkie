# Compliance & Risk Register

Guideline text here was read verbatim from Apple's live guidelines page on 2026-08-08. Full
context in `docs/research-findings.md` §2.

**Re-verify before each submission.** Guidelines change; this file goes stale.

---

## 1. The rule that shapes the product

### Guideline 5.2.5 — Apple Products · **ASR & NR**

> "Don't create an app that appears confusingly similar to an existing Apple product, interface
> (e.g. Finder), app (such as the App Store, iTunes Store, or **Messages**) or advertising
> theme."

**ASR & NR** = App Store Removal *and* Developer Program Removal. Not a rejection you resubmit
past — an account-level risk.

This names the reference genre's core mechanic: a simulated iOS home screen containing a fake
iMessage-style thread.

**Our mitigation is structural, not cosmetic.** CARVE's shell is a forensic recovery
workstation. It resembles no Apple product, interface, or app. There is nothing to argue about
in review because there is no resemblance to assess.

> **The asymmetry to keep in mind:** the genre's standard workaround — inventing in-fiction
> brand names — mitigates 4.1(b), not 5.2.5. Under 5.2.5 the exposure *is* the simulated OS
> shell. Renaming the apps inside an iPhone lookalike would not have helped.

### Concrete design rules from 5.2.5

| Do | Don't |
|---|---|
| Desktop/workstation layout, own iconography | Any iOS home-screen grid with rounded-square icons |
| Own typography and color system | SF Pro / San Francisco, or a close imitation |
| Message threads styled as forensic output — monospace, timestamped rows | Green/blue speech bubbles in iMessage arrangement |
| Own status/chrome vocabulary | Any imitation of iOS status bar, Control Center, or lock screen |
| Name it a "device image", "recovery session" | Anything reading as "iPhone", "iOS", "Finder", "AirDrop" |

Apple emoji are also prohibited by 5.2.5 in apps and extensions — **ship our own glyph set or a
licensed open set, never the system emoji font, in any authored content.**

---

## 2. Guideline 4.1(b) — Copycats · **ASR & NR**

> "Submitting apps which impersonate other apps or services is considered a violation of the
> Developer Code of Conduct and may result in removal from the Apple Developer Program."

Applies to in-fiction apps and services appearing inside a case.

**Mitigation:** every brand appearing in content is invented. This is the shipped convention in
the genre (*Simulacra* used Jabbr for Twitter, Spark for Tinder, Surfer for a browser).

Enforced as **INV-6**: no real brand, logo, wordmark, or trademark in any shipped asset.
Reviewed per case before merge.

Also 4.1(c): cannot use another developer's icon, brand, or product name in our app icon or
name.

---

## 3. Guideline 4.3(b) — Spam

> "Don't submit apps that are indistinguishable from what's already widely available… we will
> not accept new submissions unless they offer a meaningfully different or improved experience.
> We may remove these apps from the App Store going forward if they are not updated, improved,
> or **do not attract customers**."

~18 near-identical titles shipped March–August 2026. The enumerated categories don't yet
include this genre, so enforcement is reviewer discretion **today** — but the cluster is
building Apple's case, and both reference apps have near-zero ratings, which is the literal
text of the removal condition.

**Mitigation — differentiation is the submission bar, not a marketing goal:**

| Every competitor | CARVE |
|---|---|
| Free exhaustive browsing | Constrained recovery under a cycle budget |
| No win condition | Filed verdict, scored on accuracy |
| Phone shell | Forensic workstation |
| Read everything | Never enough budget to see everything (INV-2) |

A **free, complete first case** is the strongest available answer here: a reviewer can play the
entire differentiated loop without paying.

---

## 4. Guideline 3.1.2 — Subscriptions

> "Apps may offer auto-renewable in-app purchase subscriptions, regardless of category on the
> App Store."

No severity marker on the heading. Weekly cadence is not per se non-compliant — 82% of gaming
subscriptions sold are weekly. **Risk lives in paywall presentation, not billing interval.**

**We avoid the surface entirely:** one-time IAP per case pack, no subscription (DR-5). This is
also the only pricing model with surviving validation in this genre.

Corollary rule: **never sell cycles.** Monetizing the resource that gates content is
pay-to-progress and walks straight into the "tricking users into subscribing / bait-and-switch"
territory 3.1.2 actually polices.

---

## 5. Guideline 3.3.2 — hot-updating content · `[OPEN]`

**Status: unresolved. Verify before building remote case delivery.**

Not established in research. The safe-side design rule holds regardless:

- Downloadable **content** — images, JSON, text — is ordinary
- Downloadable **logic** is where 3.3.2 bites

**Therefore unlock rules are declarative data with a fixed six-predicate grammar
(`docs/content-schema.md` §4), never an executable script.** This is INV-5. It's a schema
decision that cannot be cheaply reversed once cases are authored against it, which is why it's
locked now rather than later.

v1 ships case 1 in the binary. Remote delivery is a later decision gated on resolving this.

---

## 6. Age rating

Reference apps rate 12+ and 13+. This genre involves infidelity, deception, and implied crime.

Rate honestly at submission. Under-rating is its own rejection reason, and the content is what
it is — the premise is an investigation into someone's private life.

---

## 7. The constraint that overrides everything

**All fabricated personal content stays fictional-character-only.**

A version that ingests a real person's data — contacts, messages, photos, location — stops
being a narrative game and becomes the thing the reference apps' names merely suggest. That is a
categorically different and prohibited product.

Practical rules:
- No feature reads the device's real contacts, photos, messages, or location
- No feature accepts a phone number, email, or social handle to "look up"
- No case content is derived from a real identifiable person
- Faces in media are AI-generated, licensed-with-releases, or synthetic — never a real
  identifiable person without a release

There is no research finding that changes this and no product reason that would justify it.

---

## 8. Pre-submission checklist

Run before every submission.

- [ ] Re-read 5.2.5, 4.1, 4.3, 3.1.2 from Apple's live page — confirm text unchanged
- [ ] No screen resembles an Apple interface (§1 table)
- [ ] No Apple emoji anywhere, including authored content
- [ ] INV-6 asset review passed for every case in the build
- [ ] No real brand, logo, or wordmark in screenshots or the App Store listing
- [ ] Free first case complete and playable to a filed verdict without payment
- [ ] IAP is one-time unlock only; no cycle purchases exist anywhere in the build
- [ ] Age rating matches actual content
- [ ] No device-data permission requested that gameplay doesn't need
- [ ] Privacy nutrition label matches what the app actually collects
