import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/sales_entry_model.dart';
import '../providers/sales_provider.dart';
import '../services/database_service.dart';
import '../widgets/animated_form_section.dart';

/// Animated external order entry form.
/// Captures customer name, mobile, product, quantity, rate, and payment.
class ExternalOrderForm extends StatefulWidget {
  const ExternalOrderForm({super.key});

  @override
  State<ExternalOrderForm> createState() => _ExternalOrderFormState();
}

class _ExternalOrderFormState extends State<ExternalOrderForm> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  ProductType _product = ProductType.idly;
  SaleType _saleType = SaleType.wholesale;
  DeliverySlot _slot = DeliverySlot.morning;
  PaymentStatus _paymentStatus = PaymentStatus.paid;

  List<String> _shopSuggestions = [];
  List<Map<String, String>> _recentCustomers = [];
  bool _saving = false;

  double get _total {
    final q = int.tryParse(_quantityCtrl.text) ?? 0;
    final r = double.tryParse(_rateCtrl.text) ?? 0;
    return q * r;
  }

  @override
  void initState() {
    super.initState();
    _rateCtrl.text = defaultWholesaleRate.toString();
    _costCtrl.text = '2.5';
    _paidAmountCtrl.text = '0';
    _loadRecent();
    _quantityCtrl.addListener(_updateTotal);
    _rateCtrl.addListener(_updateTotal);
  }

  void _updateTotal() => setState(() {});

  Future<void> _loadRecent() async {
    final recent = await DatabaseService.instance.getRecentExternalCustomers();
    if (mounted) setState(() => _recentCustomers = recent);
  }

  Future<void> _onShopNameChanged(String query) async {
    if (query.length < 2) {
      setState(() => _shopSuggestions = []);
      return;
    }
    final sug = await DatabaseService.instance.getShopSuggestions(query);
    if (mounted) setState(() => _shopSuggestions = sug);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _mobileCtrl.dispose();
    _quantityCtrl.dispose();
    _rateCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final quantity = int.parse(_quantityCtrl.text);
      final rate = double.parse(_rateCtrl.text);
      final cost = double.tryParse(_costCtrl.text) ?? 0;
      final paid = _paymentStatus == PaymentStatus.paid
          ? quantity * rate
          : (double.tryParse(_paidAmountCtrl.text) ?? 0);

      final entry = SalesEntry(
        date: _date,
        shopName: _shopNameCtrl.text.trim(),
        orderType: OrderType.externalOrder,
        deliverySlot: _slot,
        productType: _product,
        saleType: _saleType,
        ratePerUnit: rate,
        quantity: quantity,
        costPerUnit: cost,
        paymentStatus: _paymentStatus,
        paidAmount: paid,
        customerMobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (mounted) {
        await Provider.of<SalesProvider>(context, listen: false).addEntry(entry);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order saved ✓'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primary = Theme.of(context).colorScheme.primary;

    InputDecoration fieldDeco(String label, {String? hint, Widget? suffix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: Color(0xFFE53E3E))),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('External Order', style: TextStyle(color: textPrimary)),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // Recent customers chips
            if (_recentCustomers.isNotEmpty) ...[
              AnimatedFormSection(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Customers', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _recentCustomers.take(5).map((c) => ActionChip(
                        label: Text(c['name'] ?? ''),
                        avatar: const Icon(Icons.history, size: 14),
                        onPressed: () {
                          _shopNameCtrl.text = c['name'] ?? '';
                          _mobileCtrl.text = c['mobile'] ?? '';
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            // Shop/Customer name
            AnimatedFormSection(
              index: 1,
              child: Autocomplete<String>(
                optionsBuilder: (tv) async {
                  if (tv.text.length < 2) return [];
                  return await DatabaseService.instance.getShopSuggestions(tv.text);
                },
                onSelected: (v) => _shopNameCtrl.text = v,
                fieldViewBuilder: (ctx, ctrl, fn, _) {
                  if (_shopNameCtrl.text.isNotEmpty && ctrl.text != _shopNameCtrl.text) {
                    ctrl.text = _shopNameCtrl.text;
                  }
                  return TextFormField(
                    controller: ctrl,
                    focusNode: fn,
                    onChanged: (v) { _shopNameCtrl.text = v; _onShopNameChanged(v); },
                    decoration: fieldDeco('Customer / Shop Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Mobile
            AnimatedFormSection(
              index: 2,
              child: TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: fieldDeco('Customer Mobile', hint: 'Optional'),
              ),
            ),
            const SizedBox(height: 14),

            // Date
            AnimatedFormSection(
              index: 3,
              child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(_date),
                        style: TextStyle(color: textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Product + Slot row
            AnimatedFormSection(
              index: 4,
              child: Row(
                children: [
                  Expanded(
                    child: _DropdownField<ProductType>(
                      label: 'Product',
                      value: _product,
                      items: ProductType.values,
                      labelOf: (p) => p.displayName,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (v) => setState(() => _product = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownField<DeliverySlot>(
                      label: 'Slot',
                      value: _slot,
                      items: DeliverySlot.values,
                      labelOf: (s) => s.displayName,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (v) => setState(() => _slot = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sale type
            AnimatedFormSection(
              index: 5,
              child: _DropdownField<SaleType>(
                label: 'Sale Type',
                value: _saleType,
                items: SaleType.values,
                labelOf: (s) => s.displayName,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (v) {
                  setState(() {
                    _saleType = v!;
                    _rateCtrl.text = v == SaleType.wholesale
                        ? defaultWholesaleRate.toString()
                        : defaultRetailRate.toString();
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // Qty + Rate row
            AnimatedFormSection(
              index: 6,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: fieldDeco('Quantity'),
                      validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: fieldDeco('Rate ($currencySymbol)'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Total preview
            if (_total > 0)
              AnimatedFormSection(
                index: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Total: $currencySymbol${_total.toStringAsFixed(0)}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Cost per unit
            AnimatedFormSection(
              index: 8,
              child: TextFormField(
                controller: _costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: fieldDeco('Cost/Unit ($currencySymbol)'),
              ),
            ),
            const SizedBox(height: 14),

            // Payment
            AnimatedFormSection(
              index: 9,
              child: _DropdownField<PaymentStatus>(
                label: 'Payment Status',
                value: _paymentStatus,
                items: PaymentStatus.values,
                labelOf: (s) => s.displayName,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (v) {
                  setState(() {
                    _paymentStatus = v!;
                    if (v == PaymentStatus.paid) _paidAmountCtrl.text = _total.toStringAsFixed(0);
                  });
                },
              ),
            ),
            if (_paymentStatus == PaymentStatus.pending) ...[
              const SizedBox(height: 14),
              AnimatedFormSection(
                index: 10,
                child: TextFormField(
                  controller: _paidAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: fieldDeco('Amount Already Paid ($currencySymbol)', hint: '0 if fully pending'),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Notes
            AnimatedFormSection(
              index: 11,
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: fieldDeco('Notes', hint: 'Optional'),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            AnimatedFormSection(
              index: 12,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final Color surface, border, textPrimary, textSecondary;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(labelOf(i)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      ),
      dropdownColor: surface,
    );
  }
}
