import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/box_names.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsRepository {
  late Box _box;

  SettingsRepository() {
    _box = Hive.box(BoxNames.settings);
  }

  // Currency
  String getCurrency() {
    return _box.get('currency', defaultValue: 'USD');
  }

  Future<void> setCurrency(String currencyCode) async {
    await _box.put('currency', currencyCode);
  }

  // Theme
  String getThemeMode() {
    return _box.get('theme', defaultValue: 'system'); // system, light, dark
  }

  Future<void> setThemeMode(String mode) async {
    await _box.put('theme', mode);
  }

  // Security
  bool getBiometricsEnabled() {
    return _box.get('biometrics_enabled', defaultValue: false);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _box.put('biometrics_enabled', enabled);
  }

  // Notifications
  bool getDailyReminderEnabled() {
    return _box.get('daily_reminder_enabled', defaultValue: false);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _box.put('daily_reminder_enabled', enabled);
  }

  String getDailyReminderTime() {
    return _box.get('daily_reminder_time', defaultValue: '20:00'); // Default 8 PM
  }

  Future<void> setDailyReminderTime(String time) async {
    await _box.put('daily_reminder_time', time);
  }
}
