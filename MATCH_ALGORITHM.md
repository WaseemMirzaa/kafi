# Kafi — Best Match Algorithm

This document defines how Kafi computes a **similarity percentage (0–100)** between a
family's **job posting** and a **nanny's profile**, so families see the best-fit nannies first
and nannies see the jobs they are most likely to win.

It covers (1) which fields are used, (2) the eligibility gates, (3) the weighted scoring model,
(4) the per-dimension formulas, (5) the final percentage, and (6) a worked example.

---

## 0. Client Overview — In Plain Language (Full Detail)

In simple terms, Kafi's matching works like an experienced agency coordinator who reads a
family's job posting, looks at every available nanny, and scores how well each one fits — except
it does this instantly, consistently, and for every candidate at once. The output is a single
**similarity percentage from 0 to 100** that the family sees on each nanny's card (and that the
nanny sees on each job), so the strongest fits naturally rise to the top of the list. The whole
process is **deterministic**, meaning the same family and the same nanny will always produce the
exact same percentage; there is no randomness and no "black box," so any score can be explained
factor by factor.

The matching runs in two stages. The **first stage is a set of eligibility gates** — strict
yes/no checks that decide whether a nanny is even allowed to appear for a family. A nanny must be
**admin-approved** (her documents have been verified by our operations team) and, where
configured, carry the **verified badge**, and the job itself must be **active**. Anyone who fails
a gate is removed from the results entirely rather than simply scored low, which guarantees that
families only ever see genuinely eligible, vetted candidates. The **second stage scores every
remaining nanny** across eleven weighted dimensions and combines them into the final percentage.

Each of the eleven dimensions measures one real-world aspect of fit and carries a weight
reflecting how much it matters, with all weights adding up to 100. The largest factor is **job
type (18%)** — whether a live-in family is paired with a nanny who accepts live-in work, since a
mismatch here rarely works in practice. Next come **location (14%)**, which rewards a nanny
already willing to work in the family's emirate and gives partial credit if she is open to
relocating, and **languages (14%)**, which checks that the nanny speaks the languages the family
needs to communicate with their children and household, with a small extra bonus for
"nice-to-have" preferred languages. **Experience (12%)** confirms the nanny meets the minimum
years requested, and **salary (10%)** checks that the family's budget and the nanny's expectation
overlap, easing the score down gradually as the gap widens rather than failing abruptly. **Skills
and duties (9%)** matches concrete needs such as cooking, newborn or infant care, night shifts,
pet care, and special-needs experience — and if the family has registered a special-needs child,
that requirement is added automatically even when the posting forgot to mention it. **Religion and
household culture (7%)** respects the family's stated preference (no preference, prefer Muslim,
prefer the same faith, or open-with-respect) while remaining fair to nannies who are comfortable
working across faiths. **Household comfort (5%)** verifies that a nanny is comfortable with home
cameras and with pets when the family actually has them, while **household load (3%)** gives
heavier homes of three or more children a nudge toward nannies with proven depth. Finally,
**availability (4%)** rewards nannies who can start on time, and **visa compatibility (4%)** aligns
the family's sponsorship offer with the nanny's current visa situation. A small, unbiased
**nationality tie-breaker** then orders any near-ties (scores within two points) toward a
preferred nationality without ever lowering a score.

A deliberate fairness rule runs through the whole model: **when a family leaves an optional
preference blank, that dimension scores as a perfect neutral rather than a penalty.** If a family
does not specify required languages, a salary ceiling, or a religion preference, the algorithm
treats those as "no constraint" and the nanny is not punished for the family's silence — so the
percentage always reflects genuine mismatches, never missing data. Once every dimension is scored
on a 0-to-1 scale, each is multiplied by its weight and summed, then rounded to a whole number
between 0 and 100. That number is translated into a friendly label for the interface — **80 and
above is a "Great Match," 60–79 is "Good," 40–59 is "Fair," and below 40 is "Low"** — so families
get an instant read without needing to interpret the raw figure.

