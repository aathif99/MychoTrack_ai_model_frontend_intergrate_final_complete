class Validators {
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 number (0-9)';
    }
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(password)) {
      return 'Password must contain at least 1 special character (@, #, \$, %, etc.)';
    }
    if (RegExp(r'\s').hasMatch(password)) {
      return 'Password cannot contain spaces';
    }
    return null;
  }
}
