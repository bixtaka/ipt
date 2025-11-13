// lib/ui/pages/stack_diagram_page.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/image_saver.dart';

class StackDiagramPage extends StatelessWidget {
  const StackDiagramPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.settings;
    final boundaryKey = GlobalKey();

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

    final thicknessMm =
        s.location != null && double.tryParse(s.location!) != null
            ? double.parse(s.location!)
            : 25.0;
    final grooveAngleDeg = _parseAngleDeg(s.grooveAngle);
    final rootGapMm = _parseMm(s.rootGap, 2);

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

    // パスを順に消費して層を構成
    final passes = app.passes;
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

    final rowCount = splitCounts.length;
    final rowHeights = List<double>.generate(
      rowCount,
      (k) => thicknessMm / (rowCount + 1) * (1 + k * 0.05),
    );

    Future<void> _exportPng() async {
      try {
        final ro = boundaryKey.currentContext?.findRenderObject();
        if (ro is! RenderRepaintBoundary) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('エクスポート対象が見つかりません')),
          );
          return;
        }
        final ui.Image image = await ro.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PNG生成に失敗しました')),
          );
          return;
        }
        final bytes = byteData.buffer.asUint8List();
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            contentPadding: const EdgeInsets.all(8),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: InteractiveViewer(child: Image.memory(bytes)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('閉じる'),
              ),
              TextButton(
                onPressed: () async {
                  final filename = 'stack_diagram_${DateTime.now().millisecondsSinceEpoch}.png';
                  await savePng(bytes, filename, mimeType: 'image/png');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存しました: $filename')),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポート失敗: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Stack Diagram'),
        actions: [
          IconButton(
            tooltip: 'PNG出力 (背景透過)',
            icon: const Icon(Icons.download),
            onPressed: _exportPng,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: Colors.transparent,
              child: CustomPaint(
                size: size,
                painter: _SingleBevelPainter(
                  thicknessMm: thicknessMm,
                  grooveAngleDeg: grooveAngleDeg,
                  rootGapMm: rootGapMm,
                  rowHeights: rowHeights,
                  splitCounts: splitCounts,
                  passNumbers: passNumbers,
                  posture: s.posture,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SingleBevelPainter extends CustomPainter {
  final double thicknessMm;
  final double grooveAngleDeg;
  final double rootGapMm;
  final List<double> rowHeights;
  final List<int> splitCounts;
  final List<int> passNumbers;
  final String? posture;

  _SingleBevelPainter({
    required this.thicknessMm,
    required this.grooveAngleDeg,
    required this.rootGapMm,
    required this.rowHeights,
    required this.splitCounts,
    required this.passNumbers,
    required this.posture,
  });

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

    // スケールと原点
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

    final widthMm = topGapMm; // base content width (mm)
    final heightMm = thicknessMm + 8.0; // base content height (mm)

    // Determine posture (下向 = default, 横向 = mirror + rotate right 90°)
    final isHorizontal = (posture != null) && posture!.contains('横');

    // After rotation, content dims swap
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
      final m = Matrix4.identity()
        ..translate(origin.dx, origin.dy)
        ..scale(pxPerMm, -pxPerMm);

      if (isHorizontal) {
        // Mirror horizontally, then rotate 90° CW, then translate to keep y ≥ 0
        // Composition (right-multiplied, mm-space): T(0, widthMm) · R(-90°) · T(widthMm, 0) · S(-1, 1)
        final orient = Matrix4.identity()
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
      // After orientation above, effective mapping is x' = y, y' = x
      final xPrime = pMm.dy;
      final yPrime = pMm.dx;
      return Offset(origin.dx + xPrime * pxPerMm, origin.dy - yPrime * pxPerMm);
    }

    // 外形線
    final base = Path()
      ..moveTo(leftBottom.dx, leftBottom.dy)
      ..lineTo(leftTop.dx, leftTop.dy);
    canvas.drawPath(toCanvasPath(base), paintLine);

    final bevel = Path()
      ..moveTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..moveTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy); // 下側水平を左端まで
    canvas.drawPath(toCanvasPath(bevel), paintLine);

    // 層（上下アーチ、下辺はストローク省略）
    final layerHeights = rowHeights;
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    double accH = 0.0;
    int labelIndex = 0;
    for (int i = 0; i < layerHeights.length; i++) {
      final hRow = layerHeights[i];
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

        // ラベル
        final widthPx = (xRTop - xLTop) * pxPerMm;
        final heightPx = (y1 - y0) * pxPerMm;
        final fontPx = math.max(12.0, math.min(28.0, 0.5 * math.min(widthPx, heightPx)));
        final label = (labelIndex < passNumbers.length) ? '${passNumbers[labelIndex]}' : '${labelIndex + 1}';
        tp.text = TextSpan(text: label, style: TextStyle(fontSize: fontPx, color: Colors.black, fontWeight: FontWeight.w600));
        tp.layout();
        final centerMm = Offset(xLTop + (xRTop - xLTop) * 0.5, (y0 + y1) * 0.5);
        final centerPx = toCanvasPoint(centerMm);
        tp.paint(canvas, centerPx - Offset(tp.width / 2, tp.height / 2));
        labelIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SingleBevelPainter old) {
    if (thicknessMm != old.thicknessMm || grooveAngleDeg != old.grooveAngleDeg || rootGapMm != old.rootGapMm) return true;
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
