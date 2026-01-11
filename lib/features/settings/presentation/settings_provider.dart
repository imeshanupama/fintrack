import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

// State class for Settings
class SettingsState {
  final String currency;
  final ThemeMode themeMode;
  final bool isBiometricsEnabled;
  final bool isDailyReminderEnabled;
  final String dailyReminderTime;

  SettingsState({
    required this.currency,
    required this.themeMode,
    required this.isBiometricsEnabled,
    required this.isDailyReminderEnabled,
    required this.dailyReminderTime,
  });

  SettingsState copyWith({
    String? currency, 
    ThemeMode? themeMode, 
    bool? isBiometricsEnabled,
    bool? isDailyReminderEnabled,
    String? dailyReminderTime,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isDailyReminderEnabled: isDailyReminderEnabled ?? this.isDailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsRepository _repository;

  @override
  SettingsState build() {
    _repository = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      currency: _repository.getCurrency(),
      themeMode: _parseThemeMode(_repository.getThemeMode()),
      isBiometricsEnabled: _repository.getBiometricsEnabled(),
      isDailyReminderEnabled: _repository.getDailyReminderEnabled(),
      dailyReminderTime: _repository.getDailyReminderTime(),
    );
  }

  Future<void> setCurrency(String currencyCode) async {
    await _repository.setCurrency(currencyCode);
    state = state.copyWith(currency: currencyCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(_typeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _repository.setBiometricsEnabled(enabled);
    state = state.copyWith(isBiometricsEnabled: enabled);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _repository.setDailyReminderEnabled(enabled);
    state = state.copyWith(isDailyReminderEnabled: enabled);
  }

  Future<void> setDailyReminderTime(String time) async {
    await _repository.setDailyReminderTime(time);
    state = state.copyWith(dailyReminderTime: time);
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _typeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
