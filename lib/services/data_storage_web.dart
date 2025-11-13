import 'dart:convert';
import 'package:flutter/material.dart';

// 移行: 直接 dart:html を使わずにプラットフォームごとの実装を条件付きでエクスポートする
export 'data_storage_web_impl_stub.dart'
    if (dart.library.html) 'data_storage_web_impl_html.dart';

class DataStorageService {
  static const String _infoDataKey = 'measurement_info_data';
  static const String _measurementDataKey = 'measurement_table_data';
  static const String _lastSavedKey = 'last_saved_timestamp';

  static Future<void> saveInfoData(
      List<TextEditingController> controllers) async {
    final data = controllers.map((controller) => controller.text).toList();
    final jsonData = jsonEncode(data);
    _setItem(_infoDataKey, jsonData);
    _setItem(_lastSavedKey, DateTime.now().toIso8601String());
  }

  static Future<List<String>> loadInfoData() async {
    final jsonData = _getItem(_infoDataKey);
    if (jsonData != null) {
      return List<String>.from(jsonDecode(jsonData));
    }
    return [];
  }

  static Future<void> saveMeasurementData(
      List<List<TextEditingController>> controllers) async {
    final data = controllers
        .map((row) => row.map((controller) => controller.text).toList())
        .toList();
    final jsonData = jsonEncode(data);
    _setItem(_measurementDataKey, jsonData);
    _setItem(_lastSavedKey, DateTime.now().toIso8601String());
  }

  static Future<List<List<String>>> loadMeasurementData() async {
    final jsonData = _getItem(_measurementDataKey);
    if (jsonData != null) {
      return List<List<String>>.from(
          jsonDecode(jsonData).map((row) => List<String>.from(row)));
    }
    return [];
  }

  static DateTime? getLastSavedTime() {
    final timestamp = _getItem(_lastSavedKey);
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  static Future<void> clearAllData() async {
    _removeItem(_infoDataKey);
    _removeItem(_measurementDataKey);
    _removeItem(_lastSavedKey);
  }

  static bool hasSavedData() {
    return _getItem(_infoDataKey) != null ||
        _getItem(_measurementDataKey) != null;
  }
}

// ローカルフォールバック実装（Web 環境が未整備でもビルドが通るように in-memory ストレージを用意）
final Map<String, String> _inMemoryStorage = <String, String>{};

void _setItem(String key, String value) {
  _inMemoryStorage[key] = value;
}

String? _getItem(String key) {
  return _inMemoryStorage[key];
}

void _removeItem(String key) {
  _inMemoryStorage.remove(key);
}
