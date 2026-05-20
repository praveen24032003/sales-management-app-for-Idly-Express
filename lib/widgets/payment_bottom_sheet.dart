import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/animated_form_section.dart';

/// Bottom sheet for recording payment after dispatching a supply order.
class PaymentBottomSheet extends StatefulWidget {
  final String shopName;
  final int quantity;
  final double ratePerUnit;
  final DeliverySlot slot;

  const PaymentBottomSheet({
    super.key,
    required this.shopName,
    required this.quantity,
    required this.ratePerUnit,
    required this.slot,
  });

  static Future<DispatchPaymentResult?> show(
    BuildContext context, {
    required String shopName,
    required int quantity,
    required double ratePerUnit,
    required DeliverySlot slot,
  }) {
    return showDispatch(
      context,
      shopName: shopName,
      quantity: quantity,
      ratePerUnit: ratePerUnit,
      slot: slot,
    );
  }

  static Future<DispatchPaymentResult?> showDispatch(
    BuildContext context, {
    required String shopName,
    required int quantity,
    required double ratePerUnit,
    required DeliverySlot slot,
  }) async {
    final result = await _showInternal(
      context,
      shopName: shopName,
      quantity: quantity,
      ratePerUnit: ratePerUnit,
      slot: slot,
    );
    if (result == null) return null;
    return DispatchPaymentResult(result.status, result.paidAmount);
  }

  static Future<_PaymentResult?> _showInternal(
    BuildContext context, {
    required String shopName,
    required int quantity,
    required double ratePerUnit,
    required DeliverySlot slot,
  }) {
    return showModalBottomSheet<_PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(
        shopName: shopName,
        quantity: quantity,
        ratePerUnit: ratePerUnit,
        slot: slot,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentResult {
  final PaymentStatus status;
  final double paidAmount;
  const _PaymentResult(this.status, this.paidAmount);
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  _PaymentMode _mode = _PaymentMode.paid;
  final _partialCtrl = TextEditingController();
  final _focusNode = FocusNode();

  double get _total => widget.quantity * widget.ratePerUnit;

  @override
  void dispose() {
    _partialCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirm() {
    double paid;
    PaymentStatus status;

    switch (_mode) {
      case _PaymentMode.paid:
        paid = _total;
        status = PaymentStatus.paid;
        break;
      case _PaymentMode.pending:
        paid = 0;
        status = PaymentStatus.pending;
        break;
      case _PaymentMode.partial:
        paid = double.tryParse(_partialCtrl.text) ?? 0;
        status = paid >= _total ? PaymentStatus.paid : PaymentStatus.pending;
        break;
    }

    Navigator.of(context).pop(_PaymentResult(status, paid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.bgLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedFormSection(
              index: 0,
              child: Text(
                widget.shopName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedFormSection(
              index: 1,
              child: Text(
                '${widget.slot.displayName} · ${widget.quantity} pcs · $currencySymbol${_total.toStringAsFixed(0)}',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedFormSection(
              index: 2,
              child: Column(
                children: [
                  _modeCard(
                    mode: _PaymentMode.paid,
                    icon: Icons.check_circle_outline,
                    label: 'Fully Paid',
                    subtitle: '$currencySymbol${_total.toStringAsFixed(0)} received',
                    color: AppColors.profitLight,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    mode: _PaymentMode.partial,
                    icon: Icons.edit_outlined,
                    label: 'Partial Payment',
                    subtitle: 'Enter amount received',
                    color: AppColors.accentLight,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    mode: _PaymentMode.pending,
                    icon: Icons.schedule,
                    label: 'Pending',
                    subtitle: 'Will collect later',
                    color: AppColors.lossLight,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),
                ],
              ),
            ),
            if (_mode == _PaymentMode.partial) ...[
              const SizedBox(height: 16),
              AnimatedFormSection(
                index: 3,
                child: TextField(
                  controller: _partialCtrl,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixText: '$currencySymbol ',
                    hintText: 'Amount received',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AnimatedFormSection(
              index: 4,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Confirm Dispatch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard({
    required _PaymentMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _mode = mode);
        if (mode == _PaymentMode.partial) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _focusNode.requestFocus();
          });
        }
      },
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? color : border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.radio_button_checked, color: color, size: 18)
            else Icon(Icons.radio_button_unchecked, color: border, size: 18),
          ],
        ),
      ),
    );
  }
}

enum _PaymentMode { paid, partial, pending }

/// Expose result type publicly so dispatch planner can use it
class DispatchPaymentResult {
  final PaymentStatus status;
  final double paidAmount;
  const DispatchPaymentResult(this.status, this.paidAmount);

  static Future<DispatchPaymentResult?> show(
    BuildContext context, {
    required String shopName,
    required int quantity,
    required double ratePerUnit,
    required DeliverySlot slot,
  }) async {
    final result = await PaymentBottomSheet.showDispatch(
      context,
      shopName: shopName,
      quantity: quantity,
      ratePerUnit: ratePerUnit,
      slot: slot,
    );
    return result;
  }
}
