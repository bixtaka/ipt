Future<void> exportExcelWithInfo(
  List<List<String>> infoData,
  List<List<String>> measurementData,
) async {
  throw UnimplementedError(
      'excel exporter is not implemented for this platform');
}

Future<void> exportExcelFromTemplate({
  required String assetPath,
  required String sheetName,
  required Map<String, String> valuesByA1,
  String? filename,
}) async {
  throw UnimplementedError(
      'template-based excel exporter is not implemented for this platform');
}
