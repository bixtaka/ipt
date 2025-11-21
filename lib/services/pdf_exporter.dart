import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job_settings.dart';
import '../models/pass_record.dart';
import '../utils/stack_diagram_renderer.dart';

Future<void> exportPdfReport({
  required JobSettings settings,
  required List<PassRecord> passes,
  required List<List<String>> measurementData,
}) async {
  final bytes = await _buildPdfBytes(
    settings: settings,
    passes: passes,
    measurementData: measurementData,
  );
  await Printing.sharePdf(bytes: bytes, filename: 'ipt_report.pdf');
}

Future<String> exportPdfReportToFile({
  required JobSettings settings,
  required List<PassRecord> passes,
  required List<List<String>> measurementData,
  String? filePath,
}) async {
  final bytes = await _buildPdfBytes(
    settings: settings,
    passes: passes,
    measurementData: measurementData,
  );

  final String destPath;
  if (filePath != null && filePath.isNotEmpty) {
    destPath = filePath;
  } else {
    Directory? base;
    if (!kIsWeb && Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final desktop = Directory(p.join(userProfile, 'Desktop'));
        if (await desktop.exists()) base = desktop;
      }
      base ??= Directory(r'C:\Users\USER1\Desktop');
    }
    if (base == null && Platform.isAndroid) {
      final downloads = Directory('/sdcard/Download');
      if (await downloads.exists()) base = downloads;
    }
    base ??= await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    destPath = p.join(base!.path, 'ipt_report.pdf');
  }

  final file = File(destPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return destPath;
}

