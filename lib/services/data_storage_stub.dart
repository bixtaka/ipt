import 'package:flutter/material.dart';

class DataStorageService {
  static Future<void> saveInfoData(
      List<TextEditingController> controllers) async {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static Future<List<String>> loadInfoData() async {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static Future<void> saveMeasurementData(
      List<List<TextEditingController>> controllers) async {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static Future<List<List<String>>> loadMeasurementData() async {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static DateTime? getLastSavedTime() {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static Future<void> clearAllData() async {
    throw UnimplementedError(
        'DataStorage is not implemented for this platform');
  }

  static bool hasSavedData() {
    return false;
  }
}
