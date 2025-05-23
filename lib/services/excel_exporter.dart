import 'dart:html' as html;
import 'package:excel/excel.dart';

Future<void> exportExcelWebWithInfo(
  List<List<String>> infoData, // 情報入力タブ用データ（2次元リスト）
  List<List<String>> measurementData, // 測定データタブ用データ
) async {
  final Excel excel = Excel.createExcel();

  // 1つ目のシートは「情報入力」
  final Sheet infoSheet = excel['情報入力'];
  for (int row = 0; row < infoData.length; row++) {
    for (int col = 0; col < infoData[row].length; col++) {
      infoSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = infoData[row][col];
    }
  }

  // 2つ目のシートは「測定データ」（Sheet1はデフォルトでできているのでそれを使う）
  final Sheet measurementSheet = excel['Sheet1'];
  for (int row = 0; row < measurementData.length; row++) {
    for (int col = 0; col < measurementData[row].length; col++) {
      measurementSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = measurementData[row][col];
    }
  }

  // ファイル生成とダウンロード処理は同じ
  final fileBytes = excel.encode();
  if (fileBytes == null) {
    throw Exception('Excelのエンコードに失敗しました。');
  }

  final blob = html.Blob([fileBytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'measurement_data_with_info.xlsx')
    ..click();
  html.Url.revokeObjectUrl(url);
}
