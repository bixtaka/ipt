// lib/models/pass_record.dart
import 'package:flutter/foundation.dart';

@immutable
enum SegmentType { welding, stop }

@immutable
class TimeSegment {
  final DateTime start;
  final DateTime? end;
  final SegmentType type;

  const TimeSegment({required this.start, this.end, required this.type});

  Duration durationAt(DateTime now) {
    final e = end ?? now;
    return e.isAfter(start) ? e.difference(start) : Duration.zero;
  }

  TimeSegment close(DateTime at) {
    if (end != null) return this;
    final safeEnd = at.isAfter(start) ? at : start;
    return TimeSegment(start: start, end: safeEnd, type: type);
  }

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'type': type.name,
      };

  factory TimeSegment.fromJson(Map<String, dynamic> j) => TimeSegment(
        start: DateTime.parse(j['start'] as String),
        end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
        type: SegmentType.values
            .firstWhere((e) => e.name == (j['type'] as String? ?? 'welding'),
                orElse: () => SegmentType.welding),
      );
}

@immutable
class PassRecord {
  final int index; // 1-based index
  final int? tStart;
  final int? tEnd;
  final int? amps;
  final int? volts;
  final String? note;
  // New metadata fields
  final String? passLayer; // パス/層
  final String? slag; // スラグ

  // Derived values kept for backward compatibility with existing UI
  final double? weldTimeSec; // seconds
  final double? speed; // cm/min (if used by other parts)
  final double? heatInput; // kJ/cm
  final double? pauseSec; // seconds
  final double? totalSec; // seconds

  // New: segment-based structure
  final List<TimeSegment> segments;

  const PassRecord({
    required this.index,
    this.tStart,
    this.tEnd,
    this.amps,
    this.volts,
    this.note,
    this.passLayer,
    this.slag,
    this.weldTimeSec,
    this.speed,
    this.heatInput,
    this.pauseSec,
    this.totalSec,
    List<TimeSegment>? segments,
  }) : segments = segments ?? const [];

  PassRecord copyWith({
    int? index,
    int? tStart,
    int? tEnd,
    int? amps,
    int? volts,
    String? note,
    String? passLayer,
    String? slag,
    double? weldTimeSec,
    double? speed,
    double? heatInput,
    double? pauseSec,
    double? totalSec,
    List<TimeSegment>? segments,
  }) {
    return PassRecord(
      index: index ?? this.index,
      tStart: tStart ?? this.tStart,
      tEnd: tEnd ?? this.tEnd,
      amps: amps ?? this.amps,
      volts: volts ?? this.volts,
      note: note ?? this.note,
      passLayer: passLayer ?? this.passLayer,
      slag: slag ?? this.slag,
      weldTimeSec: weldTimeSec ?? this.weldTimeSec,
      speed: speed ?? this.speed,
      heatInput: heatInput ?? this.heatInput,
      pauseSec: pauseSec ?? this.pauseSec,
      totalSec: totalSec ?? this.totalSec,
      segments: segments ?? this.segments,
    );
  }

  @override
  String toString() =>
      'PassRecord(index: $index, tStart: $tStart, tEnd: $tEnd, '
      'amps: $amps, volts: $volts, note: $note, '
      'weldTimeSec: $weldTimeSec, speed: $speed, heatInput: $heatInput, '
      'pauseSec: $pauseSec, totalSec: $totalSec, segments: ${segments.length})';

  @override
  int get hashCode => Object.hash(
        index,
        tStart,
        tEnd,
        amps,
        volts,
        note,
        passLayer,
        slag,
        weldTimeSec,
        speed,
        heatInput,
        pauseSec,
        totalSec,
        Object.hashAll(segments),
      );

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
          passLayer == other.passLayer &&
          slag == other.slag &&
          weldTimeSec == other.weldTimeSec &&
          speed == other.speed &&
          heatInput == other.heatInput &&
          pauseSec == other.pauseSec &&
          totalSec == other.totalSec &&
          listEquals(segments, other.segments));

  Map<String, dynamic> toJson() => {
        'index': index,
        'tStart': tStart,
        'tEnd': tEnd,
        'amps': amps,
        'volts': volts,
        'note': note,
        'passLayer': passLayer,
        'slag': slag,
        'weldTimeSec': weldTimeSec,
        'speed': speed,
        'heatInput': heatInput,
        'pauseSec': pauseSec,
        'totalSec': totalSec,
        'segments': segments.map((e) => e.toJson()).toList(),
      };

  factory PassRecord.fromJson(Map<String, dynamic> json) => PassRecord(
        index: json['index'] as int,
        tStart: json['tStart'] as int?,
        tEnd: json['tEnd'] as int?,
        amps: json['amps'] as int?,
        volts: json['volts'] as int?,
        note: json['note'] as String?,
        passLayer: json['passLayer'] as String?,
        slag: json['slag'] as String?,
        weldTimeSec: json['weldTimeSec'] as double?,
        speed: json['speed'] as double?,
        heatInput: json['heatInput'] as double?,
        pauseSec: json['pauseSec'] as double?,
        totalSec: json['totalSec'] as double?,
        segments: (json['segments'] as List<dynamic>? ?? const [])
            .map((e) => TimeSegment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // Segment API
  PassRecord startSegment(SegmentType type, DateTime at) {
    final updated = endOpenSegment(at);
    final segs = List<TimeSegment>.from(updated.segments)
      ..add(TimeSegment(start: at, type: type));
    return updated.copyWith(segments: segs);
  }

  PassRecord endOpenSegment(DateTime at) {
    if (segments.isEmpty) return this;
    final last = segments.last;
    if (last.end != null) return this;
    final closed = last.close(at);
    final segs = List<TimeSegment>.from(segments)..[segments.length - 1] = closed;
    return copyWith(segments: segs);
  }

  Duration sum({required SegmentType type, DateTime? now}) {
    final n = now ?? DateTime.now();
    return segments
        .where((s) => s.type == type)
        .fold(Duration.zero, (a, s) => a + s.durationAt(n));
  }

  Duration get weldingTotal => sum(type: SegmentType.welding);
  Duration get stopTotal => sum(type: SegmentType.stop);
}
