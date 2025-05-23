import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart'; // pubspec.yamlで追加しているはず
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'screens/measurement_screen.dart'; // ← これを追加

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '測定値入力',
      home: const MeasurementTabbedScreen(),
    );
  }
}
