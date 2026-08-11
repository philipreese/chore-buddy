import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seed_colors.dart';

class AppThemeState {
  final AppThemeId themeId;
  final ThemeMode themeMode;

  const AppThemeState({
    this.themeId = AppThemeId.chambray,
    this.themeMode = ThemeMode.system,
  });

  AppThemeState copyWith({
    AppThemeId? themeId,
    ThemeMode? themeMode,
  }) {
    return AppThemeState(
      themeId: themeId ?? this.themeId,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeState &&
          runtimeType == other.runtimeType &&
          themeId == other.themeId &&
          themeMode == other.themeMode;

  @override
  int get hashCode => themeId.hashCode ^ themeMode.hashCode;
}

class AppThemeNotifier extends Notifier<AppThemeState> {
  @override
  AppThemeState build() {
    return const AppThemeState();
  }

  void setThemeId(AppThemeId themeId) {
    state = state.copyWith(themeId: themeId);
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }
}

final themeProvider = NotifierProvider<AppThemeNotifier, AppThemeState>(
  AppThemeNotifier.new,
);
