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
  return mockNannyCards.first;
}
