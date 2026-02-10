// Simple in-memory user data storage
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static String? _fullName;
  static String? _email;
  static String? _mobile;
  static String? _dateOfBirth;
  static bool _isLoggedIn = false;
  static List<String> _favorites = [];

  // Getters
  static String get fullName => _fullName ?? 'User';
  static String get email => _email ?? 'user@example.com';
  static String get mobile => _mobile ?? '';
  static String get dateOfBirth => _dateOfBirth ?? '';
  static bool get isLoggedIn => _isLoggedIn;
  static List<String> get favorites => _favorites;

  // Setters
  static void setFullName(String name) {
    _fullName = name;
    _saveToPrefs('fullName', name);
  }

  static void setEmail(String email) {
    _email = email;
    _saveToPrefs('email', email);
  }

  static void setMobile(String mobile) {
    _mobile = mobile;
    _saveToPrefs('mobile', mobile);
  }

  static void setDateOfBirth(String dob) {
    _dateOfBirth = dob;
    _saveToPrefs('dateOfBirth', dob);
  }

  static void setLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
    _saveToPrefs('isLoggedIn', loggedIn ? 'true' : 'false');
  }

  static void setFavorites(List<String> favs) {
    _favorites = favs;
    _saveToPrefs('favorites', favs.join(','));
  }

  // Save user data
  static void saveUser({
    required String fullName,
    required String email,
    required String mobile,
    required String dateOfBirth,
  }) {
    _fullName = fullName;
    _email = email;
    _mobile = mobile;
    _dateOfBirth = dateOfBirth;
    _isLoggedIn = true;
    _saveToPrefs('fullName', fullName);
    _saveToPrefs('email', email);
    _saveToPrefs('mobile', mobile);
    _saveToPrefs('dateOfBirth', dateOfBirth);
    _saveToPrefs('isLoggedIn', 'true');
  }

  // Clear user data
  static void clearUser() {
    _fullName = null;
    _email = null;
    _mobile = null;
    _dateOfBirth = null;
    _isLoggedIn = false;
    _favorites = [];
    _saveToPrefs('fullName', '');
    _saveToPrefs('email', '');
    _saveToPrefs('mobile', '');
    _saveToPrefs('dateOfBirth', '');
    _saveToPrefs('isLoggedIn', 'false');
    _saveToPrefs('favorites', '');
  }

  // Update profile
  static void updateProfile({
    String? fullName,
    String? email,
    String? mobile,
    String? dateOfBirth,
  }) {
    if (fullName != null) setFullName(fullName);
    if (email != null) setEmail(email);
    if (mobile != null) setMobile(mobile);
    if (dateOfBirth != null) setDateOfBirth(dateOfBirth);
  }

  // Favorites
  static void addFavorite(String resourceId) {
    if (!_favorites.contains(resourceId)) {
      _favorites.add(resourceId);
      setFavorites(_favorites);
    }
  }

  static void removeFavorite(String resourceId) {
    _favorites.remove(resourceId);
    setFavorites(_favorites);
  }

  // SharedPreferences helpers
  static Future<void> _saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('fullName') ?? 'User';
    _email = prefs.getString('email') ?? 'user@example.com';
    _mobile = prefs.getString('mobile') ?? '';
    _dateOfBirth = prefs.getString('dateOfBirth') ?? '';
    _isLoggedIn = prefs.getString('isLoggedIn') == 'true';
    final favs = prefs.getString('favorites') ?? '';
    _favorites = favs.isNotEmpty ? favs.split(',') : [];
  }
}
