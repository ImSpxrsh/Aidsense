class AppRegExp {
  static bool isNameValid(String name) {
    return RegExp(r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$").hasMatch(name);
  }

  static bool isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  static bool isPhoneNumberValid(String phoneNumber) {
    return RegExp(r"^(?:[+0]9)?[0-9]{10}$").hasMatch(phoneNumber);
  }

  static bool isOTPValid(String otp) {
    return RegExp(r"^[0-9]{6}$").hasMatch(otp);
  }

  static bool isNationalIDValid(String nationalID) {
    return RegExp(r"^[0-9]{10}$").hasMatch(nationalID);
  }

  static bool isCardCVVValid(String cardCVV) {
    return RegExp(r"^[0-9]{3,4}$").hasMatch(cardCVV);
  }

  static bool isPasswordValid(String password) {
    return hasLowerCase(password) &&
        hasUpperCase(password) &&
        hasNumber(password) &&
        hasSpecialCharacters(password) &&
        hasMinLength(password);
  }

  static bool hasLowerCase(String password) {
    return password.contains(RegExp(r'[a-z]'));
  }

  static bool hasUpperCase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  static bool hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  static bool hasSpecialCharacters(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  static bool hasMinLength(String password) {
    return password.length >= 6;
  }
}
