import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_settings.dart';
import '../models/job_settings_codec.dart';

class JobSettingsStorage {
  static const String _settingsKey = 'job_settings_v1';

  static Future<JobSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      return decodeJobSettings(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(JobSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final data = encodeJobSettings(settings);
    await prefs.setString(_settingsKey, jsonEncode(data));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}
