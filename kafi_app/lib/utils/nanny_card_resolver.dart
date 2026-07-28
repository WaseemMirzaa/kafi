import 'package:get/get.dart';
import 'package:kafi_app/data/mock/mock_nannies.dart';
import 'package:kafi_app/models/nanny_card_model.dart';

/// Resolves [NannyCardModel] from route arguments (card object or `{nannyId}` map).
NannyCardModel resolveNannyCard([dynamic arguments]) {
  final args = arguments ?? Get.arguments;
  if (args is NannyCardModel) return args;
  if (args is String) {
    for (final c in mockNannyCards) {
      if (c.id == args) return c;
    }
  }
  if (args is Map) {
    final id = args['nannyId'] as String?;
    if (id != null) {
      for (final c in mockNannyCards) {
        if (c.id == id) return c;
      }
    }
  }
  // No resolvable card (e.g. a deep-link with an unknown id) — return an
  // explicit EMPTY card rather than a fabricated seed nanny, so a real user is
  // never shown a fake profile. Callers can detect this via the empty id.
  return const NannyCardModel(
    id: '',
    initials: '?',
    name: '',
    nationality: '',
    yearsExp: 0,
    jobType: '',
    city: '',
    matchPercent: 0,
    tags: [],
  );
}
