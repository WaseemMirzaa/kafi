---
name: review-unverified-type-deviation
description: Recurring Sonnet defect — dropping planned wiring based on a false "field doesn't exist / would need any" claim without reading the source
metadata:
  type: feedback
---

When a build note's "Deviations" section justifies skipping a planned line with a
claim about the *type system* ("field X doesn't exist on the interface", "would
introduce an `any`", "would always be undefined"), verify it against the actual
source before accepting — these claims are frequently wrong.

**Why:** On `kafi-listing-filters`, WU2 dropped the planned
`getDate: (f) => f.createdAt` on AllFamilies claiming `FamilyRow` had no
`createdAt` and that wiring it would need an `any`. Both false: `FamilyRow.createdAt?: Date`
existed (firestore.ts ~line 153), `parseFamily` mapped it (~line 891), and the
optional `Date` matched `getDate`'s signature with zero cast. The only true fact
was that *mock* fixtures didn't populate it — which the plan had already accepted.
Net effect was a rendered-but-inert date filter (dead UI) shipped to avoid a
non-existent type problem. This is Sonnet making an unauthorized scope/architecture
call on a misread.

**How to apply:**
- Grep the interface AND the mapper (`parse*`) AND the mock fixtures separately.
  "Interface has it" + "real-path mapper sets it" = the feature works in prod even
  if mock data leaves it undefined. Don't let "mock is empty" justify dropping
  planned wiring — that's the plan's already-accepted empty-on-missing behavior
  (see [[kafi-revenue-patterns]] for the mock-fixture-window caveat).
- A rendered control wired to inert state is a Major (dead UI / plan deviation),
  even when the build is green.
- The fix for these is almost always one line (restore the planned wiring) — route
  back to the fixer, not the architect, unless the data layer genuinely lacks the
  field in both interface and mapper.
