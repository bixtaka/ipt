// lib/models/pass_record.dart
import 'package:flutter/foundation.dart';

@immutable
class PassRecord {
  final int index; // 1始まり想定
  final int? tStart;
  final int? tEnd;
  final int? amps;
  final int? volts;
  final String? note;

  // 追加：計算フィールド
  final double? weldTimeSec; // 溶接時間（秒）
  final double? speed; // 速度
  final double? heatInput; // 入熱
  final double? pauseSec; // 停止時間（秒）
  final double? totalSec; // トータル（秒）

  const PassRecord({
    required this.index,
    this.tStart,
    this.tEnd,
    this.amps,
    this.volts,
    this.note,
    this.weldTimeSec, // ← 追加
    this.speed, // ← 追加
    this.heatInput, // ← 追加
    this.pauseSec, // ← 追加
    this.totalSec, // ← 追加
  });

  PassRecord copyWith({
    int? index,
    int? tStart,
    int? tEnd,
    int? amps,
    int? volts,
    String? note,
    double? weldTimeSec,
    double? speed,
    double? heatInput,
    double? pauseSec,
    double? totalSec,
  }) {
    return PassRecord(
      index: index ?? this.index,
      tStart: tStart ?? this.tStart,
      tEnd: tEnd ?? this.tEnd,
      amps: amps ?? this.amps,
      volts: volts ?? this.volts,
      note: note ?? this.note,
      weldTimeSec: weldTimeSec ?? this.weldTimeSec,
      speed: speed ?? this.speed,
      heatInput: heatInput ?? this.heatInput,
      pauseSec: pauseSec ?? this.pauseSec,
      totalSec: totalSec ?? this.totalSec,
    );
  }

  @override
  String toString() =>
      'PassRecord(index: $index, tStart: $tStart, tEnd: $tEnd, '
      'amps: $amps, volts: $volts, note: $note, '
      'weldTimeSec: $weldTimeSec, speed: $speed, heatInput: $heatInput, '
      'pauseSec: $pauseSec, totalSec: $totalSec)';

  @override
  int get hashCode => Object.hash(
      index, tStart, tEnd, amps, volts, note, weldTimeSec, speed, heatInput, pauseSec, totalSec);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassRecord &&
          index == other.index &&
          tStart == other.tStart &&
          tEnd == other.tEnd &&
          amps == other.amps &&
          volts == other.volts &&
          note == other.note &&
          weldTimeSec == other.weldTimeSec &&
          speed == other.speed &&
          heatInput == other.heatInput &&
          pauseSec == other.pauseSec &&
          totalSec == other.totalSec);

  Map<String, dynamic> toJson() => {
    'index': index,
    'tStart': tStart,
    'tEnd': tEnd,
    'amps': amps,
    'volts': volts,
    'note': note,
    'weldTimeSec': weldTimeSec,
    'speed': speed,
    'heatInput': heatInput,
    'pauseSec': pauseSec,
    'totalSec': totalSec,
  };

  factory PassRecord.fromJson(Map<String, dynamic> json) => PassRecord(
    index: json['index'] as int,
    tStart: json['tStart'] as int?,
    tEnd: json['tEnd'] as int?,
    amps: json['amps'] as int?,
    volts: json['volts'] as int?,
    note: json['note'] as String?,
    weldTimeSec: json['weldTimeSec'] as double?,
    speed: json['speed'] as double?,
    heatInput: json['heatInput'] as double?,
    pauseSec: json['pauseSec'] as double?,
    totalSec: json['totalSec'] as double?,
  );
}
