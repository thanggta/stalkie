# Research Findings — The Fake-Phone Detective Genre

> Condensed from a 103-agent deep-research run (21 sources, 101 claims extracted, 25
> adversarially verified) plus 2 direct gap-filling fetches. Measured **2026-08-08**.
> Full report: https://claude.ai/code/artifact/11ed81eb-3e5b-42d3-acd6-d92779e3bd9b

Every fact below is tagged by how it was established. Do not upgrade a tag without a new
direct query.

- `[VERIFIED]` — read directly from a primary source during this research
- `[INFERRED]` — reasoned from verified facts, not directly observed
- `[UNVERIFIED]` — believed but not established in this run
- `[OPEN]` — unknown, and known to be unknown

---

## 1. What the reference apps are

`[VERIFIED]` *Stalkie · Mobile Detective* (id6745106241) and *Leaked · Mobile Detective*
(id6785890577) are App Store **Entertainment** titles — narrative investigation games where
the player explores a fictional character's simulated phone. They are **not** stalkerware,
OSINT tools, or breach-lookup utilities. Same lineage as *Simulacra*, *Sara Is Missing*,
*A Normal Lost Phone*.

| | Stalkie | Leaked |
|---|---|---|
| Seller | Gregoire Collin (individual) | HAPIGA VIET NAM CO. LTD |
| Released | 2026-01-13 | 2026-07-12 |
| Version at measurement | 1.3.7 | 1.16.0 |
| Size / languages | 84.7 MB · 6 languages | 177 MB · English |
| Age rating | 13+ | 12+ |
| Ratings | 5 · 3.6 avg | 1 · 5.0 avg |
| Model | Free + hard paywall, weekly + annual subscription tiers | same |

`[VERIFIED]` The two are **six months apart**, not simultaneous. The shared subtitle
("Realistic investigation story") is real, but two unrelated sellers six months apart is weak
evidence for a white-label relationship.

`[UNVERIFIED]` Specific VND subscription prices. Extraction returned what look like A/B or
localization variants (a yearly tier priced *below* a 3-month tier; three prices under one
tier name). The **pattern** — weekly + annual hard paywall — is confirmed. The **numbers**
are not.

---

## 2. The review risk — three guidelines point at this genre

All four texts below were read verbatim from Apple's live guidelines page.

### 5.2.5 Apple Products — `[VERIFIED]` — **highest risk**

> "Don't create an app that appears confusingly similar to an existing Apple product,
> interface (e.g. Finder), app (such as the App Store, iTunes Store, or **Messages**) or
> advertising theme."

Carries the **ASR & NR** marker: App Store Removal *and* Developer Program Removal — not a
rejection you resubmit past. The genre's core mechanic is a simulated iOS home screen
containing a fake iMessage-style thread. This rule names that.

