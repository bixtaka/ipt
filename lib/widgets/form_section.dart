import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  const FormSection({super.key, required this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) Icon(icon, size: 18, color: Colors.grey[700]),
            if (icon != null) const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const Divider(),
          child,
        ],
      ),
    );
  }
}

