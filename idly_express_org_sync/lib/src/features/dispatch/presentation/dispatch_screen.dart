import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../../domain/business_types.dart';
import '../../../domain/sales_entry.dart';
import '../../../domain/supply_template.dart';
import '../../sales/presentation/sale_editor_sheet.dart';
import '../../workspace/application/workspace_data_controller.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({
    super.key,
    required this.workspace,
  });

  final WorkspaceDataController workspace;

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  DateTime _selectedDate = DateTime.now();
  late final PageController _slotPageController;
  DeliverySlot _visibleSlot = DeliverySlot.morning;

  @override
  void initState() {
    super.initState();
    _slotPageController = PageController();
  }

  @override
  void dispose() {
    _slotPageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.workspace.templates.where((template) => template.isActiveOnDate(_selectedDate)).toList();
    final datedExternalOrders = widget.workspace.sales
        .where(
          (sale) =>
              sale.orderType == OrderType.externalOrder &&
              sale.date.year == _selectedDate.year &&
              sale.date.month == _selectedDate.month &&
              sale.date.day == _selectedDate.day,
        )
        .toList();
    final morning = templates.where((template) => widget.workspace.quantityForSlot(template, DeliverySlot.morning) > 0).toList()
      ..sort((left, right) => _compareTemplatesForDispatch(left, right, DeliverySlot.morning));
    final evening = templates.where((template) => widget.workspace.quantityForSlot(template, DeliverySlot.evening) > 0).toList()
      ..sort((left, right) => _compareTemplatesForDispatch(left, right, DeliverySlot.evening));
    final morningExternalOrders = datedExternalOrders
        .where((sale) => sale.deliverySlot == DeliverySlot.morning)
        .toList()
      ..sort((left, right) => left.shopName.toLowerCase().compareTo(right.shopName.toLowerCase()));
    final eveningExternalOrders = datedExternalOrders
        .where((sale) => sale.deliverySlot == DeliverySlot.evening)
        .toList()
      ..sort((left, right) => left.shopName.toLowerCase().compareTo(right.shopName.toLowerCase()));
    final totalDispatchItems = templates.length + datedExternalOrders.length;
    final morningCount = morning.length + morningExternalOrders.length;
    final eveningCount = evening.length + eveningExternalOrders.length;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                BrandSectionHeader(
                  title: 'Dispatch',
                  subtitle: '$totalDispatchItems items on this day, including customer orders.',
                  trailing: _DateChip(date: _selectedDate, onTap: _pickDate),
                ),
                const SizedBox(height: 16),
                if (templates.isNotEmpty || datedExternalOrders.isNotEmpty)
                  _DispatchSlotSwitcher(
                    selectedSlot: _visibleSlot,
                    morningCount: morningCount,
                    eveningCount: eveningCount,
                    onSelected: (slot) {
                      setState(() => _visibleSlot = slot);
                      _slotPageController.animateToPage(
                        slot == DeliverySlot.morning ? 0 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
              ],
            ),
          ),
          if (templates.isEmpty && datedExternalOrders.isEmpty)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: BrandEmptyState(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Nothing to dispatch today',
                  message: 'No supply templates are scheduled for this day. Tap the date chip above to pick another day.',
                ),
              ),
            )
          else
            Expanded(
              child: PageView(
                key: const ValueKey('dispatchSlotPager'),
                controller: _slotPageController,
                onPageChanged: (index) {
                  setState(() => _visibleSlot = index == 0 ? DeliverySlot.morning : DeliverySlot.evening);
                },
                children: [
                  _DispatchSlotPage(
                    title: 'Morning',
                    icon: Icons.wb_sunny_outlined,
                    slot: DeliverySlot.morning,
                    templates: morning,
                    externalOrders: morningExternalOrders,
                    selectedDate: _selectedDate,
                    workspace: widget.workspace,
                  ),
                  _DispatchSlotPage(
                    title: 'Evening',
                    icon: Icons.brightness_3_outlined,
                    slot: DeliverySlot.evening,
                    templates: evening,
                    externalOrders: eveningExternalOrders,
                    selectedDate: _selectedDate,
                    workspace: widget.workspace,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _compareTemplatesForDispatch(SupplyTemplate left, SupplyTemplate right, DeliverySlot slot) {
    final leftRank = _dispatchSortRank(left, slot);
    final rightRank = _dispatchSortRank(right, slot);
    if (leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }
    return left.shopName.toLowerCase().compareTo(right.shopName.toLowerCase());
  }

  int _dispatchSortRank(SupplyTemplate template, DeliverySlot slot) {
    final hasLeave = widget.workspace.findDispatchLeaveForTemplate(template, _selectedDate, slot) != null;
    if (hasLeave) {
      return 1;
    }
    final dispatched = widget.workspace.dispatchEntryForTemplate(template, _selectedDate, slot) != null;
    return dispatched ? 2 : 0;
  }
}

class _DispatchSlotSwitcher extends StatelessWidget {
  const _DispatchSlotSwitcher({
    required this.selectedSlot,
    required this.morningCount,
    required this.eveningCount,
    required this.onSelected,
  });

  final DeliverySlot selectedSlot;
  final int morningCount;
  final int eveningCount;
  final ValueChanged<DeliverySlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.brand.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.brand.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DispatchSlotButton(
              key: const ValueKey('dispatchSlotMorningButton'),
              label: 'Morning',
              icon: Icons.wb_sunny_outlined,
              count: morningCount,
              selected: selectedSlot == DeliverySlot.morning,
              onTap: () => onSelected(DeliverySlot.morning),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _DispatchSlotButton(
              key: const ValueKey('dispatchSlotEveningButton'),
              label: 'Evening',
              icon: Icons.brightness_3_outlined,
              count: eveningCount,
              selected: selectedSlot == DeliverySlot.evening,
              onTap: () => onSelected(DeliverySlot.evening),
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchSlotButton extends StatelessWidget {
  const _DispatchSlotButton({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.brand.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? BrandTokens.primary : context.brand.textMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? context.brand.textStrong : context.brand.textBody,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.82) : context.brand.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? BrandTokens.primaryDeep : context.brand.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DispatchSlotPage extends StatelessWidget {
  const _DispatchSlotPage({
    required this.title,
    required this.icon,
    required this.slot,
    required this.templates,
    required this.externalOrders,
    required this.selectedDate,
    required this.workspace,
  });

  final String title;
  final IconData icon;
  final DeliverySlot slot;
  final List<SupplyTemplate> templates;
  final List<SalesEntry> externalOrders;
  final DateTime selectedDate;
  final WorkspaceDataController workspace;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _DispatchSection(
          title: title,
          icon: icon,
          slot: slot,
          templates: templates,
          externalOrders: externalOrders,
          selectedDate: selectedDate,
          workspace: workspace,
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.surfaceCard,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.brand.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: BrandTokens.primary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(fontWeight: FontWeight.w800, color: context.brand.textStrong, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DispatchSection extends StatelessWidget {
  const _DispatchSection({
    required this.title,
    required this.icon,
    required this.slot,
    required this.templates,
    required this.externalOrders,
    required this.selectedDate,
    required this.workspace,
  });

  final String title;
  final IconData icon;
  final DeliverySlot slot;
  final List<SupplyTemplate> templates;
  final List<SalesEntry> externalOrders;
  final DateTime selectedDate;
  final WorkspaceDataController workspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: BrandTokens.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: context.brand.textStrong,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.brand.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${templates.length + externalOrders.length}',
                style: const TextStyle(color: BrandTokens.primaryDeep, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (templates.isEmpty && externalOrders.isEmpty)
          BrandCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              'No $title dispatch planned.',
              style: TextStyle(color: context.brand.textMuted),
            ),
          )
        else
          ...templates.map((template) {
            final leave = workspace.findDispatchLeaveForTemplate(template, selectedDate, slot) != null;
            final dispatchedSale = workspace.dispatchEntryForTemplate(template, selectedDate, slot);
            final dispatched = dispatchedSale != null;
            final qty = workspace.quantityForSlot(template, slot);
            final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BrandCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.shopName,
                            style: TextStyle(fontWeight: FontWeight.w800, color: context.brand.textStrong, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dispatched)
                          _DispatchStatusBadge(label: 'Dispatched', color: context.brand.successFg, bg: context.brand.successBg)
                        else if (leave)
                          _DispatchStatusBadge(label: 'Skipped today', color: context.brand.warningFg, bg: context.brand.warningBg),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dispatchedSale == null
                          ? '${template.productType.displayName} • Qty $qty'
                          : '${template.productType.displayName} • Planned $qty • Dispatched ${dispatchedSale.quantity} • ${currency.format(dispatchedSale.totalSalesAmount)}',
                      style: TextStyle(color: context.brand.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 148,
                          child: FilledButton.tonalIcon(
                            onPressed: dispatched || leave
                                ? null
                                : () => _confirmAndDispatch(
                                      context: context,
                                      workspace: workspace,
                                      template: template,
                                      date: selectedDate,
                                      slot: slot,
                                      quantity: qty,
                                    ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Dispatch'),
                          ),
                        ),
                        SizedBox(
                          width: 148,
                          child: OutlinedButton.icon(
                            onPressed: dispatched
                                ? null
                                : () => workspace.toggleDispatchLeave(template: template, date: selectedDate, slot: slot),
                            icon: Icon(leave ? Icons.undo_rounded : Icons.do_not_disturb_alt_outlined, size: 18),
                            label: Text(leave ? 'Resume today' : 'Skip today'),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openExtraOrderSheet(
                            context: context,
                            workspace: workspace,
                            template: template,
                            date: selectedDate,
                            slot: slot,
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('Extra order'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          ...externalOrders.map(
            (sale) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExternalOrderDispatchCard(sale: sale),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndDispatch({
    required BuildContext context,
    required WorkspaceDataController workspace,
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
    required int quantity,
  }) async {
    final result = await showModalBottomSheet<_DispatchPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DispatchPaymentSheet(
        shopName: template.shopName,
        totalAmount: template.ratePerUnit * quantity,
      ),
    );

    if (result == null) {
      return;
    }

    await workspace.dispatchTemplate(
      template: template,
      date: date,
      slot: slot,
      paymentStatus: result.paymentStatus,
      paidAmount: result.paidAmount,
    );

    if (!context.mounted) {
      return;
    }

    if (workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${template.shopName} marked as dispatched')),
      );
    }
  }

  Future<void> _openExtraOrderSheet({
    required BuildContext context,
    required WorkspaceDataController workspace,
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
  }) async {
    final seedSale = SalesEntry(
      id: '',
      organizationId: '',
      date: DateTime(date.year, date.month, date.day),
      shopName: template.shopName,
      orderType: OrderType.externalOrder,
      deliverySlot: slot,
      deliveryTime: template.deliveryTime,
      prepLeadDays: template.prepLeadDays,
      productType: template.productType,
      saleType: template.saleType,
      ratePerUnit: template.ratePerUnit,
      quantity: 1,
      costPerUnit: template.costPerUnit,
      paymentStatus: PaymentStatus.pending,
      paidAmount: 0,
      customerMobile: template.shopMobile,
      notes: 'Extra order for ${template.shopName}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaleEditorSheet(
        workspace: workspace,
        initialDraftSale: seedSale,
      ),
    );
  }
}

class _ExternalOrderDispatchCard extends StatelessWidget {
  const _ExternalOrderDispatchCard({required this.sale});

  final SalesEntry sale;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final brand = context.brand;
    final pendingAmount = sale.pendingAmount;

    return BrandCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sale.shopName,
                  style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _DispatchStatusBadge(label: 'External order', color: BrandTokens.primaryDeep, bg: brand.primarySoft),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${sale.productType.displayName} • Qty ${sale.quantity} • ${currency.format(sale.totalSalesAmount)}',
            style: TextStyle(color: brand.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DispatchStatusBadge(
                label: pendingAmount > 0.01 ? 'Pending ${currency.format(pendingAmount)}' : 'Paid',
                color: pendingAmount > 0.01 ? brand.warningFg : brand.successFg,
                bg: pendingAmount > 0.01 ? brand.warningBg : brand.successBg,
              ),
              if (sale.deliveryTime?.trim().isNotEmpty == true)
                _DispatchStatusBadge(label: sale.deliveryTime!.trim(), color: brand.textLabel, bg: brand.surfaceSoft),
              if (sale.customerMobile?.trim().isNotEmpty == true)
                _DispatchStatusBadge(label: sale.customerMobile!.trim(), color: brand.textLabel, bg: brand.surfaceSoft),
            ],
          ),
        ],
      ),
    );
  }
}

enum _DispatchPaymentChoice { paid, payLater, partial }

class _DispatchPaymentResult {
  const _DispatchPaymentResult({required this.paymentStatus, required this.paidAmount});

  final PaymentStatus paymentStatus;
  final double paidAmount;
}

class _DispatchPaymentSheet extends StatefulWidget {
  const _DispatchPaymentSheet({
    required this.shopName,
    required this.totalAmount,
  });

  final String shopName;
  final double totalAmount;

  @override
  State<_DispatchPaymentSheet> createState() => _DispatchPaymentSheetState();
}

class _DispatchPaymentSheetState extends State<_DispatchPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _partialController = TextEditingController();
  _DispatchPaymentChoice _choice = _DispatchPaymentChoice.paid;

  @override
  void dispose() {
    _partialController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_choice == _DispatchPaymentChoice.partial && !_formKey.currentState!.validate()) {
      return;
    }

    final result = switch (_choice) {
      _DispatchPaymentChoice.paid => _DispatchPaymentResult(
          paymentStatus: PaymentStatus.paid,
          paidAmount: widget.totalAmount,
        ),
      _DispatchPaymentChoice.payLater => const _DispatchPaymentResult(
          paymentStatus: PaymentStatus.pending,
          paidAmount: 0,
        ),
      _DispatchPaymentChoice.partial => _DispatchPaymentResult(
          paymentStatus: PaymentStatus.pending,
          paidAmount: double.parse(_partialController.text.trim()),
        ),
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: brand.surfaceSheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
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
                  'Payment for ${widget.shopName}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order total ${currency.format(widget.totalAmount)}',
                  style: TextStyle(color: brand.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _PaymentOptionTile(
                  label: 'Paid',
                  description: 'Shop paid in full now.',
                  icon: Icons.check_circle_rounded,
                  value: _DispatchPaymentChoice.paid,
                  groupValue: _choice,
                  onChanged: (value) => setState(() => _choice = value),
                ),
                _PaymentOptionTile(
                  label: 'Will pay later',
                  description: 'Record the full amount as pending.',
                  icon: Icons.schedule_rounded,
                  value: _DispatchPaymentChoice.payLater,
                  groupValue: _choice,
                  onChanged: (value) => setState(() => _choice = value),
                ),
                _PaymentOptionTile(
                  label: 'Partially paid',
                  description: 'Shop paid part of the amount now.',
                  icon: Icons.pie_chart_outline_rounded,
                  value: _DispatchPaymentChoice.partial,
                  groupValue: _choice,
                  onChanged: (value) => setState(() => _choice = value),
                ),
                if (_choice == _DispatchPaymentChoice.partial) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _partialController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Amount paid now',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final paid = double.tryParse(value?.trim() ?? '');
                      if (paid == null || paid <= 0) {
                        return 'Enter the amount paid now.';
                      }
                      if (paid >= widget.totalAmount) {
                        return 'Use "Paid" when the full amount is paid.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Mark as dispatched'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
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
  final _DispatchPaymentChoice value;
  final _DispatchPaymentChoice groupValue;
  final ValueChanged<_DispatchPaymentChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? brand.primarySoft : brand.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? BrandTokens.primary : brand.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: selected ? BrandTokens.primary : brand.textMuted, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(color: brand.textMuted, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: selected ? BrandTokens.primary : brand.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DispatchStatusBadge extends StatelessWidget {
  const _DispatchStatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
