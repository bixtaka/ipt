import 'package:flutter/material.dart';

class DateField extends StatelessWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;
  final String label;
  final bool showLabel;
  const DateField({super.key, required this.value, required this.onChanged, required this.label, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(labelText: showLabel ? label : null, suffixIcon: const Icon(Icons.date_range)),
      controller: TextEditingController(text: value == null ? '' : _fmt(value!)),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  static String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
