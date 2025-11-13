import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataStorageService {
  static const String _infoDataKey = 'measurement_info_data';
  static const String _measurementDataKey = 'measurement_table_data';
  static const String _lastSavedKey = 'last_saved_timestamp';

  static Future<void> saveInfoData(
      List<TextEditingController> controllers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = controllers.map((controller) => controller.text).toList();
    await prefs.setString(_infoDataKey, jsonEncode(data));
    await prefs.setString(_lastSavedKey, DateTime.now().toIso8601String());
  }

  static Future<List<String>> loadInfoData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_infoDataKey);
    if (jsonData != null) {
      return List<String>.from(jsonDecode(jsonData));
    }
    return [];
  }

  static Future<void> saveMeasurementData(
      List<List<TextEditingController>> controllers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = controllers
        .map((row) => row.map((controller) => controller.text).toList())
        .toList();
    await prefs.setString(_measurementDataKey, jsonEncode(data));
    await prefs.setString(_lastSavedKey, DateTime.now().toIso8601String());
  }

  static Future<List<List<String>>> loadMeasurementData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_measurementDataKey);
    if (jsonData != null) {
      return List<List<String>>.from(
          jsonDecode(jsonData).map((row) => List<String>.from(row)));
    }
    return [];
  }

  static DateTime? getLastSavedTime() {
    // SharedPreferences は同期取得不可のため null とし、必要な場合は別API化
    return null;
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_infoDataKey);
    await prefs.remove(_measurementDataKey);
    await prefs.remove(_lastSavedKey);
  }

  static bool hasSavedData() {
    // 同期APIがないため都度判定できない。UIでは読み込み成否で判断。
    return false;
  }
}
