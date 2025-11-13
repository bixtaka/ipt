import 'package:flutter/material.dart';

class Validators {
  // 数値の検証
  static bool isValidNumber(String value) {
    if (value.isEmpty) return true; // 空は許可
    return double.tryParse(value) != null;
  }

  // 時間形式の検証 (MM:SS)
  static bool isValidTime(String value) {
    if (value.isEmpty) return true;
    final regex = RegExp(r'^([0-5]?[0-9]):([0-5][0-9])$');
    if (!regex.hasMatch(value)) return false;

    final parts = value.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);

    return minutes >= 0 && minutes <= 59 && seconds >= 0 && seconds <= 59;
  }

  // 温度の検証 (0-1000度)
  static bool isValidTemperature(String value) {
    if (value.isEmpty) return true;
    final temp = double.tryParse(value);
    return temp != null && temp >= 0 && temp <= 1000;
  }

  // 電流の検証 (0-500A)
  static bool isValidCurrent(String value) {
    if (value.isEmpty) return true;
    final current = double.tryParse(value);
    return current != null && current >= 0 && current <= 500;
  }

  // 電圧の検証 (0-50V)
  static bool isValidVoltage(String value) {
    if (value.isEmpty) return true;
    final voltage = double.tryParse(value);
    return voltage != null && voltage >= 0 && voltage <= 50;
  }

  // 速度の検証 (0-100 cm/min)
  static bool isValidSpeed(String value) {
    if (value.isEmpty) return true;
    final speed = double.tryParse(value);
    return speed != null && speed >= 0 && speed <= 100;
  }

  // 入熱の検証 (0-100 kJ/cm)
  static bool isValidHeatInput(String value) {
    if (value.isEmpty) return true;
    final heatInput = double.tryParse(value);
    return heatInput != null && heatInput >= 0 && heatInput <= 100;
  }

  // 板厚の検証 (0-100 mm)
  static bool isValidThickness(String value) {
    if (value.isEmpty) return true;
    final thickness = double.tryParse(value);
    return thickness != null && thickness >= 0 && thickness <= 100;
  }

  // 溶接長の検証 (0-1000 cm)
  static bool isValidWeldingLength(String value) {
    if (value.isEmpty) return true;
    final length = double.tryParse(value);
    return length != null && length >= 0 && length <= 1000;
  }

  // 気温の検証 (-50-50度)
  static bool isValidAmbientTemperature(String value) {
    if (value.isEmpty) return true;
    final temp = double.tryParse(value);
    return temp != null && temp >= -50 && temp <= 50;
  }

  // 開先角度の検証 (0-90度)
  static bool isValidGrooveAngle(String value) {
    if (value.isEmpty) return true;
    // "35°" のような形式を処理
    final cleanValue = value.replaceAll('°', '');
    final angle = double.tryParse(cleanValue);
    return angle != null && angle >= 0 && angle <= 90;
  }

  // ルート間隔の検証 (0-20 mm)
  static bool isValidRootGap(String value) {
    if (value.isEmpty) return true;
    final gap = double.tryParse(value);
    return gap != null && gap >= 0 && gap <= 20;
  }

  // 積層数の検証 (1-50)
  static bool isValidLayerCount(String value) {
    if (value.isEmpty) return true;
    final count = int.tryParse(value);
    return count != null && count >= 1 && count <= 50;
  }

  // エラーメッセージの取得
  static String? getErrorMessage(
      String value, String fieldName, bool Function(String) validator) {
    if (!validator(value)) {
      switch (fieldName) {
        case '温度':
          return '温度は0-1000度の範囲で入力してください';
        case '電流':
          return '電流は0-500Aの範囲で入力してください';
        case '電圧':
          return '電圧は0-50Vの範囲で入力してください';
        case '速度':
          return '速度は0-100 cm/minの範囲で入力してください';
        case '入熱':
          return '入熱は0-100 kJ/cmの範囲で入力してください';
        case '板厚':
          return '板厚は0-100 mmの範囲で入力してください';
        case '溶接長':
          return '溶接長は0-1000 cmの範囲で入力してください';
        case '気温':
          return '気温は-50-50度の範囲で入力してください';
        case '開先角度':
          return '開先角度は0-90度の範囲で入力してください';
        case 'ルート間隔':
          return 'ルート間隔は0-20 mmの範囲で入力してください';
        case '積層数':
          return '積層数は1-50の範囲で入力してください';
        case '時間':
          return '時間はMM:SS形式で入力してください';
        default:
          return '正しい数値を入力してください';
      }
    }
    return null;
  }

  // null / 空文字の検証（必須入力）
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameを入力してください';
    }
    return null;
  }

  // 非負整数の検証（空は許容、入力があれば0以上の整数であること）
  static String? validateNonNegativeInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    final intVal = int.tryParse(value.trim());
    if (intVal == null || intVal < 0) {
      return '$fieldNameは0以上の整数で入力してください';
    }
    return null;
  }

  // 非負小数の検証（空は許容、入力があれば0以上の数値であること）
  static String? validateNonNegativeDecimal(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    final doubleVal = double.tryParse(value.trim());
    if (doubleVal == null || doubleVal < 0) {
      return '$fieldNameは0以上の数値（小数可）で入力してください';
    }
    return null;
  }

  // 必須選択（ドロップダウン）の検証
  static String? validateRequiredSelection(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameを選択してください';
    }
    return null;
  }

  // 互換ラッパー（既存の validate* 系をそのまま利用）
  // requiredText: null/空文字チェック（必須）
  static String? requiredText(String? value, String fieldName) {
    return validateNotEmpty(value, fieldName);
  }

  // nonNegativeInt: 非負整数チェック（空は許容、入力があれば0以上の整数）
  static String? nonNegativeInt(String? value, String fieldName) {
    return validateNonNegativeInteger(value, fieldName);
  }

  // nonNegativeDouble: 非負小数チェック（空は許容、入力があれば0以上の数値）
  static String? nonNegativeDouble(String? value, String fieldName) {
    return validateNonNegativeDecimal(value, fieldName);
  }

  // requiredSelection: 必須選択（ドロップダウン）チェック
  static String? requiredSelection(String? value, String fieldName) {
    return validateRequiredSelection(value, fieldName);
  }

  // 全体的なデータ検証
  static Map<String, String> validateAllData(
    List<TextEditingController> infoControllers,
    List<List<TextEditingController>> measurementControllers,
    List<String> infoLabels,
  ) {
    final errors = <String, String>{};

    // 情報データの検証
    for (int i = 0; i < infoControllers.length; i++) {
      final value = infoControllers[i].text;
      final label = infoLabels[i];

      String? error;
      switch (label) {
        case '板厚':
          error = getErrorMessage(value, label, isValidThickness);
          break;
        case '溶接長':
          error = getErrorMessage(value, label, isValidWeldingLength);
          break;
        case '気温':
          error = getErrorMessage(value, label, isValidAmbientTemperature);
          break;
        case '開先角度':
          error = getErrorMessage(value, label, isValidGrooveAngle);
          break;
        case 'ルート間隔':
          error = getErrorMessage(value, label, isValidRootGap);
          break;
        case '積層数':
          error = getErrorMessage(value, label, isValidLayerCount);
          break;
      }

      if (error != null) {
        errors['info_$i'] = error;
      }
    }

    // 測定データの検証
    for (int row = 0; row < measurementControllers.length; row++) {
      for (int col = 0; col < measurementControllers[row].length; col++) {
        final value = measurementControllers[row][col].text;
        if (value.isEmpty) continue;

        String? error;
        switch (col) {
          case 1: // パス間温度開始
          case 2: // パス間温度終了
            error = getErrorMessage(value, '温度', isValidTemperature);
            break;
          case 3: // 入熱
            error = getErrorMessage(value, '入熱', isValidHeatInput);
            break;
          case 4: // 電流
            error = getErrorMessage(value, '電流', isValidCurrent);
            break;
          case 5: // 電圧
            error = getErrorMessage(value, '電圧', isValidVoltage);
            break;
          case 6: // 速度
            error = getErrorMessage(value, '速度', isValidSpeed);
            break;
          case 7: // 溶接時間
          case 8: // 作業開始
          case 9: // 作業終了
          case 10: // インターバル
            error = getErrorMessage(value, '時間', isValidTime);
            break;
        }

        if (error != null) {
          errors['measurement_${row}_${col}'] = error;
        }
      }
    }

    return errors;
  }
}
