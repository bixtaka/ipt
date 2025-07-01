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
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // 親でスクロールする場合
      itemCount: controllers.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          // ヘッダー
          return Container(
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
          );
        }
        final row = index - 1;
        return Row(
          children: List.generate(
            columnTitles.length,
            (col) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: TextField(
                  controller: controllers[row][col],
                  textAlign: TextAlign.center,
                  keyboardType: col == (columnTitles.length - 1) // 備考列だけ通常
                      ? TextInputType.text
                      : TextInputType.number,
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
    );
  }
}
