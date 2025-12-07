/// String extensions for utility methods
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Capitalize first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
  
  /// Truncate string to specified length
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
  
  /// Remove all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');
  
  /// Check if string contains only numbers
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);
  
  /// Check if valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }
  
  /// Parse to int safely
  int? toIntOrNull() => int.tryParse(this);
  
  /// Parse to double safely
  double? toDoubleOrNull() => double.tryParse(this);
  
  /// Check if URL
  bool get isUrl {
    return RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$',
    ).hasMatch(this);
  }
}

/// Nullable string extensions
extension NullableStringExtension on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  
  /// Get value or default
  String orDefault(String defaultValue) => this ?? defaultValue;
  
  /// Get value or empty string
  String get orEmpty => this ?? '';
}

