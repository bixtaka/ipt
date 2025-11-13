import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';

Future<void> exportExcelWithInfo(
  List<List<String>> infoData,
  List<List<String>> measurementData,
) async {
  final excel = Excel.createExcel();

  final infoSheet = excel['情報入力'];
  for (int row = 0; row < infoData.length; row++) {
    for (int col = 0; col < infoData[row].length; col++) {
      infoSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(infoData[row][col]);
    }
  }

  final measurementSheet = excel['測定値入力'];
  for (int row = 0; row < measurementData.length; row++) {
    for (int col = 0; col < measurementData[row].length; col++) {
      measurementSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(measurementData[row][col]);
    }
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Excelのエンコードに失敗しました。');
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/measurement_data_with_info.xlsx');
  await file.writeAsBytes(bytes, flush: true);

  // 端末の共有シートで保存/共有
  await Share.shareXFiles([XFile(file.path)], text: '測定データ');
}

Future<void> exportExcelFromTemplate({
  required String assetPath,
  required String sheetName,
  required Map<String, String> valuesByA1,
  String? filename,
}) async {
  final data = await rootBundle.load(assetPath);
  final sanitized = _sanitizeExcelTemplateBytes(data.buffer.asUint8List());
  final excel = Excel.decodeBytes(sanitized);

  final sheet = excel[sheetName];
  valuesByA1.forEach((a1, value) {
    sheet.cell(CellIndex.indexByString(a1)).value = TextCellValue(value);
  });

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Excelのエンコードに失敗しました');
  }

  final dir = await getApplicationDocumentsDirectory();
  final outName = filename ?? 'template_output.xlsx';
  final file = File('${dir.path}/$outName');
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles([XFile(file.path)], text: 'テンプレート出力');
}

Uint8List _sanitizeExcelTemplateBytes(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final stylesFile = archive.files.firstWhere(
      (f) => f.name == 'xl/styles.xml',
      orElse: () => ArchiveFile('none', 0, Uint8List(0)),
    );
    if (stylesFile.name != 'xl/styles.xml') return bytes;
    final content = String.fromCharCodes(stylesFile.content as List<int>);
    final replaced = _fixStylesXml(content);
    final updated = Archive()
      ..files.addAll(archive.files.map((f) {
        if (f.name == 'xl/styles.xml') {
          return ArchiveFile(f.name, replaced.length, Uint8List.fromList(replaced.codeUnits))
            ..mode = f.mode
            ..isFile = true
            ..lastModTime = f.lastModTime;
        }
        return f;
      }));
    final out = ZipEncoder().encode(updated);
    return Uint8List.fromList(out!);
  } catch (_) {
    return bytes;
  }
}

String _fixStylesXml(String xml) {
  var out = xml;
  // 1) Replace any xf/dxf references to numFmtId=31 with 14 (safe built-in)
  final re = RegExp(r'numFmtId\s*=\s*"?31"?');
  if (re.hasMatch(out)) {
    out = out.replaceAll(re, 'numFmtId="14"');
  }
  // 2) Ensure a numFmt for 31 exists (in case some references remain)
  if (out.contains('numFmtId="31"')) {
    if (out.contains('<numFmts')) {
      final countRe = RegExp(r'<numFmts[^>]*count="(\d+)"[^>]*>');
      final m = countRe.firstMatch(out);
      if (m != null) {
        final count = int.tryParse(m.group(1)!) ?? 0;
        if (!out.contains('numFmt numFmtId="31"')) {
          out = out.replaceFirst(
            '</numFmts>',
            '<numFmt numFmtId="31" formatCode="yyyy-mm-dd"/></numFmts>',
          );
          out = out.replaceFirst(m.group(0)!, m.group(0)!.replaceFirst(m.group(1)!, '${count + 1}'));
        }
      }
    } else {
      // Insert a new numFmts block after <styleSheet ...>
      final styleStart = out.indexOf('>');
      if (styleStart != -1) {
        final insert = '<numFmts count="1"><numFmt numFmtId="31" formatCode="yyyy-mm-dd"/></numFmts>';
        out = out.substring(0, styleStart + 1) + insert + out.substring(styleStart + 1);
      }
    }
  }
  return out;
}
