import 'package:kafi_app/models/nanny_model.dart';

/// The 7 real UAE emirates in display order, reusing the shared [Emirate] enum.
/// Declared explicitly (not `Emirate.values`) so this list is independent of the
/// enum's declaration/order and never surfaces the removed `Al Ain` value —
/// which keeps it compiling both before and after the nanny phase's 8→7 fix.
const List<Emirate> kFamilyEmirates = [
  Emirate.abuDhabi, Emirate.dubai, Emirate.sharjah, Emirate.ajman,
  Emirate.uaq, Emirate.rak, Emirate.fujairah,
];

const Map<Emirate, String> _emirateLabels = {
  Emirate.abuDhabi: 'Abu Dhabi',
  Emirate.dubai: 'Dubai',
  Emirate.sharjah: 'Sharjah',
  Emirate.ajman: 'Ajman',
  Emirate.uaq: 'Umm Al Quwain',
  Emirate.rak: 'Ras Al Khaimah',
  Emirate.fujairah: 'Fujairah',
};

String emirateLabel(Emirate e) => _emirateLabels[e] ?? e.name;

/// Parses a stored `city` string back to an [Emirate]. Tolerant of legacy
/// free-text: matches a canonical label OR the enum `.name`, case-insensitively;
/// returns null when the stored value is none of the 7 (so old free-text data
/// simply shows nothing pre-selected instead of crashing).
Emirate? emirateFromStored(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  if (v.isEmpty) return null;
  for (final e in kFamilyEmirates) {
    if (emirateLabel(e).toLowerCase() == v || e.name.toLowerCase() == v) return e;
  }
  return null;
}
