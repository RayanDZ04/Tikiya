import 'package:flutter/material.dart';

class FilterChipPlaceholder extends StatelessWidget {
  final String label;
  const FilterChipPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: false,
      onSelected: (_) {},
      label: Text(label),
    );
  }
}

class LabeledInput extends StatelessWidget {
  final String label;
  final String hint;
  const LabeledInput({super.key, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
