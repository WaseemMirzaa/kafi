import 'package:kafi_app/controllers/auth_controller.dart';

/// Logged-in user id; null when session is missing.
String? currentUserId(AuthController auth) => auth.currentUser.value?.id;

/// Same as [currentUserId] but only when the user is a family account.
String? currentFamilyId(AuthController auth) {
  final user = auth.currentUser.value;
  if (user == null || !user.isFamily) return null;
  return user.id;
}
