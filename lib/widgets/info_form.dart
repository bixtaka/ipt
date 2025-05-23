import 'package:flutter/material.dart';

class InfoForm extends StatelessWidget {
  final List<String> infoLabels;
  final List<TextEditingController> controllers;
  final void Function(int index) onChanged;

  const InfoForm({
    super.key,
    required this.infoLabels,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: List.generate(infoLabels.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  infoLabels[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controllers[index],
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (value) {
                    onChanged(index);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
