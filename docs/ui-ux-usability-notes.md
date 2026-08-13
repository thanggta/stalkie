# Usability session notes — vertical slice & redesign phase

**Date:** 2026-08-13  
**Build:** `ui-ux-redesign` branch  
**Path under test:** library → five_minutes → discover Sable → Links → connect Eli and Sable → Maps update → Decide → review & revise → file verdict → interpret results

## Status

**No external cold-player tester was present during automated CLI execution.**

Per project safety rules and usability guidelines:
- We do NOT invent playtest results or fake quotes.
- We prepare a complete, installable build and facilitator handoff below.
- Interaction validation is marked **PENDING COLD-PLAYER PLAYTEST**.
- Objective visual, navigation, pacing, schema, and accessibility defects are fixed and verified via automated test suites and device captures.

## Facilitator handoff script for cold-player testing

### Setup
1. Install build on an iPhone (or boot iPhone 17 Pro simulator with `Carve` scheme).
2. Reset session data (Clean launch from Case Library).
3. Do not explain the story or reveal that Links unlocks Maps.

### Observer protocol
- Do not coach or give hints unless the player is completely stuck for > 2 minutes.
- Record every intervention in the log table below.

### Key observation checkpoints
1. **Library start:** Does the player easily launch "Five Minutes"?
2. **Phone fantasy:** Is the fictional iOS shell immediately intuitive?
3. **Links discovery:** Does the player find Links after discovering Sable in Messages?
4. **Links interaction:** Is the "select node A → select node B" connection mechanic clear without tutorial text?
5. **Maps feedback:** Does the player notice the banner / notice that Maps updated after connecting Eli & Sable?
6. **Decide pacing:** Does step-by-step Decide question navigation feel focused or overwhelming?
7. **Verdict revision:** Can the player revise draft answers on the review screen before filing?
8. **Filing consequence:** Does pressing "File Verdict" feel weighty and final?
9. **Results landing:** Do the results explain *why* wrong calls were made and reference supporting evidence?

## Behavior log (to be completed during live playtest session)

| # | Checkpoint | Observation / Player Quote | Intervention Needed? |
|---|---|---|---|
| 1 | Library launch | | |
| 2 | Sable discovery | | |
| 3 | Links connection | | |
| 4 | Maps reaction | | |
| 5 | Decide completion | | |
| 6 | Results landing | | |

## Release gate criteria
Until a non-implementer completes this session without major blocking interventions:
- Interaction validation remains **BLOCKED ON COLD-PLAYER USABILITY TESTING**.