Future<Uint8List> _buildPdfBytes({
  required JobSettings settings,
  required List<PassRecord> passes,
  required List<List<String>> measurementData,
}) async {
  final fonts = await _loadFonts();
  final baseStyle = pw.TextStyle(font: fonts.base, fontSize: 10);
  final smallStyle = baseStyle.copyWith(fontSize: 9);
  final boldStyle = pw.TextStyle(font: fonts.bold, fontSize: 10);
  final titleStyle = pw.TextStyle(font: fonts.bold, fontSize: 14);
  final pageFormat = PdfPageFormat.a4.applyMargin(
    left: 20 * PdfPageFormat.mm,
    right: 15 * PdfPageFormat.mm,
    top: 15 * PdfPageFormat.mm,
    bottom: 15 * PdfPageFormat.mm,
  );

  final renderData = buildStackDiagramRenderData(settings, passes);
  Uint8List? diagramBytes;
  try {
    diagramBytes = await renderStackDiagramPng(
      renderData,
      width: 420,
      height: 260,
      pixelRatio: 2.5,
    );
  } catch (_) {
    diagramBytes = null;
  }

  final headerRow = measurementData.isNotEmpty
      ? measurementData.first
      : _defaultMeasurementHeader;
  final dataRows = measurementData.length > 1
      ? measurementData.sublist(1)
      : <List<String>>[];

  const firstPageRows = 40;
  final firstChunk = dataRows.take(firstPageRows).toList();
  final remaining = dataRows.skip(firstPageRows).toList();

  final pdf = pw.Document();
  final remainingChunks = <List<List<String>>>[];
  if (remaining.isNotEmpty) {
    const laterRows = 45;
    int index = 0;
    while (index < remaining.length) {
      remainingChunks.add(remaining.skip(index).take(laterRows).toList());
      index += laterRows;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(pageFormat: pageFormat),
      footer: (context) => _pageNumber(context, smallStyle),
      build: (context) {
        final widgets = <pw.Widget>[
          _buildFirstPageContent(
            titleStyle: titleStyle,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            smallStyle: smallStyle,
            settings: settings,
            diagramBytes: diagramBytes,
            headerRow: headerRow,
            firstChunk: firstChunk,
          ),
        ];
        for (final chunk in remainingChunks) {
          widgets.add(pw.NewPage());
          widgets.add(
            _buildMeasurementSection(
              headerRow: headerRow,
              rows: chunk,
              baseStyle: baseStyle,
              boldStyle: boldStyle,
              showHeader: false,
            ),
          );
        }
        return widgets;
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildFirstPageContent({
  required pw.TextStyle titleStyle,
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
  required pw.TextStyle smallStyle,
  required JobSettings settings,
  required Uint8List? diagramBytes,
  required List<String> headerRow,
  required List<List<String>> firstChunk,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        '\u5165\u71b1\u30fb\u30d1\u30b9\u9593\u6e29\u5ea6\u7ba1\u7406\u5831\u544a\u66f8',
        style: titleStyle,
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 8),
      _buildTopRow(
        settings: settings,
        diagramBytes: diagramBytes,
        baseStyle: baseStyle,
        boldStyle: boldStyle,
        smallStyle: smallStyle,
      ),
      pw.SizedBox(height: 12),
      _buildMeasurementSection(
        headerRow: headerRow,
        rows: firstChunk,
        baseStyle: baseStyle,
        boldStyle: boldStyle,
        showHeader: true,
      ),
      pw.SizedBox(height: 12),
      _buildNotesAndSignatures(
        baseStyle: baseStyle,
        boldStyle: boldStyle,
      ),
    ],
  );
}

pw.Widget _buildTopRow({
  required JobSettings settings,
  required Uint8List? diagramBytes,
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
  required pw.TextStyle smallStyle,
}) {
  final tempLine = settings.ambientTempC != null
      ? '\u6c17\u6e29: ${settings.ambientTempC!.toStringAsFixed(1)}\u2103'
      : '\u6c17\u6e29: --\u2103';
  final humidityLine = settings.humidityPercent != null
      ? '\u6e7f\u5ea6: ${settings.humidityPercent!.toStringAsFixed(0)}%'
      : '\u6e7f\u5ea6: --%';
  final weather = '$tempLine  $humidityLine';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Align(
        alignment: pw.Alignment.topRight,
        child: pw.Text(weather, style: baseStyle),
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: _buildInfoBlock(
              settings: settings,
              baseStyle: baseStyle,
              boldStyle: boldStyle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 4,
            child: _buildStackDiagramBlock(
              diagramBytes: diagramBytes,
              baseStyle: baseStyle,
              boldStyle: boldStyle,
              smallStyle: smallStyle,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildStackDiagramBlock({
  required Uint8List? diagramBytes,
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
  required pw.TextStyle smallStyle,
}) {
  const inside = PdfColors.grey500;
  return pw.Container(
    height: 200,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey700, width: 0.4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          height: 20,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: inside, width: 0.3),
            color: PdfColors.grey200,
          ),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text('\u7a4d\u5c64\u56f3', style: boldStyle),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: diagramBytes == null
                ? pw.Center(
                    child: pw.Text(
                      '\u7a4d\u5c64\u56f3\u3092\u751f\u6210\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f',
                      style: smallStyle,
                      textAlign: pw.TextAlign.center,
                    ),
                  )
                : pw.Image(
                    pw.MemoryImage(diagramBytes),
                    fit: pw.BoxFit.contain,
                    alignment: pw.Alignment.center,
                  ),
          ),
        ),
        pw.Container(
          height: 20,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: inside, width: 0.3),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 60,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(
                    right: pw.BorderSide(color: inside, width: 0.3),
                  ),
                ),
                child: pw.Text('\u7a4d\u5c64\u6570', style: boldStyle),
              ),
              pw.Expanded(
                child: pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  child: pw.Text('', style: baseStyle),
                ),
              ),
              pw.Container(
                width: 70,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(
                    left: pw.BorderSide(color: inside, width: 0.3),
                    right: pw.BorderSide(color: inside, width: 0.3),
                  ),
                ),
                child:
                    pw.Text('\u6a19\u6e96\u7a4d\u5c64\u6570', style: boldStyle),
              ),
              pw.Expanded(
                child: pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  child: pw.Text('', style: baseStyle),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildInfoBlock({
  required JobSettings settings,
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
}) {
  const borderColor = PdfColors.grey700;
  const insideBorder = PdfColors.grey500;
  const rowHeight = 20.0;

  pw.Widget labelCell(String text) => pw.Container(
        height: rowHeight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: insideBorder, width: 0.3),
          color: PdfColors.grey200,
        ),
        child: pw.Text(text, style: boldStyle),
      );

  pw.Widget valueCell(String text) => pw.Container(
        height: rowHeight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        alignment: pw.Alignment.centerLeft,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: insideBorder, width: 0.3),
        ),
        child: pw.Text(text, style: baseStyle),
      );

  final twoColumnRows = <List<String>>[
    ['\u6e2c\u5b9a\u65e5', _fmtDateJa(settings.measurementDate)],
    ['\u5de5\u4e8b\u540d', settings.projectName ?? ''],
    ['\u88fd\u54c1\u7b26\u53f7', settings.productCode ?? ''],
    ['\u4f4d\u7f6e', settings.location ?? ''],
    ['\u90e8\u6750', settings.part ?? ''],
    ['\u6750\u8cea', settings.material ?? ''],
  ];

  final twoColumnTable = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(1),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
    children: twoColumnRows
        .map(
          (row) => pw.TableRow(
            children: [
              labelCell(row[0]),
              valueCell(row[1]),
            ],
          ),
        )
        .toList(),
  );

  final fourColumnRows = <List<String>>[
    [
      '\u958b\u5148\u89d2\u5ea6',
      settings.grooveAngle ?? '',
      '\u30eb\u30fc\u30c8\u9593\u9694',
      settings.rootGap ?? ''
    ],
    [
      '\u6eb6\u63a5\u59ff\u52e2',
      settings.posture ?? '',
      '\u6eb6\u63a5\u6280\u80fd\u8005',
      ''
    ],
    [
      '\u6eb6\u63a5\u9577(cm)',
      settings.weldingLengthCm != null ? '${settings.weldingLengthCm}' : '',
      '',
      '',
    ],
  ];

  final fourColumnTable = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(2),
      2: pw.FixedColumnWidth(70),
      3: pw.FlexColumnWidth(2),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
    children: fourColumnRows
        .map(
          (row) => pw.TableRow(
            children: [
              labelCell(row[0]),
              valueCell(row[1]),
              labelCell(row[2]),
              valueCell(row[3]),
            ],
          ),
        )
        .toList(),
  );

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: borderColor, width: 0.4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        twoColumnTable,
        pw.Container(height: 0.4, color: borderColor),
        fourColumnTable,
      ],
    ),
  );
}

