import 'package:flutter/material.dart';

enum AppThemeId {
  chambray,
  blueStone,
  russet,
  affair,
  spicyMustard,
  woodland,
  dynamicTheme,
}

extension AppThemeIdExtension on AppThemeId {
  String get displayName {
    switch (this) {
      case AppThemeId.chambray:
        return 'Chambray';
      case AppThemeId.blueStone:
        return 'Blue Stone';
      case AppThemeId.russet:
        return 'Russet';
      case AppThemeId.affair:
        return 'Affair';
      case AppThemeId.spicyMustard:
        return 'Spicy Mustard';
      case AppThemeId.woodland:
        return 'Woodland';
      case AppThemeId.dynamicTheme:
        return 'Dynamic';
    }
  }

  Color get seedColor {
    switch (this) {
      case AppThemeId.chambray:
        return const Color(0xFF415F91);
      case AppThemeId.blueStone:
        return const Color(0xFF006A62);
      case AppThemeId.russet:
        return const Color(0xFF855317);
      case AppThemeId.affair:
        return const Color(0xFF775084);
      case AppThemeId.spicyMustard:
        return const Color(0xFF6D5E0F);
      case AppThemeId.woodland:
        return const Color(0xFF4C662B);
      case AppThemeId.dynamicTheme:
        return const Color(0xFF415F91); // Fallback seed color
    }
  }
}
