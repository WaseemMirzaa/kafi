/// Curated UAE neighbourhood / area labels used by the fallback location
/// picker when Google Maps/Places API key is not configured.
class LocationConstants {
  LocationConstants._();

  /// Default pin when "Use my current location" runs without GPS/geocoding.
  static const mockCurrentArea = 'Dubai Marina';

  /// `(displayName, emirateOrCity)` — searchable suggestions for the picker.
  static const uaeAreas = <(String, String)>[
    ('Dubai Marina', 'Dubai'),
    ('Jumeirah Lake Towers (JLT)', 'Dubai'),
    ('Downtown Dubai', 'Dubai'),
    ('Business Bay', 'Dubai'),
    ('Jumeirah', 'Dubai'),
    ('Jumeirah Beach Residence (JBR)', 'Dubai'),
    ('Palm Jumeirah', 'Dubai'),
    ('Arabian Ranches', 'Dubai'),
    ('Dubai Hills', 'Dubai'),
    ('Al Barsha', 'Dubai'),
    ('Al Quoz', 'Dubai'),
    ('Deira', 'Dubai'),
    ('Bur Dubai', 'Dubai'),
    ('Mirdif', 'Dubai'),
    ('Silicon Oasis', 'Dubai'),
    ('Sports City', 'Dubai'),
    ('Motor City', 'Dubai'),
    ('International City', 'Dubai'),
    ('Discovery Gardens', 'Dubai'),
    ('The Springs', 'Dubai'),
    ('The Meadows', 'Dubai'),
    ('Emirates Hills', 'Dubai'),
    ('Al Reem Island', 'Abu Dhabi'),
    ('Al Maryah Island', 'Abu Dhabi'),
    ('Khalifa City', 'Abu Dhabi'),
    ('Al Raha', 'Abu Dhabi'),
    ('Saadiyat Island', 'Abu Dhabi'),
    ('Yas Island', 'Abu Dhabi'),
    ('Corniche', 'Abu Dhabi'),
    ('Mussafah', 'Abu Dhabi'),
    ('Al Ain City', 'Al Ain'),
    ('Al Nahda', 'Sharjah'),
    ('Al Majaz', 'Sharjah'),
    ('Al Khan', 'Sharjah'),
    ('Muwaileh', 'Sharjah'),
    ('University City', 'Sharjah'),
    ('Ajman Downtown', 'Ajman'),
    ('Al Nuaimiya', 'Ajman'),
    ('Ras Al Khaimah City', 'Ras Al Khaimah'),
    ('Al Hamra', 'Ras Al Khaimah'),
    ('Fujairah City', 'Fujairah'),
    ('Umm Al Quwain City', 'Umm Al Quwain'),
  ];
}
