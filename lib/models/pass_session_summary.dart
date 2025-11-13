// lib/models/pass_session_summary.dart
import 'package:flutter/foundation.dart';

@immutable
class PassSessionSummary {
  /// 実作業（溶接）時間 [s]
  final double workSec;

  /// 停止（中断）時間 [s]
  final double pauseSec;

  /// トータル（開始〜停止）時間 [s]（停止前は null 可）
  final double? totalSec;

  const PassSessionSummary({
    required this.workSec,
    required this.pauseSec,
    required this.totalSec,
  });

  factory PassSessionSummary.zero() =>
      const PassSessionSummary(workSec: 0, pauseSec: 0, totalSec: null);

  PassSessionSummary copyWith({
    double? workSec,
    double? pauseSec,
    double? totalSec,
  }) =>
      PassSessionSummary(
        workSec: workSec ?? this.workSec,
        pauseSec: pauseSec ?? this.pauseSec,
        totalSec: totalSec ?? this.totalSec,
      );

  Map<String, dynamic> toJson() => {
        'workSec': workSec,
        'pauseSec': pauseSec,
        'totalSec': totalSec,
      };

  factory PassSessionSummary.fromJson(Map<String, dynamic> j) =>
      PassSessionSummary(
        workSec: (j['workSec'] as num?)?.toDouble() ?? 0.0,
        pauseSec: (j['pauseSec'] as num?)?.toDouble() ?? 0.0,
        totalSec: (j['totalSec'] as num?)?.toDouble(),
      );

  @override
  String toString() =>
      'PassSessionSummary(work:$workSec, pause:$pauseSec, total:$totalSec)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassSessionSummary &&
          workSec == other.workSec &&
          pauseSec == other.pauseSec &&
          totalSec == other.totalSec;

  @override
  int get hashCode => Object.hash(workSec, pauseSec, totalSec);
}