**The asymmetry that drives our whole design:** inventing in-fiction brand names (the shipped
convention — *Simulacra*'s "Jabbr" for Twitter) solves **4.1(b)**. It does **nothing** for
5.2.5, because there the exposure *is* the simulated OS shell itself. The standard workaround
and the biggest risk do not overlap.

### 4.1(b) Copycats — `[VERIFIED]`

> "Submitting apps which impersonate other apps or services is considered a violation of the
> Developer Code of Conduct and may result in removal from the Apple Developer Program."

Covers in-game WhatsApp/Instagram/TikTok lookalikes. Also **ASR & NR**. This *is* mitigated by
invented brand names.

### 4.3(b) Spam — `[VERIFIED]`

> "Don't submit apps that are indistinguishable from what's already widely available… we will
> not accept new submissions unless they offer a meaningfully different or improved
> experience. We may remove these apps from the App Store going forward if they are not
> updated, improved, or **do not attract customers**."

`[INFERRED]` The enumerated categories (dating, flashlight, wallpaper, fortune telling) don't
yet include this genre, so enforcement is reviewer discretion today. But ~18 near-identical
titles in seven months is precisely how a category becomes "well established," and both
incumbents have near-zero ratings — the literal text of the removal condition.

### 3.1.2 Subscriptions — `[VERIFIED]` — **not the problem**

> "Apps may offer auto-renewable in-app purchase subscriptions, regardless of category on the
> App Store."

No marker on the heading. Weekly cadence is not per se non-compliant. Risk sits in paywall
**presentation**, not billing interval.

---

## 3. Unit economics

`[VERIFIED]` — RevenueCat *State of Subscription Apps 2026*, gaming category:

| Metric | Value |
|---|---|
| Revenue per install, D60 (median) | **$0.14** |
| Revenue per install, D14 (median) | $0.08 |
| Download→paid conversion, D35 (median) | **1.0%** (top quartile 2.3%) |
| Weekly share of subscriptions sold | 82% (yearly 13%) |
| Realized LTV per payer, year 1 | $11.22 (month 1: $8.41) |
| Reach $1K MRR | 20.0% |
| Reach $10K MRR | **8.9%** — highest of any category |
| Median time to $1K MRR | **32 days** — fastest of any category |

`[INFERRED]` **$0.14 RPI at D60 means paid acquisition needs blended CPI under ~$0.14 to be
gross-positive in two months.** `[UNVERIFIED]` Real iOS CPI on Meta/TikTok runs an order of
magnitude above that. A buy-installs-and-monetize-with-a-weekly-sub strategy is underwater at
median performance.

`[INFERRED]` But 8.9% reaching $10K MRR (highest of any category) plus 32-day median time to
$1K MRR (fastest) explains the clone cluster exactly: **cheap to build, fast to learn, fat
tail.** The economics don't fail generically — they fail for one *specific strategy*. This
works as a portfolio of cheap fast bets where 8.9% carry the rest. That is what a 43-app
operator runs. It is **not** what a solo dev pouring six months into one title runs.

---

## 4. Competitive picture

`[VERIFIED]` At least **11 distinct sellers** independently re-resolved through Apple's lookup
API as shipping near-identical fake-phone investigation titles; a broader sweep surfaced ~18.
Nearly all released March–August 2026.

Named: Spy Story (Axel Hirly), SpyDiva (Evgeniy Bujanivskiy), Detectea (App Tricks Studio —
self-describes verbatim as "a fake-phone mystery game"), SpyLove, Unlocked, Snoop, Fresh
Trace, Last Seen, iChase, Snitchy, Girl Sherlock, Girl Detective, Spylie. A **second,
unrelated** seller ships an app also named "Stalkie."

`[VERIFIED]` Duplication is **cross-publisher** (many sellers, one SKU each), not
within-publisher. HAPIGA's 43-app portfolio holds exactly one Mobile Detective SKU — but HAPIGA
is demonstrably a reskin operator elsewhere (Woolscape 3D → Yarn Quest 3D, 38 days apart,
near-verbatim descriptions with wool→yarn swapped), and Leaked was 27 days old when measured,
inside that latency.

`[VERIFIED]` Genre demand is validated **only at premium pricing**: *A Normal Lost Phone* sold
~200,000 units at €2.99–5.99 one-time. Caveats: that figure has been frozen on the developer's
press kit since at least July 2019, and the title appeared in Humble Bundle — units do **not**
convert to revenue at list price. It says audiences want this genre. It says nothing about
whether free-with-weekly-subscription converts.

---

## 5. Build facts

`[VERIFIED]` Stalkie's iOS + iPadOS + macOS + visionOS listing is **not a stack signal**. Both
Mac-on-Apple-silicon and visionOS availability are opt-out defaults in App Store Connect — zero
engineering, one checkbox. Determining its real engine would need an IPA teardown.

`[VERIFIED]` Ink (inkle) compiles `.ink` → a single `.json`, loaded via
`public Story(string jsonString)` — an arbitrary string, not an engine-specific handle. Content
is data, not compiled code. Version-locked: runtime 21, min-compatible 18, throws outside that
range. Only the *script* is swappable; images, audio, and native behavior stay in the binary.

`[VERIFIED]` inkle officially ships **C# and JavaScript runtimes only** (inkjs is the JS port).
**No official Dart/Flutter runtime.**

`[VERIFIED]` Shipped convention for in-game fake apps is invented in-fiction brands:
*Simulacra*'s Jabbr (Twitter), Spark (Tinder), Surfer (browser). No real platform brand appears
as a functional in-game app. This is evidence of *convention*, not of legal necessity — no
source gave a legal rationale.

---

## 6. Still open

| Question | Why it stayed open |
|---|---|
| What any cluster app actually earns | No download/revenue estimate survived; session search budget exhausted at 200/200 |
| Per-case production cost (words, assets, person-weeks) | Highest-priority research angle produced **zero** verified team-size, budget, or schedule figures from any comparable title |
| Guideline 3.3.2 legality of hot-pushing content | Never checked |
| Cost of AI-generated imagery in 2026 / 6-language localization | Nothing established |

---

## 7. Methodological note worth remembering

The research run's adversarial verification killed all 9 claims across the two most
decision-critical angles (0–3 and 1–2 votes), concluding review risk and unit economics were
unanswerable. **They weren't.** Both source pages are JS-heavy and resisted extraction, and no
verifier ever reported finding *contrary* text. Re-fetching both directly succeeded first try
and confirmed the original claims nearly verbatim, including the ASR & NR markers.

**A failed verification means "not established," which is not the same as "false."**

---

## 8. Non-negotiable design constraint

All fabricated personal content stays **fictional-character-only**. A version that ingests a
real person's data — contacts, messages, photos, location — stops being a narrative game and
becomes the thing the reference apps' names merely suggest. That is a categorically different
and prohibited product. No finding in this research changes it.
