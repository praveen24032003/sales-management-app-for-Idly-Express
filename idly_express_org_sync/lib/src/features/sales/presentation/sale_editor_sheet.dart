import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../domain/business_types.dart';
import '../../../domain/sales_entry.dart';
import '../../../domain/supply_template.dart';
import '../../templates/presentation/templates_screen.dart';
import '../../workspace/application/workspace_data_controller.dart';

class SaleEditorSheet extends StatefulWidget {
  const SaleEditorSheet({
    super.key,
    required this.workspace,
    this.existingSale,
    this.initialDraftSale,
  });

  final WorkspaceDataController workspace;
  final SalesEntry? existingSale;
  final SalesEntry? initialDraftSale;

  bool get isEditing => existingSale != null;

  @override
  State<SaleEditorSheet> createState() => _SaleEditorSheetState();
}

class _SaleEditorSheetState extends State<SaleEditorSheet> {
  static const _dispatchNotePrefix = '[dispatch:';

  static const List<double> _commonRates = [3.5, 4.0, 5.0];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopController;
  late final TextEditingController _customerMobileController;
  late final TextEditingController _rateController;
  late final TextEditingController _quantityController;
  late final TextEditingController _costController;
  late final TextEditingController _paidAmountController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late OrderType _orderType;
  late DeliverySlot _deliverySlot;
  TimeOfDay? _deliveryTime;
  late int _prepLeadDays;
  late ProductType _productType;
  late SaleType _saleType;
  late _SalePaymentChoice _paymentChoice;

  double _totalSales = 0;
  double _totalCost = 0;
  double _profit = 0;

  bool get _isDispatchManagedSale {
    final notes = widget.existingSale?.notes?.trim();
    return notes != null && notes.startsWith(_dispatchNotePrefix);
  }

  String? get _dispatchTemplateId {
    final notes = widget.existingSale?.notes?.trim();
    if (notes == null || !notes.startsWith(_dispatchNotePrefix)) {
      return null;
    }

    final closingIndex = notes.indexOf(']');
    if (closingIndex == -1) {
      return null;
    }

    final payload = notes.substring(_dispatchNotePrefix.length, closingIndex);
    final separatorIndex = payload.indexOf('|');
    if (separatorIndex <= 0) {
      return null;
    }

    return payload.substring(0, separatorIndex);
  }

  SupplyTemplate? get _dispatchTemplate {
    final templateId = _dispatchTemplateId;
    if (templateId == null) {
      return null;
    }

    for (final template in widget.workspace.templates) {
      if (template.id == templateId) {
        return template;
      }
    }
    return null;
  }

  SalesEntry? get _seedSale => widget.existingSale ?? widget.initialDraftSale;

  @override
  void initState() {
    super.initState();
    final sale = _seedSale;
    _selectedDate = sale?.date ?? DateTime.now();
    _orderType = sale?.orderType ?? OrderType.externalOrder;
    _deliverySlot = sale?.deliverySlot ?? DeliverySlot.morning;
    _deliveryTime = _parseTime(sale?.deliveryTime);
    _prepLeadDays = sale?.prepLeadDays ?? 1;
    _productType = sale?.productType ?? ProductType.idly;
    _saleType = sale?.saleType ?? SaleType.wholesale;
    _paymentChoice = _initialPaymentChoice(sale);

    _shopController = TextEditingController(text: sale?.shopName ?? '');
    _customerMobileController = TextEditingController(text: sale?.customerMobile ?? '');
    _rateController = TextEditingController(
      text: sale != null ? _formatDecimal(sale.ratePerUnit) : _formatDecimal(_defaultRateFor(_orderType)),
    );
    _quantityController = TextEditingController(text: sale != null ? sale.quantity.toString() : '100');
    _costController = TextEditingController(text: sale != null ? _formatDecimal(sale.costPerUnit) : '2.5');
    _paidAmountController = TextEditingController(
      text: sale?.paidAmount != null ? _formatDecimal(sale!.paidAmount!) : '',
    );
    _notesController = TextEditingController(text: _visibleNotes(sale?.notes));

    _rateController.addListener(_recalculateTotals);
    _quantityController.addListener(_recalculateTotals);
    _costController.addListener(_recalculateTotals);
    _recalculateTotals();
  }

