// lib/ui/pages/stack_diagram_page.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../utils/image_saver.dart';
import '../../utils/stack_diagram_renderer.dart';

class StackDiagramPage extends StatelessWidget {
  const StackDiagramPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final boundaryKey = GlobalKey();
    final renderData = buildStackDiagramRenderData(app.settings, app.passes);

    Future<void> _exportPng() async {
      try {
        final ro = boundaryKey.currentContext?.findRenderObject();
        if (ro is! RenderRepaintBoundary) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('エクスポ�Eト対象が見つかりません')),
          );
          return;
        }
        final ui.Image image = await ro.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PNG生�Eに失敗しました')),
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
          SnackBar(content: Text('エクスポ�Eト失敁E $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Stack Diagram'),
        actions: [
          IconButton(
            tooltip: 'PNG出劁E(背景透過)',
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
                painter: StackDiagramPainter(renderData: renderData),
              ),
            ),
          );
        },
      ),
    );
  }
}
