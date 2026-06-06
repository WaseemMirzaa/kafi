/// String formatting helpers (replaces deprecated / GetX-only extensions in UI).
extension StringFormat on String {
  String get titleCase {
    if (isEmpty) return this;
    if (length == 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
