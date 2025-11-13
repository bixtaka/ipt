// lib/widgets/measurement_table.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeasurementTable extends StatelessWidget {
  final List<List<TextEditingController>> controllers;
  final List<String> columnTitles;
  final int? selectedRow;
  final int? selectedColumn;
  final Map<String, String> validationErrors;
  final void Function(int row, int col)? onCellTap;
  final void Function(int row, int col, String value)? onCellChanged;

  const MeasurementTable({
    Key? key,
    required this.controllers,
    required this.columnTitles,
    this.selectedRow,
    this.selectedColumn,
    this.validationErrors = const {},
    this.onCellTap,
    this.onCellChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final int colCount = columnTitles.length;

      // 列幅の目安（必要に応じて調整してください）
      final List<double> colWidths = List.generate(colCount, (i) {
        if (i == 0) return 56.0; // パス数など狭い列
        if (i == 1 || i == 2) return 160.0; // パス間温度開始/終了（更に広め）
        if (i == 3) return 140.0; // 入熱（広め）
        if (i == 4 || i == 5) return 160.0; // 電流/電圧（更に広め）
        if (i == 6) return 130.0; // 速度
        if (i == colCount - 1) return 280.0; // 備考は大きく
        return 150.0; // その他
      });

      final double totalWidth = colWidths.fold(0.0, (prev, w) => prev + w);

      // スクロールコントローラはローカルで作成（Stateless の場合 build ごとに再作成されますが問題ありません）
      final hController = ScrollController();
      final vController = ScrollController();

      return Scrollbar(
        controller: hController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: hController,
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: math.max(constraints.maxWidth, totalWidth)),
            child: SizedBox(
              width: math.max(constraints.maxWidth, totalWidth),
              // 親から高さの制約が来ない場合に備えてフォールバックを用意
              height: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 400.0,
              child: Column(
                children: [
                  // ヘッダー行
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: List.generate(colCount, (col) {
                        return SizedBox(
                          width: colWidths[col],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              columnTitles[col],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // データ行（縦スクロール）
                  Expanded(
                    child: Scrollbar(
                      controller: vController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: vController,
                        itemCount: controllers.length,
                        itemBuilder: (context, row) {
                          final rowControllers = controllers[row];
                          return InkWell(
                            onTap: () => onCellTap?.call(row, -1),
                            child: Row(
                              children: List.generate(colCount, (col) {
                                final isSelected =
                                    selectedRow == row && selectedColumn == col;
                                final ctrl = rowControllers[col];
                                final errorKey = 'r${row}_c$col';
                                final hasError =
                                    validationErrors.containsKey(errorKey);
                                return SizedBox(
                                  width: colWidths[col],
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: TextField(
                                      controller: ctrl,
                                      maxLines: 1,
                                      keyboardType: (col == 1 ||
                                              col == 2 ||
                                              col == 3 ||
                                              col == 4 ||
                                              col == 5 ||
                                              col == 6)
                                          ? const TextInputType
                                              .numberWithOptions(decimal: true)
                                          : TextInputType.text,
                                      textAlign: (col == 1 ||
                                              col == 2 ||
                                              col == 3 ||
                                              col == 4 ||
                                              col == 5 ||
                                              col == 6)
                                          ? TextAlign.right
                                          : TextAlign.start,
                                      style: TextStyle(
                                        fontSize: (col == 1 ||
                                                col == 2 ||
                                                col == 3 ||
                                                col == 4 ||
                                                col == 5 ||
                                                col == 6)
                                            ? 13
                                            : 14,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: hasError
                                                  ? Colors.red
                                                  : Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        filled: false,
                                        fillColor: isSelected
                                            ? Colors.blue.shade50
                                            : null,
                                        errorText: hasError
                                            ? validationErrors[errorKey]
                                            : null,
                                      ),
                                      onTap: () => onCellTap?.call(row, col),
                                      onChanged: (v) =>
                                          onCellChanged?.call(row, col, v),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
