import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../models/job_settings.dart';
import '../models/pass_record.dart';

class StackDiagramRenderData {
  final double thicknessMm;
  final double grooveAngleDeg;
  final double rootGapMm;
  final List<double> rowHeights;
  final List<int> splitCounts;
  final List<int> passNumbers;
  final String? posture;

  const StackDiagramRenderData({
    required this.thicknessMm,
    required this.grooveAngleDeg,
    required this.rootGapMm,
    required this.rowHeights,
    required this.splitCounts,
    required this.passNumbers,
    required this.posture,
  });
}

StackDiagramRenderData buildStackDiagramRenderData(
  JobSettings settings,
  List<PassRecord> passes,
) {
  final thicknessMm = _parseThickness(settings.location);
  final grooveAngleDeg = _parseAngleDeg(settings.grooveAngle);
  final rootGapMm = _parseMm(settings.rootGap, 2);

  final splitCounts = <int>[];
  final passNumbers = <int>[];
  int iPass = 0;
  while (iPass < passes.length) {
    final cnt = math.min(_parseLayerCount(passes[iPass].passLayer), passes.length - iPass);
    splitCounts.add(cnt);
    for (int k = 0; k < cnt; k++) {
      passNumbers.add(passes[iPass + k].index);
    }
    iPass += cnt;
  }

  final rowCount = splitCounts.isEmpty ? 1 : splitCounts.length;
  final rowHeights = List<double>.generate(
    rowCount,
    (k) => thicknessMm / (rowCount + 1) * (1 + k * 0.05),
  );

  return StackDiagramRenderData(
    thicknessMm: thicknessMm,
    grooveAngleDeg: grooveAngleDeg,
    rootGapMm: rootGapMm,
    rowHeights: rowHeights,
    splitCounts: splitCounts,
    passNumbers: passNumbers,
    posture: settings.posture,
  );
}

