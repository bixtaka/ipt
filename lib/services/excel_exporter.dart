import 'dart:html' as html;
import 'package:excel/excel.dart';

Future<void> exportExcelWebWithInfo(
  List<List<String>> infoData,
  List<List<String>> measurementData,
) async {
  final excel = Excel.createExcel();

  // 情報入力シート
  final infoSheet = excel['情報入力'];
  for (int row = 0; row < infoData.length; row++) {
    for (int col = 0; col < infoData[row].length; col++) {
      infoSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(infoData[row][col]);
    }
  }

  // 測定データシート
  final measurementSheet = excel['測定値入力'];
  for (int row = 0; row < measurementData.length; row++) {
    for (int col = 0; col < measurementData[row].length; col++) {
      measurementSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(measurementData[row][col]);
    }
  }

  // ファイル生成・ダウンロード
  final fileBytes = excel.encode();
  if (fileBytes == null) {
    throw Exception('Excelのエンコードに失敗しました。');
  }
  final blob = html.Blob(
    [fileBytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', 'measurement_data_with_info.xlsx')
    ..click();
  html.Url.revokeObjectUrl(url);
}
