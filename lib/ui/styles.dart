import 'package:flutter/material.dart';

class AppStyles {
  // Touch target sizes (accessibility)
  static const double minTouchTarget = 44.0;
  static const double buttonHeight = 48.0;
  static const double iconButtonSize = 48.0;

  // Typography
  static const double bodyLargeSize = 18.0;
  static const double bodyMediumSize = 16.0;
  static const double bodySmallSize = 14.0;
  static const double captionSize = 12.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;

  // Validation ranges
  static const int minTemperature = 0;
  static const int maxTemperature = 1000;
  static const int minAmps = 0;
  static const int maxAmps = 500;
  static const int minVolts = 0;
  static const int maxVolts = 50;

  // Text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: bodyMediumSize,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: bodySmallSize,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  // Input field styles
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    String? suffixText,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey.shade400,
          width: hasError ? 2.0 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.blue,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
    );
  }

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, buttonHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusS),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade200,
    foregroundColor: Colors.black87,
    minimumSize: const Size(0, buttonHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusS),
    ),
  );

  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, buttonHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusS),
    ),
  );

  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade300,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Validation helpers
  static bool isValidTemperature(int? value) {
    if (value == null) return true;
    return value >= minTemperature && value <= maxTemperature;
  }

  static bool isValidAmps(int? value) {
    if (value == null) return true;
    return value >= minAmps && value <= maxAmps;
  }

  static bool isValidVolts(int? value) {
    if (value == null) return true;
    return value >= minVolts && value <= maxVolts;
  }

  static Color getValidationColor(int? value, bool Function(int?) validator) {
    if (value == null) return Colors.grey.shade400;
    return validator(value) ? Colors.grey.shade400 : Colors.red;
  }
}
