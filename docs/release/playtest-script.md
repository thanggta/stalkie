# External first-player playtest — facilitator script

**Audience:** someone who has **not** read either case, the design docs, or this repo.  
**Goal:** measure real first-play behavior and time-to-filed-verdict. Not to coach them to the “right” ending.

Internal playtests are author-contaminated and already under the 45–90 minute target.  
**Do not pad content during this session. Do not tell them the target time.**

---

## What to install

Prefer a **TestFlight** or other **release-equivalent** build (Release configuration, no DEBUG unlock).  
If only a Debug sim build is available, say so on the observation sheet — it is not release-equivalent.

**Do not** pass `-unlockAllCases` or developer reset unless recovering a broken install.

---

## Recruitment blurb (send as-is)

> Looking for ~30–60 minutes of playtesting on an iPhone game. You open a phone that isn’t yours and decide what you believe. No prior knowledge needed. I’ll watch quietly and only step in if you’re completely stuck. Spoilers off afterward if you want them.

Exclude: anyone who wrote the cases, read `cases/*/`, or saw design/verdict docs.

---

## Before they start

1. Confirm they have not seen the cases.  
2. Sandbox / purchase: for **Five Minutes only**, no purchase needed.  
3. If testing the paid case later, use a **separate session** and do **not** reveal any “twist” framing.  
4. Start a screen recording only with consent.  
5. Start timer when they reach the case library (or when the phone opens — pick one and stick to it; note which).

### Spoken intro (spoiler-free)

> This is a fiction game. You’re looking through a phone. Browse whatever you want. When you feel ready, there’s a way to say what you think happened. There isn’t a single button that “wins” by reading everything. I’ll stay quiet unless you can’t move at all. Ready?

**Do not say:** Links, Decide, Maps gates, affair, ring, job offer, or any character names before they appear.

---

## Session A — Five Minutes (required first)

1. Launch app → case library.  
2. Ask them to open **Five Minutes** (point only if they cannot find the free card).  
3. Observe silently.  
4. Interventions only if **completely blocked** (cannot leave a screen, crash, blank UI). Record every word you say.  
5. Stop when they **file** a verdict, or after they abandon with a stated reason.  
6. Optional post-game questions (after timer stops) — see observation sheet. Do not correct answers until they ask.

## Session B — Don’t Wait Up (optional, separate)

- Run only if time and entitlement allow (sandbox purchase or owned).  
- **Do not** frame it as “the one where you might be wrong.”  
- Same silence rules.  
- Separate observation sheet instance.

---

## What you must capture

See `docs/release/playtest-observation-sheet.md`:

- Start → filed-verdict clock time (honest)  
- First ten minutes behavior  
- Apps opened / ignored  
- Whether Links is found without prompting  
- Whether a required link is understood  
- Whether Decide is found at a reasonable moment  
- Fragments they never open (if you can tell post-results)  
- Confidence / confusion / boredom moments  
- Whether ~15 questions feel manageable  
- Whether committing feels heavy  
- Whether wrong answers feel fair after results  
- Interest in replaying from missed evidence  
- Purchase/lock confusion if paid case included  
- Every intervention

---

## Afterward

1. Thank them. Offer spoiler debrief only if they want it.  
2. Do **not** tell them to expand the case to hit 45–90 minutes.  
3. File the sheet into the release report as evidence.  
4. Content expansion vs shortening the design target is a **product decision later**, not part of release-readiness coding.
