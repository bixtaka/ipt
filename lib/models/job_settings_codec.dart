import 'job_settings.dart';

Map<String, dynamic> encodeJobSettings(JobSettings s) => {
      'projectName': s.projectName,
      'measurementDate': s.measurementDate.toIso8601String(),
      'productCode': s.productCode,
      'location': s.location,
      'part': s.part,
      'material': s.material,
      'grooveAngle': s.grooveAngle,
      'rootGap': s.rootGap,
      'posture': s.posture,
      'weldingLengthCm': s.weldingLengthCm,
      'weather': s.weather,
      'ambientTempC': s.ambientTempC,
      'humidityPercent': s.humidityPercent,
    };

JobSettings decodeJobSettings(Map<String, dynamic> j) => JobSettings(
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

