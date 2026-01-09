import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom styled text field with validation
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final int? maxLines;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.hint,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.onChanged,
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
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            prefixText: prefix,
            filled: readOnly,
            fillColor: readOnly 
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
          ),
        ),
      ],
    );
  }
}

/// Numeric text field for quantity and cost inputs
class NumericTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool allowDecimal;
  final String? suffix;
  final void Function(String)? onChanged;

  const NumericTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.allowDecimal = false,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      suffix: suffix,
      onChanged: onChanged,
    );
  }
}

/// Read-only display field for calculated values
class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
