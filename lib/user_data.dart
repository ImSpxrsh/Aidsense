// Simple in-memory user data storage
class UserData {
  static String? _fullName;
  static String? _email;
  static String? _mobile;
  static String? _dateOfBirth;
  static bool _isLoggedIn = false;

  // Getters
  static String get fullName => _fullName ?? 'User';
  static String get email => _email ?? 'user@example.com';
  static String get mobile => _mobile ?? '';
  static String get dateOfBirth => _dateOfBirth ?? '';
  static bool get isLoggedIn => _isLoggedIn;

  // Setters
  static void setFullName(String name) => _fullName = name;
  static void setEmail(String email) => _email = email;
  static void setMobile(String mobile) => _mobile = mobile;
  static void setDateOfBirth(String dob) => _dateOfBirth = dob;
  static void setLoggedIn(bool loggedIn) => _isLoggedIn = loggedIn;

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
  }

  // Clear user data
  static void clearUser() {
    _fullName = null;
    _email = null;
    _mobile = null;
    _dateOfBirth = null;
    _isLoggedIn = false;
  }

  // Update profile
  static void updateProfile({
    String? fullName,
    String? email,
    String? mobile,
    String? dateOfBirth,
  }) {
    if (fullName != null) _fullName = fullName;
    if (email != null) _email = email;
    if (mobile != null) _mobile = mobile;
    if (dateOfBirth != null) _dateOfBirth = dateOfBirth;
  }
}