Two practical notes complete the picture. First, on **privacy**: sensitive fields such as health
conditions, medications, allergies, emergency contacts, and uploaded documents are used **only**
for safety and verification and are **never** fed into the score, so matching can never
disadvantage a nanny for personal or medical information. Second, on **transparency of current
state**: there is now a **single scoring engine** (`MatchService`). It powers the detailed
breakdown on the job-detail and Smart Match screens over the full profile, and the browse list
ranks cards through the very same engine using the subset of dimensions a lightweight card
carries — so the number is consistent everywhere rather than coming from separate heuristics.
Everything else in this document — the exact fields, weights, formulas, and a fully worked
example — is laid out below for the technical team.

---

## 1. Overview

Matching runs in two stages:

1. **Eligibility gates** — hard yes/no filters. A nanny who fails any gate is *excluded*
   from a family's results entirely (not just scored low).
2. **Weighted similarity score** — for every eligible nanny, each scoring **dimension** is
   rated on a `0.0–1.0` scale, multiplied by its weight, and summed into a `0–100` percentage.

```
similarity% = round( Σ (weightᵢ × scoreᵢ) )   for all scoring dimensions i
```

The score is **deterministic** (same inputs → same output) so it can be computed on the
client for instant browsing and re-used on the server for ranking.

---

## 2. Fields Used

### 2.1 Authentication / account fields (`UserModel`)

Auth fields are used for **identity and eligibility**, not for the weighted score.

| Field | Role in matching |
|-------|------------------|
| `type` (`nanny` / `family`) | Routes the user to the correct side; a job is matched only against nannies |
| `fullName`, `phone`, `email` | Identity/display only — **not scored** |
| `hasPassword`, `fcmTokens`, `settings` | Account/notification plumbing — **not scored** |

> The account record establishes *who* a profile belongs to. The matchable signal lives in the
> **nanny profile** and **job posting**, described below.

### 2.2 Job-posting fields (`JobPostModel`) — family side

These are the family's requirements (the "query").

| Field | Used for |
|-------|----------|
| `jobType` (liveIn/liveOut) | Job-type dimension |
| `city` | Location dimension |
| `languagesRequired`, `languagesPreferred` | Language dimension |
| `experienceYears` | Experience dimension |
| `salaryMin`, `salaryMax` | Salary dimension |
| `skillsRequired`, `duties` | Skills & duties dimension |
| `visaSponsorship` | Visa dimension |
| `startDate`, `startImmediate` | Availability dimension |
| `religionPreference` | Religion dimension |
| `nationalityPreference` | Sort tie-breaker (see §4 tie-breaker) |
| `status` | **Gate** — only `active` jobs match |

### 2.3 Family profile fields (`FamilyModel`) — household context

Supplement the job posting with household realities.

| Field | Used for |
|-------|----------|
| `religion` | Religion dimension (for `preferSame`) |
| `nannyReligionPreference` | Religion dimension (mirrors `JobPost.religionPreference`) |
| `hasCameras` | Household-comfort dimension |
| `hasPets`, `petTypes` | Household-comfort dimension |
| `childrenAges`, `hasSpecialNeedsChild` | Skills & duties dimension (e.g. newborn/special-needs need) |
| `childrenCount` | Household-load dimension |
| `languagesAtHome` | Falls back into the language dimension when the posting omits it |

### 2.4 Nanny profile fields (`NannyModel`) — the candidate

| Field | Used for |
|-------|----------|
| `status` (`approved`) + `isVerified` | **Gates** — only approved nannies match |
| `jobTypePreference` (liveIn/liveOut/both) | Job-type dimension |
| `workEmirates`, `willingToRelocate`, `currentArea` | Location dimension |
| `languages` | Language dimension |
| `experiences[]` (durations) | Experience & skills dimensions |
| `expectedSalaryMin`, `expectedSalaryMax` | Salary dimension |
| `canCook`, `cuisines`, `canDoNightShifts`, `comfortableWithPets` | Skills & duties dimension |
| `comfortableWithCameras` | Household-comfort dimension |
| `religion`, `comfortableWithDifferentFaith` | Religion dimension |
| `visaStatus`, `hasEmiratesId`, `willingToTransferVisa` | Visa dimension |
| `availability`, `availableFrom` | Availability dimension |
| `hasChildren` | Household-load dimension (parenting depth) |
| `nationality` | Sort tie-breaker (see §4 tie-breaker) |