pw.Widget _buildMeasurementSection({
  required List<String> headerRow,
  required List<List<String>> rows,
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
  required bool showHeader,
}) {
  if (!showHeader && rows.isEmpty) {
    return pw.SizedBox();
  }

  const headers = <String>[
    '\u30d1\u30b9',
    '\u958b\u59cb\n\u6e29\u5ea6\n(\u2103)',
    '\u7d42\u4e86\n\u6e29\u5ea6\n(\u2103)',
    '\u96fb\u6d41\n(A)',
    '\u96fb\u5727\n(V)',
    '\u5165\u71b1\n(kJ/cm)',
    '\u6eb6\u63a5\n\u6642\u9593\n(\u79d2)',
    '\u505c\u6b62\n\u6642\u9593\n(\u79d2)',
    '\u6eb6\u63a5\u901f\u5ea6\n(cm/min)',
    '\u5099\u8003',
  ];

  const columnsToKeep = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 11];

  List<String> projectRow(List<String> row) {
    return columnsToKeep.map((i) => (i < row.length ? row[i] : '')).toList();
  }

  final tableRows = <pw.TableRow>[];
  if (showHeader) {
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map(
              (h) => _tableCell(
                h,
                boldStyle,
                alignCenter: true,
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                height: 30,
              ),
            )
            .toList(),
      ),
    );
  }

  for (final row in rows) {
    final trimmed = projectRow(row);
    tableRows.add(
      pw.TableRow(
        children: List.generate(headers.length, (index) {
          final value = index < trimmed.length ? trimmed[index] : '';
          final alignCenter = index <= 4;
          return _tableCell(
            value,
            baseStyle,
            alignCenter: alignCenter,
            height: 20,
          );
        }),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.3),
    columnWidths: const {
      0: pw.FixedColumnWidth(28),
      1: pw.FixedColumnWidth(42),
      2: pw.FixedColumnWidth(42),
      3: pw.FixedColumnWidth(38),
      4: pw.FixedColumnWidth(38),
      5: pw.FixedColumnWidth(56),
      6: pw.FixedColumnWidth(52),
      7: pw.FixedColumnWidth(52),
      8: pw.FixedColumnWidth(62),
      9: pw.FlexColumnWidth(1),
    },
    children: tableRows,
  );
}

