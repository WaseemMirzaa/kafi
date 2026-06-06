class ShortlistItem {
  final String id;
  final String familyId;
  final String nannyId;
  final String? nannyName;
  final String? nannyPhoto;
  final String? notes;
  final DateTime addedAt;

  const ShortlistItem({
    required this.id,
    required this.familyId,
    required this.nannyId,
    this.nannyName,
    this.nannyPhoto,
    this.notes,
    required this.addedAt,
  });

  ShortlistItem copyWith({String? notes}) => ShortlistItem(
        id: id,
        familyId: familyId,
        nannyId: nannyId,
        nannyName: nannyName,
        nannyPhoto: nannyPhoto,
        notes: notes ?? this.notes,
        addedAt: addedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'nannyId': nannyId,
        'nannyName': nannyName,
        'nannyPhoto': nannyPhoto,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ShortlistItem.fromMap(Map<String, dynamic> m) => ShortlistItem(
        id: m['id'] as String,
        familyId: m['familyId'] as String,
        nannyId: m['nannyId'] as String,
        nannyName: m['nannyName'] as String?,
        nannyPhoto: m['nannyPhoto'] as String?,
        notes: m['notes'] as String?,
        addedAt: DateTime.parse(m['addedAt'] as String),
      );
}