  @override
  void dispose() {
    _shopController.dispose();
    _customerMobileController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final brand = context.brand;

    return Container(
      decoration: BoxDecoration(
        color: context.brand.surfaceSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: brand.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  widget.isEditing ? 'Edit sale entry' : 'Add sale entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _orderType == OrderType.externalOrder
                      ? 'Record the customer order now so it stays visible in Dispatch on delivery day.'
                      : 'Record the recurring supply details and payment status clearly.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: brand.textMuted, height: 1.4),
                ),
                if (_isDispatchManagedSale) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brand.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.lock_outline_rounded, size: 18, color: BrandTokens.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This sale came from a dispatch template. Shop, schedule, and product fields stay locked here. Edit quantity, pricing, payment, or notes here, or edit the template instead to change the recurring setup.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: brand.textStrong,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_dispatchTemplate != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _openDispatchTemplate,
                        icon: const Icon(Icons.repeat_rounded, size: 18),
                        label: const Text('Edit template instead'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildDispatchManagedHeader(context),
                ],
                const SizedBox(height: 16),
                _buildSectionCard(
                  context: context,
                  title: 'Order details',
                  icon: Icons.event_note_rounded,
                  subtitle: _isDispatchManagedSale
                      ? 'Dispatch schedule fields are locked here because this sale came from the planner.'
                      : 'Choose the delivery timing and prep window clearly.',
                  child: Column(
                    children: [
                      _EnumDropdown<OrderType>(
                        label: 'Order type',
                        value: _orderType,
                        values: OrderType.values,
                        itemLabel: (value) => value.displayName,
                        enabled: !_isDispatchManagedSale,
                        onChanged: _onOrderTypeChanged,
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveFieldPair(
                        left: _buildDatePicker(context, enabled: !_isDispatchManagedSale),
                        right: _EnumDropdown<DeliverySlot>(
                          label: 'Delivery slot',
                          value: _deliverySlot,
                          values: DeliverySlot.values,
                          itemLabel: (value) => value.displayName,
                          enabled: !_isDispatchManagedSale,
                          onChanged: (value) => setState(() => _deliverySlot = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveFieldPair(
                        left: _buildDeliveryTimePicker(context, enabled: !_isDispatchManagedSale),
                        right: _EnumDropdown<int>(
                          label: 'Prep lead days',
                          value: _prepLeadDays,
                          values: const [1, 2, 3],
                          itemLabel: (value) => '$value day${value == 1 ? '' : 's'}',
                          enabled: !_isDispatchManagedSale,
                          onChanged: (value) => setState(() => _prepLeadDays = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  context: context,
                  title: _orderType == OrderType.externalOrder ? 'Customer details' : 'Shop details',
                  icon: _orderType == OrderType.externalOrder ? Icons.person_rounded : Icons.storefront_rounded,
                  subtitle: _orderType == OrderType.externalOrder
                      ? (_isDispatchManagedSale
                          ? 'Customer identity came from Dispatch and stays locked in this editor.'
                          : 'Use the customer name here so the order is easy to spot on dispatch day.')
                      : (_isDispatchManagedSale
                          ? 'Shop identity came from Dispatch and stays locked in this editor.'
                          : 'Use the recurring shop details tied to everyday supply.'),
                  child: Column(
                    children: [
                      _buildPartyAutocomplete(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customerMobileController,
                        decoration: InputDecoration(
                          labelText: _orderType == OrderType.externalOrder ? 'Customer mobile' : 'Shop mobile',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_isDispatchManagedSale) ...[
                  _buildSectionCard(
                    context: context,
                    title: 'Template product',
                    icon: Icons.inventory_2_rounded,
                    subtitle: 'Product identity came from Dispatch and stays locked here.',
                    child: _ResponsiveFieldPair(
                      left: _EnumDropdown<ProductType>(
                        label: 'Product',
                        value: _productType,
                        values: ProductType.values,
                        itemLabel: (value) => value.displayName,
                        enabled: false,
                        onChanged: (value) => setState(() => _productType = value),
                      ),
                      right: _EnumDropdown<SaleType>(
                        label: 'Sale type',
                        value: _saleType,
                        values: SaleType.values,
                        itemLabel: (value) => value.displayName,
                        enabled: false,
                        onChanged: (value) => setState(() => _saleType = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    context: context,
                    title: 'Quantity and pricing',
                    icon: Icons.tune_rounded,
                    subtitle: 'These fields stay editable so you can correct actual dispatch details.',
                    child: _buildPricingFields(context),
                  ),
                ] else
                  _buildSectionCard(
                    context: context,
                    title: 'Product and pricing',
                    icon: Icons.sell_rounded,
                    subtitle: 'Quick rate picks keep the most common pricing one tap away.',
                    child: Column(
                      children: [
                        _ResponsiveFieldPair(
                          left: _EnumDropdown<ProductType>(
                            label: 'Product',
                            value: _productType,
                            values: ProductType.values,
                            itemLabel: (value) => value.displayName,
                            enabled: true,
                            onChanged: (value) => setState(() => _productType = value),
                          ),
                          right: _EnumDropdown<SaleType>(
                            label: 'Sale type',
                            value: _saleType,
                            values: SaleType.values,
                            itemLabel: (value) => value.displayName,
                            enabled: true,
                            onChanged: (value) => setState(() => _saleType = value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPricingFields(context),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  context: context,
                  title: 'Payment',
                  icon: Icons.account_balance_wallet_rounded,
                  subtitle: 'Keep the payment choice explicit so follow-up collection is clear.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PaymentChoiceTile(
                        label: 'Paid',
                        description: 'Customer paid the full amount now.',
                        icon: Icons.check_circle_rounded,
                        value: _SalePaymentChoice.paid,
                        groupValue: _paymentChoice,
                        onChanged: _onPaymentChoiceChanged,
                      ),
                      _PaymentChoiceTile(
                        label: 'Pending',
                        description: 'Customer paid only part now or you want to record an advance.',
                        icon: Icons.hourglass_bottom_rounded,
                        value: _SalePaymentChoice.pending,
                        groupValue: _paymentChoice,
                        onChanged: _onPaymentChoiceChanged,
                      ),
                      _PaymentChoiceTile(
                        label: 'Will collect later',
                        description: 'No money collected now. Keep the full amount pending.',
                        icon: Icons.schedule_rounded,
                        value: _SalePaymentChoice.collectLater,
                        groupValue: _paymentChoice,
                        onChanged: _onPaymentChoiceChanged,
                      ),
                      if (_paymentChoice == _SalePaymentChoice.pending) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paidAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount paid',
                            helperText: 'Enter advance received. Use 0 if nothing was collected yet.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _validatePaidAmount,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: brand.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calculate_rounded, size: 18, color: BrandTokens.primary),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Live totals',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CalculatedRow(label: 'Total sales', value: currency.format(_totalSales)),
                        const Divider(),
                        _CalculatedRow(label: 'Total cost', value: currency.format(_totalCost)),
                        const Divider(),
                        _CalculatedRow(
                          label: 'Profit',
                          value: currency.format(_profit),
                          valueColor: _profit >= 0 ? Colors.green : Colors.red,
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  context: context,
                  title: 'Notes',
                  icon: Icons.sticky_note_2_rounded,
                  subtitle: 'Add anything the team should remember while dispatching.',
                  child: TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submit,
                  child: Text(widget.isEditing ? 'Update sale' : 'Save sale'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String subtitle,
    required Widget child,
  }) {
    final brand = context.brand;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: brand.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: BrandTokens.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: brand.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchManagedHeader(BuildContext context) {
    final brand = context.brand;

    return Row(
      children: [
        Text(
          'Template-managed details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: brand.textStrong,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: brand.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Locked',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: BrandTokens.primaryDeep,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingFields(BuildContext context) {
    final brand = context.brand;

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Common rates',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: brand.textMuted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: brand.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Popular',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BrandTokens.primaryDeep,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _commonRates
                .map(
                  (rate) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('₹${_formatDecimal(rate)}'),
                      selected: _selectedRate == rate,
                      onSelected: (_) => _selectRate(rate),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rateController,
          decoration: InputDecoration(
            labelText: 'Rate per unit',
            helperText: _orderType == OrderType.externalOrder
                ? 'External orders default to ₹5. Common rates: ₹3.5, ₹4, ₹5.'
                : 'Everyday supply defaults to ₹3.5. You can still adjust it here.',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => _validatePositiveDecimal(value, 'Enter a valid rate.'),
        ),
        const SizedBox(height: 12),
        _ResponsiveFieldPair(
          left: TextFormField(
            key: const ValueKey('saleEditorQuantityField'),
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            validator: (value) => _validatePositiveInt(value, 'Enter a valid quantity.'),
          ),
          right: TextFormField(
            controller: _costController,
            decoration: const InputDecoration(labelText: 'Cost per unit'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _validatePositiveDecimal(value, 'Enter a valid cost.'),
          ),
        ),
      ],
    );
  }

  void _openDispatchTemplate() {
    final template = _dispatchTemplate;
    final templateId = _dispatchTemplateId;
    if (template == null || templateId == null) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    rootNavigator.push(
      MaterialPageRoute<void>(
        builder: (_) => TemplatesScreen(
          workspace: widget.workspace,
          initialTemplateId: templateId,
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool enabled}) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'Dispatch date', enabled: enabled),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 12),
            Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimePicker(BuildContext context, {required bool enabled}) {
    final label = _deliveryTime == null ? 'Tap to set time' : _deliveryTime!.format(context);
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _deliveryTime ?? const TimeOfDay(hour: 7, minute: 0),
        );
        if (picked != null) {
          setState(() => _deliveryTime = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Delivery time',
          enabled: enabled,
          suffixIcon: !enabled || _deliveryTime == null
              ? null
              : IconButton(
                  onPressed: () => setState(() => _deliveryTime = null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear time',
                ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyAutocomplete() {
    if (_isDispatchManagedSale) {
      return TextFormField(
        key: const ValueKey('saleEditorShopNameField'),
        controller: _shopController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: _orderType == OrderType.externalOrder ? 'Customer name' : 'Shop name',
        ),
      );
    }

    final suggestions = _partySuggestions();
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _shopController.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return suggestions.take(8);
        }
        return suggestions.where((item) => item.toLowerCase().contains(query)).take(8);
      },
      onSelected: (selection) => _shopController.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.value = TextEditingValue(
          text: _shopController.text,
          selection: TextSelection.collapsed(offset: _shopController.text.length),
        );
        controller.addListener(() => _shopController.text = controller.text);
        return TextFormField(
          key: const ValueKey('saleEditorShopNameField'),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: _orderType == OrderType.externalOrder ? 'Customer name' : 'Shop name'),
          validator: (value) => value == null || value.trim().isEmpty
              ? _orderType == OrderType.externalOrder
                  ? 'Enter customer name.'
                  : 'Enter shop name.'
              : null,
        );
      },
    );
  }

  List<String> _partySuggestions() {
    final values = <String>{};
    for (final sale in widget.workspace.sales) {
      if (sale.orderType == _orderType && sale.shopName.trim().isNotEmpty) {
        values.add(sale.shopName.trim());
      }
    }
    if (_orderType == OrderType.everydaySupply) {
      for (final template in widget.workspace.templates) {
        if (template.shopName.trim().isNotEmpty) {
          values.add(template.shopName.trim());
        }
      }
    }
    final contactType = _orderType == OrderType.externalOrder ? ContactType.customer : ContactType.shop;
    for (final contact in widget.workspace.contacts.where((item) => item.contactType == contactType)) {
      if (contact.name.trim().isNotEmpty) {
        values.add(contact.name.trim());
      }
    }
    final sorted = values.toList()..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    return sorted;
  }

  void _recalculateTotals() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;
    setState(() {
      _totalSales = rate * quantity;
      _totalCost = cost * quantity;
      _profit = _totalSales - _totalCost;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rate = double.parse(_rateController.text.trim());
    final quantity = int.parse(_quantityController.text.trim());
    final cost = double.parse(_costController.text.trim());
    final totalSales = rate * quantity;
    final paymentStatus = _paymentChoice == _SalePaymentChoice.paid ? PaymentStatus.paid : PaymentStatus.pending;
    final double paidAmount = switch (_paymentChoice) {
      _SalePaymentChoice.paid => totalSales,
      _SalePaymentChoice.pending => double.tryParse(_paidAmountController.text.trim()) ?? 0,
      _SalePaymentChoice.collectLater => 0.0,
    };
    final seedSale = _seedSale;

    final sale = SalesEntry(
      id: widget.existingSale?.id ?? '',
      organizationId: widget.existingSale?.organizationId ?? seedSale?.organizationId ?? '',
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      shopName: _shopController.text.trim(),
      orderType: _orderType,
      deliverySlot: _deliverySlot,
      deliveryTime: _formatTime(_deliveryTime),
      prepLeadDays: _prepLeadDays,
      productType: _productType,
      saleType: _saleType,
      ratePerUnit: rate,
      quantity: quantity,
      costPerUnit: cost,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      customerMobile: _customerMobileController.text.trim().isEmpty ? null : _customerMobileController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await widget.workspace.saveSale(sale);
    if (!mounted) {
      return;
    }

    if (widget.workspace.errorMessage == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Sale updated' : 'Sale saved')),
      );
    }
  }

  void _onOrderTypeChanged(OrderType value) {
    setState(() {
      _orderType = value;
      if (!widget.isEditing) {
        _rateController.text = _formatDecimal(_defaultRateFor(value));
      }
    });
    _recalculateTotals();
  }

  void _onPaymentChoiceChanged(_SalePaymentChoice value) {
    setState(() {
      _paymentChoice = value;
      if (value == _SalePaymentChoice.paid) {
        _paidAmountController.text = _formatDecimal(_totalSales);
      } else if (value == _SalePaymentChoice.collectLater) {
        _paidAmountController.text = '0';
      }
    });
  }

  _SalePaymentChoice _initialPaymentChoice(SalesEntry? sale) {
    if (sale == null) {
      return _SalePaymentChoice.paid;
    }
    if (sale.paymentStatus == PaymentStatus.paid) {
      return _SalePaymentChoice.paid;
    }
    if ((sale.paidAmount ?? 0) > 0) {
      return _SalePaymentChoice.pending;
    }
    return _SalePaymentChoice.collectLater;
  }

  double _defaultRateFor(OrderType orderType) {
    return orderType == OrderType.externalOrder ? 5.0 : 3.5;
  }

  String _visibleNotes(String? notes) {
    if (notes == null) {
      return '';
    }

    final trimmed = notes.trim();
    if (!trimmed.startsWith(_dispatchNotePrefix)) {
      return trimmed;
    }

    final closingIndex = trimmed.indexOf(']');
    if (closingIndex == -1) {
      return '';
    }

    return trimmed.substring(closingIndex + 1).trim();
  }

  double? get _selectedRate => double.tryParse(_rateController.text.trim());

  void _selectRate(double rate) {
    _rateController.text = _formatDecimal(rate);
    _recalculateTotals();
  }

  String? _validatePositiveDecimal(String? value, String message) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return message;
    }
    return null;
  }

  String? _validatePositiveInt(String? value, String message) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return message;
    }
    return null;
  }

  String? _validatePaidAmount(String? value) {
    final paid = double.tryParse(value?.trim() ?? '');
    if (paid == null || paid < 0) {
      return 'Enter a valid paid amount.';
    }
    if (paid > _totalSales) {
      return 'Paid amount cannot exceed total sales.';
    }
    return null;
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _formatTime(TimeOfDay? value) {
    if (value == null) {
      return null;
    }
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, enabled: enabled),
      items: values
          .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
          .toList(),
      onChanged: !enabled
          ? null
          : (nextValue) {
        if (nextValue != null) {
          onChanged(nextValue);
        }
      },
    );
  }
}

class _CalculatedRow extends StatelessWidget {
  const _CalculatedRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

enum _SalePaymentChoice { paid, pending, collectLater }

class _PaymentChoiceTile extends StatelessWidget {
  const _PaymentChoiceTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String description;
  final IconData icon;
  final _SalePaymentChoice value;
  final _SalePaymentChoice groupValue;
  final ValueChanged<_SalePaymentChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final brand = context.brand;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? brand.primarySoft : brand.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? BrandTokens.primary : brand.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? BrandTokens.primary : brand.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: brand.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? BrandTokens.primary : brand.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}