---
epic: kafi-profile-trial-overhaul
project: kafi
title: Trial-completion workflow + family/nanny profile simplification (emirate-only location, no GPS)
owner: project-manager
status: APPROVED
updated: 2026-08-15
---

# Epic: Trial-completion workflow + profile simplification

Waseem's spec (verbatim requirements are in each phase's scope doc) covers three
areas: a rebuilt trial-completion/reactivation workflow with mutual hire
confirmation, family-profile field changes (emirate-only location, multi-select
role with "Other", days-off replacing free-text schedule), and nanny-profile
field changes (emirate-only location, expanded languages, full/part-time +
per-day part-time availability, restructured work-experience fields, dropping
emergency contact). All three remove Google Maps/GPS from the fields they touch.

## Decisions locked in during scoping (do not re-litigate)

1. **Mutual hire confirmation.** The family's "We hired her" is a *pending*
   signal, not an instant hire. The nanny is marked Hired (and hidden from
   search) only once she also confirms "I got the job". This replaces today's
   single-sided instant-hire (`TrialController.setOutcome` → immediate
   `_createHireFromTrial`).
2. **Emirate list correctness.** The canonical list is the real 7 UAE emirates
   (Abu Dhabi, Dubai, Sharjah, Ajman, Umm Al Quwain, Ras Al Khaimah, Fujairah).
   The existing nanny `Emirate` enum (`kafi_app/lib/models/nanny_model.dart:6`)
   wrongly lists "Al Ain" as an 8th, separate value — Al Ain is a city inside
   Abu Dhabi emirate, not its own emirate. Fix this enum to the correct 7 and
   use the same 7 everywhere (existing `workEmirates`, and every new
   emirate-select field this epic adds). Any nanny document currently holding
   `Emirate.alAin` must be remapped to `Emirate.abuDhabi` (one-time, on read or
   via a small migration — architect's call which).
3. **Delivery.** Three phases, built and reviewed **in parallel** (file sets
   barely overlap) — three independent branches/PRs, no phase blocks another.

## Phases

| Phase | Slug | Scope doc | Status |
| ----- | ---- | --------- | ------ |
| 1 — Nanny profile fields | `kafi-nanny-profile-fields` | `scope/kafi-nanny-profile-fields.md` | ACTIVE |
| 2 — Family profile fields | `kafi-family-profile-fields` | `scope/kafi-family-profile-fields.md` | ACTIVE |
| 3 — Trial completion & reactivation flow | `kafi-trial-completion-flow` | `scope/kafi-trial-completion-flow.md` | ACTIVE |

Each phase runs the full `scope → plan → build → review → PR` cycle
independently (see root `CLAUDE.md` §1, §3). Architect plans first — no
developer starts until its phase's `plans/<slug>.md` exists with
`status: READY_FOR_BUILD`.

## Cross-phase notes (for all three architects)

- **GPS/Maps removal is scoped to the fields the user's spec explicitly names**
  (see each phase's scope doc). `trial_offer_screen.dart`'s location picker
  (trial logistics address) and `nanny_refs_screen.dart`'s reference-city
  picker are **out of scope** — they are not part of either party's profile.
- `KafiLocationPicker` (`kafi_app/lib/views/widgets/kafi_location_picker.dart`)
  and its backing `LocationService`/`PlacesService` stay in the codebase (used
  by the two out-of-scope sites above) — do not delete them, just stop calling
  them from the in-scope fields.
- Existing production data: treat new/changed fields as additive where
  possible (nullable/optional, sensible fallback when absent) rather than
  requiring a destructive backfill, **except** the Emirate-8→7 remap above,
  which the user explicitly approved.
- No two phases should edit the same file. If an architect's plan would touch
  a file another phase's scope doc also claims, stop and flag it in the plan
  instead of proceeding — report to the PM.
