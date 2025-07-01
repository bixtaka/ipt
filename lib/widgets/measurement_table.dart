// lib/widgets/measurement_table.dart
import 'package:flutter/material.dart';

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
    return Column(
      children: [
        // ヘッダー
        Container(
          color: Colors.grey[200],
          child: Row(
            children: List.generate(
              columnTitles.length,
              (col) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    columnTitles[col],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // データ行（高さを固定 → 可変に変更）
        Expanded(
          child: ListView.builder(
            itemCount: controllers.length,
            itemBuilder: (context, row) {
              return Row(
                children: List.generate(
                  columnTitles.length,
                  (col) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      child: TextField(
                        controller: controllers[row][col],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          border: InputBorder.none,
                        ),
                        onTap: () => onCellTap(row, col),
                        onChanged: (value) => onCellChanged(row, col, value),
                        style: TextStyle(
                          backgroundColor:
                              (selectedRow == row && selectedColumn == col)
                                  ? Colors.blue.withOpacity(0.1)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
