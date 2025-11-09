/// Input validation utilities
class Validators {
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate PIN (4 digits)
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length != 4) {
      return 'PIN must be 4 digits';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate cycle length
  static String? cycleLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cycle length is required';
    }
    final length = int.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 21 || length > 35) {
      return 'Cycle length should be between 21 and 35 days';
    }
    return null;
  }

  /// Validate period length
  static String? periodLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Period length is required';
    }
    final length = int.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 3 || length > 7) {
      return 'Period length should be between 3 and 7 days';
    }
    return null;
  }
}
