// lib/core/utils/color_utils.dart
import 'package:flutter/material.dart';

class ColorUtils {
  static Color parseHexColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha channel
      }
      int val = int.parse(hexColor, radix: 16);
      return Color(val);
    } catch (e) {
      print('Error parsing hex color: $e');
      return Colors.grey; // Fallback color
    }
  }

  // ✅ ADD this method that was missing
  static Color getCategoryFallbackColor(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return const Color(0xFFFF6B6B);
      case 'nutrition':
        return const Color(0xFF4ECDC4);
      case 'mindfulness':
        return const Color(0xFF45B7D1);
      case 'productivity':
        return const Color(0xFF96CEB4);
      case 'health':
        return const Color(0xFFFECE2F);
      case 'social':
        return const Color(0xFFE17055);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  // ✅ Helper method to get habit color (custom or fallback)
  static Color getHabitColor(String customColor, String category) {
    // Use custom color if available
    if (customColor.isNotEmpty) {
      return parseHexColor(customColor);
    }

    // Fallback to category color
    return getCategoryFallbackColor(category);
  }
}
