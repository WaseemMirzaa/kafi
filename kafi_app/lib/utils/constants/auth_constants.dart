/// Auth flow limits and timings (System spec §1.5 & §Authentication).
class AuthConstants {
  static const otpLength = 4;
  static const otpExpirySeconds = 300;
  static const otpResendCooldownSeconds = 60;
  static const minPasswordLength = 8;
  static const defaultCountryCode = '+971';

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

  /// Family country codes per System Spec §1.5 (extended list)
  static const familyCountryCodes = <String, String>{
    // Gulf
    'UAE': '+971',
    'Saudi Arabia': '+966',
    'Kuwait': '+965',
    'Qatar': '+974',
    'Bahrain': '+973',
    'Oman': '+968',
    // Arab
    'Egypt': '+20',
    'Lebanon': '+961',
    'Jordan': '+962',
    'Morocco': '+212',
    // Europe
    'UK': '+44',
    'Ireland': '+353',
    'France': '+33',
    'Germany': '+49',
    'Italy': '+39',
    'Spain': '+34',
    'Netherlands': '+31',
    'Switzerland': '+41',
    // Americas
    'USA': '+1',
    'Canada': '+1',
    // Asia
    'India': '+91',
    'Pakistan': '+92',
    'Singapore': '+65',
    // Oceania
    'Australia': '+61',
    'New Zealand': '+64',
  };
}
