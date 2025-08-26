// lib/core/utils/validators.dart
class Validators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  static String? habitName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Habit name is required';
    }

    if (value.trim().length < 3) {
      return 'Habit name must be at least 3 characters long';
    }

    if (value.trim().length > 50) {
      return 'Habit name must be less than 50 characters';
    }

    return null;
  }

  static String? positiveInteger(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final intValue = int.tryParse(value.trim());
    if (intValue == null || intValue <= 0) {
      return '${fieldName ?? 'This field'} must be a positive number';
    }

    return null;
  }
}
