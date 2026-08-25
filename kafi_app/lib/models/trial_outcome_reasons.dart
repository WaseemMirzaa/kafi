// Reason enums for the trial-completion mutual-outcome flow. Persisted as
// the enum's stable `.name` (never the localized label) — matches every
// other enum-to-string convention in this codebase, e.g. `TrialStatus.name`,
// `HireEndReason.resigned.name`. Display labels are resolved through
// `AppStrings` at render time.

/// Why the family chose not to hire after a trial (skippable). Persisted to
/// `trials.notHiredReason`.
enum NotHiredReason {
  notTheRightMatch,
  salary,
  schedule,
  location,
  nannyDeclined,
  foundSomeoneElse,
  other,
}

/// Why a hired nanny is making her profile available again. Carried as the
/// free-text `note` on the existing `HireModel.endNote` field via
/// `endHire(..., note: reason.name)` — no new persistence surface.
enum ReactivationReason {
  jobDidntWorkOut,
  familyEndedEmployment,
  iDecidedToLeave,
  temporaryJobEnded,
  other,
  preferNotToSay,
}
