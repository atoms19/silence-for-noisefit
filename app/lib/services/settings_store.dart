/// Small persistent key/value store for app preferences.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class MemorySettingsStore implements SettingsStore {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

class PrefsSettingsStore implements SettingsStore {
  @override
  Future<String?> getString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> setString(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
  @override
  Future<void> remove(String key) async =>
      (await SharedPreferences.getInstance()).remove(key);
}
