import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart'; // pubspec.yamlで追加しているはず
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'screens/measurement_screen.dart'; // ← これを追加

void main() {
  runApp(const MyApp());
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  final formatted = formatter.format(now);
  print(formatted); // 例: 2025-05-23 18:30:00
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '測定値入力',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue, // メインカラー
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 243, 247, 250), // 薄い青系
        // 他にもaccentColor, textThemeなどカスタマイズ可能
      ),
      home: const MeasurementTabbedScreen(),
    );
  }
}
