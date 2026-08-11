import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's System/Light/Dark preference. Colors always come from dynamic
/// color (Material You) with a fixed fallback seed on devices that don't
/// support it -- see `app_theme.dart` -- so this is the only theme choice
/// left to make.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
