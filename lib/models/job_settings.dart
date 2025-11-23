// lib/models/job_settings.dart
import 'package:flutter/foundation.dart';

@immutable
class JobSettings {
  static const Object _unset = Object();

  final int? projectId;
  final String? projectName;
  final DateTime measurementDate;
  final int? productId;
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
    this.projectId,
    this.projectName,
    DateTime? measurementDate, // const を外す
    this.productId,
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
    Object? projectId = _unset,
    Object? projectName = _unset,
    DateTime? measurementDate,
    Object? productId = _unset,
    Object? productCode = _unset,
    Object? location = _unset,
    Object? part = _unset,
    Object? material = _unset,
    Object? grooveAngle = _unset,
    Object? rootGap = _unset,
    Object? posture = _unset,
    Object? weldingLengthCm = _unset,
    Object? weather = _unset,
    Object? ambientTempC = _unset,
    Object? humidityPercent = _unset,
  }) {
    return JobSettings(
      projectId: projectId == _unset ? this.projectId : projectId as int?,
      projectName:
          projectName == _unset ? this.projectName : projectName as String?,
      measurementDate: measurementDate ?? this.measurementDate,
      productId: productId == _unset ? this.productId : productId as int?,
      productCode:
          productCode == _unset ? this.productCode : productCode as String?,
      location: location == _unset ? this.location : location as String?,
      part: part == _unset ? this.part : part as String?,
      material: material == _unset ? this.material : material as String?,
      grooveAngle:
          grooveAngle == _unset ? this.grooveAngle : grooveAngle as String?,
      rootGap: rootGap == _unset ? this.rootGap : rootGap as String?,
      posture: posture == _unset ? this.posture : posture as String?,
      weldingLengthCm: weldingLengthCm == _unset
          ? this.weldingLengthCm
          : weldingLengthCm as double?,
      weather: weather == _unset ? this.weather : weather as String?,
      ambientTempC: ambientTempC == _unset
          ? this.ambientTempC
          : ambientTempC as double?,
      humidityPercent: humidityPercent == _unset
          ? this.humidityPercent
          : humidityPercent as double?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'projectName': projectName,
        'measurementDate': measurementDate.toIso8601String(),
        'productId': productId,
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
        projectId: (j['projectId'] as num?)?.toInt(),
        projectName: j['projectName'] as String?,
        measurementDate: j['measurementDate'] != null
            ? DateTime.parse(j['measurementDate'] as String)
            : null,
        productId: (j['productId'] as num?)?.toInt(),
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
