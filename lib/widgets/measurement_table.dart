// lib/widgets/measurement_table.dart
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class MeasurementTable extends StatelessWidget {
  final List<List<TextEditingController>> controllers;
  final List<String> columnTitles;
  final int? selectedRow;
  final int? selectedColumn;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col, String value) onCellChanged;

  const MeasurementTable({
    super.key,
    required this.controllers,
    required this.columnTitles,
    required this.selectedRow,
    required this.selectedColumn,
    required this.onCellTap,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StickyHeader(
        header: Container(
          color: const Color.fromARGB(255, 63, 131, 231), // ネイビー（濃い青）に変更
          child: Row(
            children: List.generate(
              columnTitles.length,
              (col) => Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: col != columnTitles.length - 1
                          ? BorderSide(color: Colors.grey)
                          : BorderSide.none,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      columnTitles[col],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // ヘッダー文字色も白に
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        content: Column(
          children: List.generate(
            controllers.length,
            (row) => Container(
              decoration: BoxDecoration(
                color: selectedRow == row
                    ? const Color.fromARGB(255, 233, 75, 149)
                        .withOpacity(0.18) // 青系でハイライト
                    : null,
                border: const Border(
                  bottom: BorderSide(color: Colors.grey), // 横の罫線（行の下）
                ),
              ),
              child: Row(
                children: List.generate(
                  columnTitles.length,
                  (col) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: col != columnTitles.length - 1
                              ? BorderSide(color: Colors.grey)
                              : BorderSide.none,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: TextField(
                          controller: controllers[row][col],
                          textAlign: TextAlign.center,
                          keyboardType: col == (columnTitles.length - 1)
                              ? TextInputType.text
                              : TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            border: InputBorder.none,
                          ),
                          onTap: () => onCellTap(row, col),
                          onChanged: (value) => onCellChanged(row, col, value),
                          // セル単体の背景色指定は削除
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
