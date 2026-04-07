// Simple in-memory user data storage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserData {
  static String? _fullName;
  static String? _email;
  static String? _mobile;
  static String? _dateOfBirth;
  static bool _isLoggedIn = false;
  static List<String> _favorites = [];

  // Getters
  static String get fullName => _fullName ?? 'User';
  static String get email => _email ?? 'support@aidsense.app';
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
    _email = prefs.getString('email') ?? 'support@aidsense.app';
    _mobile = prefs.getString('mobile') ?? '';
    _dateOfBirth = prefs.getString('dateOfBirth') ?? '';
    _isLoggedIn = prefs.getString('isLoggedIn') == 'true';
    final favs = prefs.getString('favorites') ?? '';
    _favorites = favs.isNotEmpty ? favs.split(',') : [];
  }

  static String? _firstNonEmptyString(
      Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static Map<String, dynamic> _profileUpsertPayload({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required List<String> favorites,
  }) {
    return {
      'uid': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'favorites': favorites,
    };
  }

  /// Ensures a `profiles` row exists (e.g. after Google OAuth). Uses same columns as email signup.
  static Future<void> ensureProfileRow() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    final fromMeta = _firstNonEmptyString(
        meta, ['full_name', 'fullName', 'name', 'given_name']);
    final email = user.email ?? '';
    final displayName = fromMeta ??
        (email.isNotEmpty ? email.split('@').first : null) ??
        'User';
    final phone = _firstNonEmptyString(meta, ['phone']) ?? '';

    Map<String, dynamic>? existing;
    try {
      existing = await Supabase.instance.client
          .from('profiles')
          .select('uid')
          .eq('uid', user.id)
          .maybeSingle();
    } catch (_) {
      try {
        existing = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {
        existing = null;
      }
    }
    if (existing != null) return;

    try {
      await Supabase.instance.client.from('profiles').upsert(
            _profileUpsertPayload(
              userId: user.id,
              fullName: displayName,
              email: email,
              phone: phone,
              favorites: const [],
            ),
          );
    } catch (_) {
      // RLS or schema mismatch — local/session state is still valid.
    }
  }

  // Supabase profile fetch
  static Future<void> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    Map<String, dynamic>? response;
    try {
      response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('uid', user.id)
          .maybeSingle();
      response ??= await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      response = null;
    }

    final meta = user.userMetadata ?? {};

    if (response != null) {
      _fullName = _firstNonEmptyString(response, ['fullName', 'full_name']) ??
          _firstNonEmptyString(meta, ['full_name', 'fullName', 'name']) ??
          (user.email != null && user.email!.isNotEmpty
              ? user.email!.split('@').first
              : 'User');
      _email = _firstNonEmptyString(response, ['email']) ??
          user.email ??
          'support@aidsense.app';
      _mobile = _firstNonEmptyString(response, ['phone', 'phone_number']) ??
          _firstNonEmptyString(meta, ['phone']) ??
          '';
      _dateOfBirth =
          _firstNonEmptyString(response, ['dateOfBirth', 'date_of_birth']) ??
              _firstNonEmptyString(meta, ['date_of_birth', 'dateOfBirth']) ??
              '';
      _favorites =
          (response['favorites'] as List?)?.map((e) => e.toString()).toList() ??
              [];
    } else {
      _fullName =
          _firstNonEmptyString(meta, ['full_name', 'fullName', 'name']) ??
              (user.email != null && user.email!.isNotEmpty
                  ? user.email!.split('@').first
                  : 'User');
      _email = user.email ?? 'support@aidsense.app';
      _mobile = _firstNonEmptyString(meta, ['phone']) ?? '';
      _dateOfBirth =
          _firstNonEmptyString(meta, ['date_of_birth', 'dateOfBirth']) ?? '';
      _favorites = [];
    }

    _isLoggedIn = true;
    await _saveToPrefs('fullName', _fullName ?? '');
    await _saveToPrefs('email', _email ?? '');
    await _saveToPrefs('mobile', _mobile ?? '');
    await _saveToPrefs('dateOfBirth', _dateOfBirth ?? '');
    await _saveToPrefs('isLoggedIn', 'true');
    await _saveToPrefs('favorites', _favorites.join(','));
  }

  static Future<void> saveToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('profiles').upsert(
          _profileUpsertPayload(
            userId: user.id,
            fullName: _fullName ?? '',
            email: _email ?? '',
            phone: _mobile ?? '',
            favorites: _favorites,
          ),
        );
  }

  static Future<void> clearSupabaseProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('profiles').delete().eq('uid', user.id);
  }
}
