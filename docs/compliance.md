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

> ## ⚠ 1.1 — SUPERSEDED ON 2026-08-12. READ THIS BEFORE THE REST OF §1.
>
> **The mitigation described below was deliberately abandoned by the project owner.** The shell
> is now an iOS lookalike: home-screen grid with rounded-square icons, system font, iOS status
> bar, iMessage-style bubbles. That is the exact configuration 5.2.5 names.
>
> **This is an accepted risk, not an oversight.** The owner was shown the severity — App Store
> Removal *and* Apple Developer Program Removal, an account-level loss rather than a
> resubmittable rejection — and the asymmetry below (that inventing in-fiction brand names
> mitigates 4.1(b), not 5.2.5) and chose to proceed. Recorded as DR-8 in the design spec.
>
> **The analysis in the rest of §1 remains factually accurate and is retained deliberately.**
> It is the record of what the risk is. Do not delete it to make the decision look better.
>
> **What still binds, and is not covered by the accepted risk:**
> - **Apple's own artwork is never shipped.** No copied icon files, logos, wordmarks, or glyph
>   artwork. That is copyright and 4.1(c), a distinct and worse exposure. All assets original.
> - **The visual language ships as a swappable theme layer** — fonts, geometry, radii, icon
>   shapes and status-bar layout as data, so a reviewer flag costs a reskin, not a rewrite.
>   This is the entire retreat plan; if it is not built, there is no retreat.
> - **INV-6** — narrowed later the same day by DR-12 (§2.1): real *platform* brands are now
>   permitted as in-game apps. Everything else still holds: no other real brand or trademark
>   ships, no third party's actual asset files are bundled, and every person stays fictional.
>
> **Re-verify 5.2.5's live text before every submission.** With this shell, that checklist item
> stops being routine and becomes the highest-value line in §8.

**The original mitigation, now abandoned — structural, not cosmetic.** CARVE's shell was to be a
forensic recovery workstation. It would resemble no Apple product, interface, or app. There
would be nothing to argue about in review because there would be no resemblance to assess.

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

> ## ⚠ 2.1 — SUPERSEDED ON 2026-08-12 (DR-12). READ BEFORE THE REST OF §2.
>
> **The mitigation below was deliberately abandoned.** In-game apps now carry **real brand
> names** — Instagram, Snapchat, Google Maps and similar — because realism is the experience
> being sold. `docs/research-findings.md` §2 records that 4.1(b) explicitly covers
> "in-game WhatsApp/Instagram/TikTok lookalikes" at **ASR & NR** severity, and the owner was
> shown that before deciding. Recorded as DR-12.
>
> **This is the project's SECOND account-removal trigger,** stacked on the 5.2.5 one accepted
> in DR-8. They are independent: fixing one does not fix the other. Unlike 5.2.5, this one is
> visible in App Store screenshots, so the realistic failure mode is **rejection at review**
> rather than removal later.
>
> **One thing the research says in the owner's favour, recorded honestly:**
> `research-findings.md` line 164 notes invented brands are "evidence of *convention*, not of
> legal necessity" — no source established that real brands are legally required to be avoided
> here. The 4.1(b) exposure is verified; the trademark-law exposure is genuinely unestablished.
>
> **What still binds and is NOT covered by DR-12:**
> - **Never ship another company's actual asset files.** Icons, logos and wordmarks are drawn
>   originally, even when they are drawn to be recognisable. Reproducing a mark is the
>   trademark risk that was accepted; shipping Meta's or Snap's PNG adds a separate and clean
>   **copyright** claim on top, for no extra realism. Free to avoid — so avoid it.
> - **Fictional people, always.** Real brands do not license real people. Every character,
>   handle, number and photo subject stays invented (CLAUDE.md rule 6).
> - **Keep brand strings in one place.** Names live in a single config, never scattered through
>   views or case JSON, so reverting to invented names is a config change and not a rewrite.
>   This is the same retreat mechanism as the DR-8 theme layer, and it is worth as much.

**The original mitigation, now abandoned:** every brand appearing in content is invented. This
is the shipped convention in the genre (*Simulacra* used Jabbr for Twitter, Spark for Tinder,
Surfer for a browser), and no shipped title in the cluster uses a real platform brand as a
functional in-game app.

