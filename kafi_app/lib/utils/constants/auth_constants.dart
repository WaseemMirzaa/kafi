/// Auth flow limits and timings (System spec §1.5 & §Authentication).
class AuthConstants {
  // Firebase phone-auth SMS codes are 6 digits.
  static const otpLength = 6;
  static const otpExpirySeconds = 300;
  static const otpResendCooldownSeconds = 60;
  static const minPasswordLength = 8;
  static const defaultCountryCode = '+971';

  /// iOS Phone Auth reCAPTCHA callback scheme when `REVERSED_CLIENT_ID` is absent.
  /// Format: `app-` + [GOOGLE_APP_ID] with `:` replaced by `-`.
  static String iosPhoneAuthCallbackScheme(String googleAppId) =>
      'app-${googleAppId.replaceAll(':', '-')}';

  /// Nanny-origin country codes per System Spec §1.5
  static const nannyCountryCodes = <String, String>{
    'UAE': '+971',
    'Philippines': '+63',
    'India': '+91',
    'Sri Lanka': '+94',
    'Nepal': '+977',
    'Indonesia': '+62',
    'Ethiopia': '+251',
    'Kenya': '+254',
    'Ghana': '+233',
    'Nigeria': '+234',
    'Pakistan': '+92',
    'Bangladesh': '+880',
    'Uganda': '+256',
  };

  /// Display options (flag + dial code) for the nanny login country picker —
  /// the single source for that list (System Spec §1.5).
  static const nannyCountryOptions = <String>[
    '🇦🇪 +971', '🇵🇭 +63', '🇮🇳 +91', '🇱🇰 +94', '🇳🇵 +977', '🇮🇩 +62',
    '🇪🇹 +251', '🇰🇪 +254', '🇬🇭 +233', '🇳🇬 +234', '🇵🇰 +92', '🇧🇩 +880', '🇺🇬 +256',
  ];

  /// Display options (flag + dial code) for the family login country picker
  /// (extended list per System Spec §1.5).
  static const familyCountryOptions = <String>[
    '🇦🇪 +971', '🇸🇦 +966', '🇰🇼 +965', '🇶🇦 +974', '🇧🇭 +973',
    '🇴🇲 +968', '🇪🇬 +20', '🇱🇧 +961', '🇯🇴 +962', '🇲🇦 +212',
    '🇬🇧 +44', '🇮🇪 +353', '🇫🇷 +33', '🇩🇪 +49', '🇮🇹 +39',
    '🇪🇸 +34', '🇳🇱 +31', '🇨🇭 +41', '🇺🇸 +1', '🇨🇦 +1',
    '🇮🇳 +91', '🇵🇰 +92', '🇸🇬 +65', '🇦🇺 +61', '🇳🇿 +64',
  ];
}