---

## 3. Eligibility Gates (hard filters)

A nanny is shown to a family **only if all** of the following hold. Any failure removes the
nanny from the result set.

1. `nanny.status == approved` — passed admin verification.
2. `job.status == active` — the posting is live.
3. *(configurable)* `nanny.isVerified == true` — fully verified badge required.

> Gates are applied first so the weighted score only ranks genuinely viable candidates.

---

## 4. Scoring Dimensions & Weights

Each dimension returns a normalized score in `[0.0, 1.0]`. Weights sum to **100**.

| # | Dimension | Weight | Intuition |
|---|-----------|:------:|-----------|
| 1 | Job type (live-in / live-out) | **18** | A live-in family and a live-out-only nanny rarely work — biggest single factor |
| 2 | Location | **14** | Same emirate beats a relocation |
| 3 | Languages | **14** | Communication with kids & parents |
| 4 | Experience | **12** | Meets the required years |
| 5 | Salary | **10** | Budget vs. expectation overlap |
| 6 | Skills & duties | **9** | Cooking, newborn, night shifts, pets, special needs, etc. |
| 7 | Religion / culture | **7** | Household compatibility |
| 8 | Household comfort | **5** | Cameras & pets acceptance |
| 9 | Household load | **3** | Heavier homes (3+ children) favour proven depth |
| 10 | Availability | **4** | Can start on time |
| 11 | Visa compatibility | **4** | Sponsorship vs. visa status |
|   | **Total** | **100** | |

> **Missing-data rule:** when a job leaves an *optional* requirement empty (e.g. no
> `languagesRequired`, `salaryMax == 0`, `religionPreference == noPreference`), that dimension
> returns **1.0** (neutral) so the family isn't penalized for not specifying a preference.

### 4.1 Job type — weight 18
```
if nanny.jobTypePreference == both      → 1.0
else if jobLiveIn == nannyLiveIn        → 1.0
else                                    → 0.2
```

### 4.2 Location — weight 14
```
if job.city is empty                            → 1.0
else if nanny.workEmirates contains job.city    → 1.0
else if nanny.willingToRelocate                 → 0.7
else                                            → 0.2
```

### 4.3 Languages — weight 14
Let `required = job.languagesRequired` (fall back to `family.languagesAtHome` if empty).
```
if required is empty           → 1.0
else                           → matchedCount / required.length        (0.0–1.0)
```
`languagesPreferred` then adds a bonus of `0.1 × (preferredMatched / preferredCount)`, with the
final dimension clamped to a maximum of `1.0`.

### 4.4 Experience — weight 12
`nannyYears = Σ (exp.toDate.year − exp.fromDate.year)` across `experiences`, each clamped 0–20.
```
if job.experienceYears == 0              → 1.0
else if nannyYears ≥ job.experienceYears → 1.0
else if nannyYears ≥ required − 1        → 0.7
else                                     → 0.3
```

### 4.5 Salary — weight 10
Ranges are `[nanny.expectedMin, nanny.expectedMax]` vs `[job.salaryMin, job.salaryMax]`.
```
if nanny expectation unset (0/0)   → 1.0
if job.salaryMax == 0              → 1.0
if ranges overlap                  → 1.0
else gap = nanny.expectedMin − job.salaryMax:
    gap < 500   → 0.7
    gap < 1000  → 0.4
    otherwise   → 0.1
```

