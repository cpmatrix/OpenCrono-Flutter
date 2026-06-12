class Validators {
  static bool isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  static bool isStrongEnoughPassword(String value) {
    return value.trim().length >= 6;
  }
}