Future<Uint8List> renderStackDiagramPng(
  StackDiagramRenderData data, {
  double width = 600,
  double height = 400,
  double pixelRatio = 3.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = StackDiagramPainter(renderData: data);
  final paintSize = Size(width, height);
  painter.paint(canvas, paintSize);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (width * pixelRatio).round(),
    (height * pixelRatio).round(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to encode stack diagram image');
  }
  return byteData.buffer.asUint8List();
}

class StackDiagramPainter extends CustomPainter {
  final StackDiagramRenderData renderData;

  const StackDiagramPainter({required this.renderData});

  double get thicknessMm => renderData.thicknessMm;
  double get grooveAngleDeg => renderData.grooveAngleDeg;
  double get rootGapMm => renderData.rootGapMm;
  List<double> get rowHeights => renderData.rowHeights;
  List<int> get splitCounts => renderData.splitCounts;
  List<int> get passNumbers => renderData.passNumbers;
  String? get posture => renderData.posture;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 2.0;

    final paintFillTransparent = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    const margin = 24.0;
    final usableW = size.width - margin * 2;
    final usableH = size.height - margin * 2;

    final theta = grooveAngleDeg * math.pi / 180.0;
    final bevelOffsetXmm = thicknessMm * math.tan(theta);
    final topGapMm = rootGapMm + bevelOffsetXmm;

    final leftBottom = const Offset(0, 0);
    final leftTop = Offset(0, thicknessMm);
    final rightBottom = Offset(rootGapMm, 0);
    final rightTop = Offset(topGapMm, thicknessMm);

    final widthMm = topGapMm;
    final heightMm = thicknessMm + 8.0;

    final isHorizontal = (posture != null) && posture!.contains('横');

    final contentWmm = isHorizontal ? heightMm : widthMm;
    final contentHmm = isHorizontal ? widthMm : heightMm;

    final pxPerMmH = contentWmm == 0 ? 0.0 : (usableW / contentWmm);
    final pxPerMmV = contentHmm == 0 ? 0.0 : (usableH / contentHmm);
    final pxPerMm = math.max(0.0, math.min(pxPerMmH, pxPerMmV));
    final contentWpx = contentWmm * pxPerMm;
    final contentHpx = contentHmm * pxPerMm;
    final padX = (usableW - contentWpx) / 2;
    final padY = (usableH - contentHpx) / 2;
    final origin = Offset(margin + padX, size.height - margin - padY);

    Path toCanvasPath(Path pMm) {
      final m = vm.Matrix4.identity()
        ..translate(origin.dx, origin.dy)
        ..scale(pxPerMm, -pxPerMm);

      if (isHorizontal) {
        final orient = vm.Matrix4.identity()
          ..translate(0.0, widthMm)
          ..rotateZ(-math.pi / 2)
          ..translate(widthMm, 0.0)
          ..scale(-1.0, 1.0);
        m.multiply(orient);
      }
      return pMm.transform(m.storage);
    }

    Offset toCanvasPoint(Offset pMm) {
      if (!isHorizontal) {
        return Offset(origin.dx + pMm.dx * pxPerMm, origin.dy - pMm.dy * pxPerMm);
      }
      final xPrime = pMm.dy;
      final yPrime = pMm.dx;
      return Offset(origin.dx + xPrime * pxPerMm, origin.dy - yPrime * pxPerMm);
    }

    final base = Path()
      ..moveTo(leftBottom.dx, leftBottom.dy)
      ..lineTo(leftTop.dx, leftTop.dy);
    canvas.drawPath(toCanvasPath(base), paintLine);

    final bevel = Path()
      ..moveTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..moveTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy);
    canvas.drawPath(toCanvasPath(bevel), paintLine);

    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    double accH = 0.0;
    int labelIndex = 0;
    for (int i = 0; i < rowHeights.length; i++) {
      final hRow = rowHeights[i];
      final y0 = accH;
      final y1 = (accH + hRow).clamp(0.0, thicknessMm);
      accH = y1;

      final parts = (i < splitCounts.length && splitCounts[i] > 0) ? splitCounts[i] : 1;
      final xFullBottom = rootGapMm + y0 * math.tan(theta);
      final xFullTop = rootGapMm + y1 * math.tan(theta);

      for (int k = 0; k < parts; k++) {
        final a0 = k / parts;
        final a1 = (k + 1) / parts;
        final xLBot = a0 * xFullBottom;
        final xRBot = a1 * xFullBottom;
        final xLTop = a0 * xFullTop;
        final xRTop = a1 * xFullTop;

        final ctrl = Offset(xLTop + (xRTop - xLTop) * 0.6, y1 + hRow * 0.35);

        final fill = Path()
          ..moveTo(xLBot, y0)
          ..lineTo(xLTop, y1)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, xRTop, y1)
          ..lineTo(xRBot, y0)
          ..close();
        canvas.drawPath(toCanvasPath(fill), paintFillTransparent);

        final epsMm = 0.75 / (pxPerMm <= 0 ? 1.0 : pxPerMm);
        final y0Adj = (y0 + epsMm).clamp(0.0, thicknessMm);
        final stroke = Path()
          ..moveTo(xLBot, y0Adj)
          ..lineTo(xLTop, y1)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, xRTop, y1)
          ..lineTo(xRBot, y0Adj);
        canvas.drawPath(toCanvasPath(stroke), paintLine);

        final widthPx = (xRTop - xLTop) * pxPerMm;
        final heightPx = (y1 - y0) * pxPerMm;
        final fontPx = math.max(12.0, math.min(28.0, 0.5 * math.min(widthPx, heightPx)));
        final label = (labelIndex < passNumbers.length) ? '${passNumbers[labelIndex]}' : '${labelIndex + 1}';
        tp.text = TextSpan(
          text: label,
          style: TextStyle(fontSize: fontPx, color: Colors.black, fontWeight: FontWeight.w600),
        );
        tp.layout();
        final centerMm = Offset(xLTop + (xRTop - xLTop) * 0.5, (y0 + y1) * 0.5);
        final centerPx = toCanvasPoint(centerMm);
        tp.paint(canvas, centerPx - Offset(tp.width / 2, tp.height / 2));
        labelIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant StackDiagramPainter old) {
    if (thicknessMm != old.thicknessMm || grooveAngleDeg != old.grooveAngleDeg || rootGapMm != old.rootGapMm) {
      return true;
    }
    if (rowHeights.length != old.rowHeights.length) return true;
    for (int i = 0; i < rowHeights.length; i++) {
      if ((rowHeights[i] - old.rowHeights[i]).abs() > 1e-6) return true;
    }
    if (splitCounts.length != old.splitCounts.length) return true;
    for (int i = 0; i < splitCounts.length; i++) {
      if (splitCounts[i] != old.splitCounts[i]) return true;
    }
    if (passNumbers.length != old.passNumbers.length) return true;
    for (int i = 0; i < passNumbers.length; i++) {
      if (passNumbers[i] != old.passNumbers[i]) return true;
    }
    if (posture != old.posture) return true;
    return false;
  }
}

double _parseThickness(String? text) {
  if (text == null) return 25.0;
  final value = double.tryParse(text.trim());
  return value ?? 25.0;
}

double _parseAngleDeg(String? v) {
  if (v == null) return 35;
  final m = RegExp(r'[0-9.]+').firstMatch(v)?.group(0);
  return m == null ? 35 : (double.tryParse(m) ?? 35);
}

double _parseMm(String? v, double def) {
  if (v == null) return def;
  final m = RegExp(r'[0-9.]+').firstMatch(v)?.group(0);
  return m == null ? def : (double.tryParse(m) ?? def);
}

int _parseLayerCount(String? text) {
  if (text == null) return 1;
  final sb = StringBuffer();
  for (final r in text.runes) {
    if (r >= 0x30 && r <= 0x39) sb.writeCharCode(r);
    if (r >= 0xFF10 && r <= 0xFF19) sb.writeCharCode(r - 0xFF10 + 0x30);
  }
  final m = RegExp(r'[0-9]+').firstMatch(sb.toString());
  final n = m == null ? null : int.tryParse(m.group(0)!);
  return (n == null || n < 1) ? 1 : n.clamp(1, 3);
}