### 4.6 Skills & duties — weight 9
Combine `job.skillsRequired` + `job.duties` into a requirement set; score each against the
nanny's capabilities, then `score = matched / total`.
```
cooking      → nanny.canCook
night_shifts → nanny.canDoNightShifts
pet_care     → nanny.comfortableWithPets
newborn      → any experience mentioning "newborn" (job title/children) OR family has an infant
special_needs→ any experience mentioning "special needs"
(other)      → treated as satisfied (no negative signal)
if requirement set empty → 1.0
```
When `family.hasSpecialNeedsChild == true`, a `special needs` requirement is **added
automatically** even if the posting didn't list it, so special-needs experience is rewarded.

### 4.7 Religion / culture — weight 7
Driven by `job.religionPreference` (or `family.nannyReligionPreference`).
```
noPreference    → 1.0
preferMuslim    → nanny.religion is Muslim ? 1.0 : 0.3
preferSame      → nanny.religion == family.religion ? 1.0 : 0.3
openWithRespect → nanny.comfortableWithDifferentFaith ? 1.0 : 0.5
```

### 4.8 Household comfort — weight 5
Average of the two sub-checks (each defaults to 1.0 when the family doesn't have it).
```
cameraScore = family.hasCameras ? (nanny.comfortableWithCameras ? 1.0 : 0.0) : 1.0
petScore    = family.hasPets    ? (nanny.comfortableWithPets    ? 1.0 : 0.0) : 1.0
score = (cameraScore + petScore) / 2
```

### 4.9 Household load — weight 3
Heavier households favour nannies with demonstrated depth; smaller homes impose no constraint.
```
if family is null OR family.childrenCount ≤ 2   → 1.0
else nanny.hasChildren OR nannyYears ≥ 3         → 1.0
else                                             → 0.6
```

### 4.10 Availability — weight 4
```
availability == onTrial        → 0.3
availability == availableNow   → 1.0
availableFrom & job.startDate set:
    diffDays ≤ 0   → 1.0
    diffDays ≤ 7   → 0.8
    diffDays ≤ 14  → 0.6
    otherwise      → 0.3
else                           → 0.7
```

### 4.11 Visa compatibility — weight 4
```
job.visaSponsorship == full          → 1.0
job.visaSponsorship == residenceOnly → nanny.hasEmiratesId ? 1.0 : 0.0
otherwise                            → (nanny.willingToTransferVisa || nanny.hasEmiratesId) ? 1.0 : 0.3
```

### Tie-breaker — nationality *(implemented)*
`job.nationalityPreference` is intentionally **not** a weighted dimension (to avoid bias). Instead,
`MatchService.rankCards` uses it purely as a **sort tie-breaker**: when two candidates score within
**2 points** of each other, the one whose nationality is in the family's preference list is ordered
first; otherwise ordering falls back to the raw score. A matching nationality can only *raise*
position within a near-tie — it never lowers a score.

---

## 5. Final Percentage & Labels

```
raw   = Σ (weightᵢ × scoreᵢ)            // 0–100
final = round(raw).clamp(0, 100)
```

The full scorer (`MatchService.calculateJobMatch`) returns the **true** `0–100` value with no
floor. A **display floor of 35** (range `[35, 99]`) is applied only by the browse-card path
(`MatchService.cardMatchPercent`, which `jobMatchPercent` now wraps) to keep the browsing UI
friendly; ranking within `rankCards` still uses that same card score.

| Score | Label |
|-------|-------|
| 80–100 | **Great Match! 🌸** |
| 60–79 | **Good Match** |
| 40–59 | **Fair Match** |
| 0–39 | **Low Match** |

---

## 6. Worked Example

**Job posting:** live-in, Dubai, requires English + Arabic, 2 yrs experience,
AED 2,500–3,500, skills = cooking + newborn, full visa sponsorship, prefers Muslim,
family has cameras, no pets, start immediately.

**Nanny:** prefers *both*, works Dubai, speaks English + Arabic + Filipino, 4 yrs experience,
expects AED 2,800–3,400, canCook = true + newborn experience, willing to transfer visa,
Muslim, comfortable with cameras, available now.

| Dimension | Score | Weight | Contribution |
|-----------|:-----:|:------:|:-----------:|
| Job type (both) | 1.0 | 18 | 18.0 |
| Location (Dubai) | 1.0 | 14 | 14.0 |
| Languages (2/2) | 1.0 | 14 | 14.0 |
| Experience (4 ≥ 2) | 1.0 | 12 | 12.0 |
| Salary (overlap) | 1.0 | 10 | 10.0 |
| Skills (cook+newborn 2/2) | 1.0 | 9 | 9.0 |
| Religion (Muslim) | 1.0 | 7 | 7.0 |
| Household comfort (cameras ok, no pets) | 1.0 | 5 | 5.0 |
| Household load (≤2 children) | 1.0 | 3 | 3.0 |
| Availability (now) | 1.0 | 4 | 4.0 |
| Visa (full sponsorship) | 1.0 | 4 | 4.0 |
| **Total** | | **100** | **100 → "Great Match! 🌸"** |

A second nanny who is *live-out only* would score `0.2 × 18 = 3.6` on job type instead of 18,
dropping the total to ≈ **85.6** — still a strong match, but ranked below the first.

---

## 7. Implementation Notes

- **Single source of truth.** `lib/services/match_service.dart` (`MatchService`) is the only
  scoring engine. It exposes two entry points that share the same weights and per-dimension
  formulas:
  - `calculateJobMatch(nanny, job, {family})` + `getMatchFactors(...)` — the full 11-dimension
    score over a complete `NannyModel` (job-detail screen and the Smart Match breakdown).
  - `cardMatchPercent(card, job)` + `rankCards(cards, job)` — the browse-list score over the
    lightweight `NannyCardModel`, using the subset of dimensions a card carries (job type,
    location, languages, experience, availability), renormalized over just those weights, plus
    the nationality tie-breaker.
- **Thin wrappers.** `lib/utils/job_match.dart` (`jobMatchPercent`) and `lib/utils/smart_match.dart`
  (`SmartMatch.evaluate`) now delegate to `MatchService` — they hold no scoring logic of their own.
  `SmartMatch` returns the canonical score and derives its five UI checks from the matching
  canonical dimensions.
- **Where it runs:** `browseNannies(matchJob: job)` in both the mock and Firestore job services
  ranks via `MatchService.rankCards`, so the percentage and ordering on the browse list, the job
  detail, and the Smart Match screen all come from one engine.
- **Determinism:** no randomness; identical inputs always yield the same percentage.
- **Extensibility:** weights live in a single `_weights` map; adding a dimension means adding a
  `0.0–1.0` scorer and a weight that keeps the total at 100.
- **Privacy:** health, medication, allergy, emergency-contact, and document fields are **never**
  used in scoring; they exist for safety/verification only.

---

## 8. Status & Future Ideas

The gaps that previously split scoring across three implementations are now **resolved**:

1. ✅ **Browse ranking uses the engine.** Both job services rank through `MatchService.rankCards`
   instead of a standalone heuristic.
2. ✅ **Smart Match breakdown is canonical.** `SmartMatch.evaluate` delegates to `MatchService`;
   its score and checks reflect §4.
3. ✅ **Nationality tie-breaker** is implemented in `rankCards` (see §4 tie-breaker).
4. ✅ **Household load** is a live dimension (§4.9), grounded in `family.childrenCount` and the
   nanny's parenting depth / experience.
5. ✅ **One scoring implementation.** `jobMatchPercent` and `SmartMatch` are thin wrappers over
   `MatchService`.

Future, non-blocking enhancements:

- **Card parity.** The browse card carries a subset of fields, so its score uses 5 of the 11
  dimensions. Persisting a richer card (or scoring full `NannyModel`s server-side) would let the
  browse list use all 11 dimensions for an exact match to the detail score.
- **Explicit nanny capacity.** A dedicated "max children" field on the nanny profile would make
  the household-load dimension precise rather than experience-based.
- **Learned weights.** The static weights could later be tuned from real hire/trial outcomes.
