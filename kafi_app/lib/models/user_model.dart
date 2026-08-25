enum UserType { nanny, family }

/// User settings per System Spec §3.1
class UserSettings {
  const UserSettings({
    this.pushNotifications = true,
    this.messageNotifications = true,
    this.jobMatchNotifications = true,
    this.trialNotifications = true,
    this.profileViewNotifications = true,
    this.marketingNotifications = false,
    this.emailNotifications = true,
    this.showOnlineStatus = true,
    this.language = 'en',
  });

  final bool pushNotifications;
  final bool messageNotifications;
  final bool jobMatchNotifications;
  final bool trialNotifications;
  final bool profileViewNotifications;
  final bool marketingNotifications;
  final bool emailNotifications;
  final bool showOnlineStatus;
  final String language;

  UserSettings copyWith({
    bool? pushNotifications,
    bool? messageNotifications,
    bool? jobMatchNotifications,
    bool? trialNotifications,
    bool? profileViewNotifications,
    bool? marketingNotifications,
    bool? emailNotifications,
    bool? showOnlineStatus,
    String? language,
  }) =>
      UserSettings(
        pushNotifications: pushNotifications ?? this.pushNotifications,
        messageNotifications: messageNotifications ?? this.messageNotifications,
        jobMatchNotifications: jobMatchNotifications ?? this.jobMatchNotifications,
        trialNotifications: trialNotifications ?? this.trialNotifications,
        profileViewNotifications: profileViewNotifications ?? this.profileViewNotifications,
        marketingNotifications: marketingNotifications ?? this.marketingNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
        language: language ?? this.language,
      );

  Map<String, dynamic> toMap() => {
        'pushNotifications': pushNotifications,
        'messageNotifications': messageNotifications,
        'jobMatchNotifications': jobMatchNotifications,
        'trialNotifications': trialNotifications,
        'profileViewNotifications': profileViewNotifications,
        'marketingNotifications': marketingNotifications,
        'emailNotifications': emailNotifications,
        'showOnlineStatus': showOnlineStatus,
        'language': language,
      };

  factory UserSettings.fromMap(Map<String, dynamic> m) => UserSettings(
        pushNotifications: m['pushNotifications'] ?? true,
        messageNotifications: m['messageNotifications'] ?? true,
        jobMatchNotifications: m['jobMatchNotifications'] ?? true,
        trialNotifications: m['trialNotifications'] ?? true,
        profileViewNotifications: m['profileViewNotifications'] ?? true,
        marketingNotifications: m['marketingNotifications'] ?? false,
        emailNotifications: m['emailNotifications'] ?? true,
        showOnlineStatus: m['showOnlineStatus'] ?? true,
        language: m['language'] ?? 'en',
      );
}

/// Base user model per System Spec §3.1
class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.type,
    this.fullName,
    this.email,
    this.hasPassword = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.fcmTokens = const [],
    this.settings = const UserSettings(),
  });

  final String id;
  final String phone;
  final UserType type;
  final String? fullName;
  final String? email;
  final bool hasPassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final List<String> fcmTokens;
  final UserSettings settings;

  bool get isNanny => type == UserType.nanny;
  bool get isFamily => type == UserType.family;

  UserModel copyWith({
    String? fullName,
    String? email,
    bool? hasPassword,
    UserType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    List<String>? fcmTokens,
    UserSettings? settings,
  }) =>
      UserModel(
        id: id,
        phone: phone,
        type: type ?? this.type,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        hasPassword: hasPassword ?? this.hasPassword,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        fcmTokens: fcmTokens ?? this.fcmTokens,
        settings: settings ?? this.settings,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'userType': type.name,
        'fullName': fullName,
        'email': email,
        'hasPassword': hasPassword,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'fcmTokens': fcmTokens,
        'settings': settings.toMap(),
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] ?? '',
        phone: m['phone'] ?? '',
        type: UserType.values.firstWhere(
            (e) => e.name == (m['userType'] ?? m['type']),
            orElse: () => UserType.family),
        fullName: m['fullName'],
        email: m['email'],
        hasPassword: m['hasPassword'] ?? false,
        createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt']) : null,
        updatedAt: m['updatedAt'] != null ? DateTime.tryParse(m['updatedAt']) : null,
        lastLoginAt: m['lastLoginAt'] != null ? DateTime.tryParse(m['lastLoginAt']) : null,
        fcmTokens: List<String>.from(m['fcmTokens'] ?? []),
        settings: m['settings'] != null
            ? UserSettings.fromMap(m['settings'])
            : const UserSettings(),
      );
}