**INV-6 is narrowed, not deleted** (see DR-12): real *platform* brands are permitted as in-game
apps; no other real brand, logo, wordmark or trademark appears in any shipped asset, and no
third party's actual asset files are ever bundled. Reviewed per case before merge.

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
| Free exhaustive browsing, no structure | Free browsing **with discovery gates** (`hiddenUntil`, DR-11) |
| No win condition | You must decide. Filed verdict (~15 questions, all required), scored on accuracy. |
| Read everything, put the phone down | You file what you believe — and you can be wrong |
| No way to lose | You can be confidently wrong, and it costs you |
| Horror / supernatural hook | Ordinary relationship drama, deliberately (DR-10) |
| ~~Phone shell~~ | ~~Forensic workstation~~ — **dead as a differentiator (DR-8).** Our shell is a phone shell too. |
| ~~Hard budget / INV-2 scarcity~~ | **Removed (DR-11).** Competitors already do free browsing; we match the fantasy and beat them on ending + gates. |

**Read that table as a warning, not a comfort.** DR-8 struck out the shell, DR-10 struck out
the forensic premise, and DR-11 struck out cycle-budget scarcity. What remains is discovery
structure and a forced scored ending — real, but **loop**, and a loop is invisible until
someone plays it. Since 4.3(b)'s literal removal condition is "do not attract customers", the
burden is now specific:

- Discovery revealing something new, and the verdict, must be legible in the **first two minutes**
  of play, not unlocked in hour two.
- They must be legible in the **App Store screenshots and preview video**, because that is the
  only differentiation a reviewer or a browsing customer sees before installing.

A **free, complete first case** remains the strongest available answer: a reviewer can play the
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

- [ ] **Re-read 5.2.5 from Apple's live page — confirm text unchanged. Highest-value line here,
      because DR-8 puts us inside what it describes (§1.1).** Then 4.1, 4.3, 3.1.2.
- [ ] ~~No screen resembles an Apple interface~~ — **N/A under DR-8, deliberately.** Instead:
      confirm no *Apple-authored asset* ships (icons, logos, wordmarks, glyph artwork). That is
      4.1(c) and copyright, and DR-8 does not cover it.
- [ ] Theme layer intact — fonts, geometry, radii, icon shapes, status bar all still data, not
      hardcoded. This is the retreat path; verify it still works by reskinning in a scratch
      build before submitting.
- [ ] 4.3(b) differentiation visible in the first ten minutes and in the screenshots —
      discovery gates opening new content, forced filed verdict scored on accuracy. "Phone
      shell" and cycle-budget scarcity are no longer differentiators (DR-8, DR-11).
- [ ] INV-6 asset review passed for every case in the build
- [ ] **Real platform brands appear in the screenshots (DR-12) — accept that this is the most
      likely rejection trigger, and re-read 4.1(b)'s live text before submitting.** No brand
      beyond the in-game platforms; no third party's actual asset files bundled anywhere
- [ ] Brand strings still confined to their single config file — verify reverting to invented
      names is genuinely a config edit. That is DR-12's only retreat path
- [ ] Free first case complete and playable to a filed verdict without payment
- [ ] IAP is one-time unlock only; no cycle purchases exist anywhere in the build
- [ ] Catalog is the only source of product IDs — none appear in views
- [ ] Purchase screen states one-time, names the case, shows StoreKit's localized price, says it is not a subscription, and offers Restore Purchases
- [ ] No fake urgency, countdown, preselected purchase, or disguised buy button
- [ ] Local `.storekit` configuration is not treated as proof that the App Store Connect product exists
- [ ] Case 1 (`five_minutes`) launches with StoreKit unavailable
- [ ] Accessibility baseline checked: VoiceOver labels on library cards, purchase actions, maps pins, social rows, link nodes, verdict options, results; Dynamic Type; Reduce Motion; no critical info by color only; authored image descriptions do not leak `depicts`
- [ ] Age rating matches actual content
- [ ] No device-data permission requested that gameplay doesn't need
- [ ] Privacy nutrition label matches what the app actually collects
