import 'package:flutter/material.dart';

class SmallDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool showLabel;
  const SmallDropdown({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: showLabel ? InputDecoration(labelText: label) : const InputDecoration(),
      items: items,
      onChanged: onChanged,
    );
  }
}