pw.Widget _tableCell(
  String text,
  pw.TextStyle style, {
  bool alignCenter = false,
  pw.EdgeInsets padding =
      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
  double? height,
}) {
  return pw.Container(
    height: height,
    padding: padding,
    alignment: alignCenter ? pw.Alignment.center : pw.Alignment.centerLeft,
    child: pw.Text(
      text,
      style: style,
      textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
    ),
  );
}

pw.Widget _buildNotesAndSignatures({
  required pw.TextStyle baseStyle,
  required pw.TextStyle boldStyle,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text('\u5099\u8003', style: boldStyle),
      pw.SizedBox(height: 4),
      pw.Container(
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.4),
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          _signatureBox('\u691c\u67fb\u8005', baseStyle, boldStyle),
          pw.SizedBox(width: 12),
          _signatureBox('\u78ba\u8a8d\u8005', baseStyle, boldStyle),
        ],
      ),
    ],
  );
}

pw.Widget _signatureBox(
  String label,
  pw.TextStyle baseStyle,
  pw.TextStyle boldStyle,
) {
  return pw.Expanded(
    child: pw.Container(
      height: 50,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: boldStyle),
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.bottomLeft,
              child: pw.Container(
                height: 0.4,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _pageNumber(pw.Context context, pw.TextStyle style) {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text('${context.pageNumber}/${context.pagesCount}', style: style),
  );
}

class _PdfFonts {
  final pw.Font base;
  final pw.Font bold;

  _PdfFonts({required this.base, required this.bold});
}

Future<_PdfFonts> _loadFonts() async {
  for (final pair in const [
    ('assets/fonts/NotoSansJP-Regular.ttf', 'assets/fonts/NotoSansJP-Bold.ttf'),
    ('assets/fonts/NotoSansJP-Regular.otf', 'assets/fonts/NotoSansJP-Bold.otf'),
  ]) {
    try {
      final regularData = await rootBundle.load(pair.$1);
      final boldData = await rootBundle.load(pair.$2);
      final base = pw.Font.ttf(regularData);
      final bold = pw.Font.ttf(boldData);
      return _PdfFonts(base: base, bold: bold);
    } catch (_) {}
  }

  try {
    final base = await PdfGoogleFonts.notoSansJPRegular();
    final bold = await PdfGoogleFonts.notoSansJPBold();
    return _PdfFonts(base: base, bold: bold);
  } catch (_) {
    return _PdfFonts(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }
}

String _fmtDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _fmtDateJa(DateTime date) {
  return '${date.year}\u5e74${date.month}\u6708${date.day}\u65e5';
}

const List<String> _defaultMeasurementHeader = <String>[
  '\u30d1\u30b9',
  '\u958b\u59cb\u6e29\u5ea6',
  '\u7d42\u4e86\u6e29\u5ea6',
  '\u96fb\u6d41',
  '\u96fb\u5727',
  '\u5165\u71b1(kJ/cm)',
  '\u6eb6\u63a5\u6642\u9593',
  '\u505c\u6b62\u6642\u9593',
  '\u6eb6\u63a5\u901f\u5ea6(cm/min)',
  '\u5099\u8003',
];
