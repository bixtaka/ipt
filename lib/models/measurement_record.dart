import 'dart:math';

import 'job_settings.dart';
import 'job_settings_codec.dart';
import 'pass_record.dart';

class MeasurementRecord {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JobSettings settings;
  final List<PassRecord> passes;

  MeasurementRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    required this.passes,
  });

  factory MeasurementRecord.newRecord({
    required JobSettings settings,
    required List<PassRecord> passes,
  }) {
    final now = DateTime.now();
      return MeasurementRecord(
        id: _genId(),
        createdAt: now,
        updatedAt: now,
        settings: settings,
        passes: List<PassRecord>.from(passes),
      );
  }

  MeasurementRecord copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    JobSettings? settings,
    List<PassRecord>? passes,
  }) {
    return MeasurementRecord(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      passes: passes ?? this.passes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'settings': encodeJobSettings(settings),
        'passes': passes.map((p) => p.toJson()).toList(),
      };

  factory MeasurementRecord.fromJson(Map<String, dynamic> j) => MeasurementRecord(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        settings: decodeJobSettings(j['settings'] as Map<String, dynamic>),
        passes: (j['passes'] as List<dynamic>)
            .map((e) => PassRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

String _genId() {
  // Simple unique id using timestamp + random suffix
  final ts = DateTime.now().millisecondsSinceEpoch;
  final r = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return 'rec_${ts}_$r';
}
