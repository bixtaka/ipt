import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ValueSubmit = void Function(String value);

class EditableValueTile extends StatelessWidget {
  final String label;
  final String? value;
  final String? unit;
  final TextInputType keyboardType;
  final ValueSubmit onSubmitted;
  final String? hintText;
  final int? maxLines;
  final bool dense; // compact layout
  final List<TextInputFormatter>? inputFormatters;

  const EditableValueTile({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
    this.unit,
    this.keyboardType = TextInputType.number,
    this.hintText,
    this.maxLines = 1,
    this.dense = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.isEmpty) ? '-' : value!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openEditor(context),
      child: Container(
        padding: dense ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: dense
                  ? Theme.of(context).textTheme.labelSmall
                  : Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: dense
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null)
                  Text(
                    unit!,
                    style: (dense
                            ? Theme.of(context).textTheme.labelSmall
                            : Theme.of(context).textTheme.labelLarge)
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: dense ? 14 : 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final controller = TextEditingController(text: (value ?? '').trim());
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  hintText: hintText ?? '入力してください',
                  suffixText: unit,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx, controller.text.trim());
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      onSubmitted(result);
    }
  }
}
