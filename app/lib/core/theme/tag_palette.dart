import 'package:flutter/material.dart';

/// Fixed 12-swatch palette for tag colors (indices 0..11).
abstract class TagPalette {
  static const List<Color> swatches = [
    Color(0xFFEF4444), // 0: Warm Red
    Color(0xFFF59E0B), // 1: Amber
    Color(0xFFFB923C), // 2: Orange
    Color(0xFF7C3AED), // 3: Purple
    Color(0xFFF472B6), // 4: Pink
    Color(0xFFD375C8), // 5: Magenta
    Color(0xFF10B981), // 6: Emerald Green
    Color(0xFF047857), // 7: Dark Green
    Color(0xFF064E3B), // 8: Deep Green
    Color(0xFF007ACC), // 9: Blue
    Color(0xFF0891B2), // 10: Cyan
    Color(0xFF003D66), // 11: Dark Blue
  ];

  static Color getColor(int index) {
    if (index >= 0 && index < swatches.length) {
      return swatches[index];
    }
    return swatches[0];
  }
}
