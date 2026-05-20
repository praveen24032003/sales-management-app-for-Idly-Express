import 'package:flutter/material.dart';

/// Custom styled dropdown widget
class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? hint;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
          hint: hint != null ? Text(hint!) : null,
        ),
      ],
    );
  }
}

/// Dropdown specifically for rate selection (Idly only)
class RateDropdown extends StatelessWidget {
  final double value;
  final List<double> options;
  final void Function(double?) onChanged;

  const RateDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate per Unit (₹)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: options.map((rate) {
            return DropdownMenuItem<double>(
              value: rate,
              child: Text('₹${rate.toStringAsFixed(1)}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
