// lib/models/job_settings.dart
import 'package:flutter/foundation.dart';

@immutable
class JobSettings {
  final String? projectName;
  final DateTime measurementDate;
  final String? productCode;
  final String? location;
  final String? part; // 部材
  final String? material;
  final String? grooveAngle;
  final String? rootGap;
  final String? posture; // 溶接姿勢
  final double? weldingLengthCm; // 溶接長[cm]
  final String? weather; // 天候
  final double? ambientTempC; // 気温[°C]
  final double? humidityPercent; // 湿度[%]

  JobSettings({
    this.projectName,
    DateTime? measurementDate, // const を外す
    this.productCode,
    this.location,
    this.part,
    this.material,
    this.grooveAngle,
    this.rootGap,
    this.posture,
    this.weldingLengthCm,
    this.weather,
    this.ambientTempC,
    this.humidityPercent,
  }) : measurementDate = measurementDate ?? DateTime.now();

  JobSettings copyWith({
    String? projectName,
    DateTime? measurementDate,
    String? productCode,
    String? location,
    String? part,
    String? material,
    String? grooveAngle,
    String? rootGap,
    String? posture,
    double? weldingLengthCm,
    String? weather,
    double? ambientTempC,
    double? humidityPercent,
  }) {
    return JobSettings(
      projectName: projectName ?? this.projectName,
      measurementDate: measurementDate ?? this.measurementDate,
      productCode: productCode ?? this.productCode,
      location: location ?? this.location,
      part: part ?? this.part,
      material: material ?? this.material,
      grooveAngle: grooveAngle ?? this.grooveAngle,
      rootGap: rootGap ?? this.rootGap,
      posture: posture ?? this.posture,
      weldingLengthCm: weldingLengthCm ?? this.weldingLengthCm,
      weather: weather ?? this.weather,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      humidityPercent: humidityPercent ?? this.humidityPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'measurementDate': measurementDate.toIso8601String(),
        'productCode': productCode,
        'location': location,
        'part': part,
        'material': material,
        'grooveAngle': grooveAngle,
        'rootGap': rootGap,
        'posture': posture,
        'weldingLengthCm': weldingLengthCm,
        'weather': weather,
        'ambientTempC': ambientTempC,
        'humidityPercent': humidityPercent,
      };

  factory JobSettings.fromJson(Map<String, dynamic> j) => JobSettings(
        projectName: j['projectName'] as String?,
        measurementDate: j['measurementDate'] != null
            ? DateTime.parse(j['measurementDate'] as String)
            : null,
        productCode: j['productCode'] as String?,
        location: j['location'] as String?,
        part: j['part'] as String?,
        material: j['material'] as String?,
        grooveAngle: j['grooveAngle'] as String?,
        rootGap: j['rootGap'] as String?,
        posture: j['posture'] as String?,
        weldingLengthCm: (j['weldingLengthCm'] as num?)?.toDouble(),
        weather: j['weather'] as String?,
        ambientTempC: (j['ambientTempC'] as num?)?.toDouble(),
        humidityPercent: (j['humidityPercent'] as num?)?.toDouble(),
      );
}
