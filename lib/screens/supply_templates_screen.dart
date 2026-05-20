import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/supply_template_model.dart';
import '../providers/sales_provider.dart';
import '../core/theme.dart';

const Map<int, String> _weekdayLabels = {
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

class SupplyTemplatesScreen extends StatelessWidget {
  const SupplyTemplatesScreen({super.key});

  String _weekdaySummary(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted
        .map((d) => _weekdayLabels[d] ?? d.toString())
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Supply Templates')),
      body: Consumer<SalesProvider>(
        builder: (context, provider, _) {
          final templates = provider.supplyTemplates;
          if (templates.isEmpty) {
            return const Center(
              child: Text('No templates yet. Add one to auto-create daily orders.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    template.isActive ? Icons.repeat : Icons.pause_circle,
                        color: template.isActive ? context.profitColor : context.subtleText,
                  ),
                  title: Text('${template.shopName} • ${template.morningQuantity > 0 && template.eveningQuantity > 0 ? '${template.morningQuantity}+${template.eveningQuantity}' : template.quantity} pcs'),
                  subtitle: Text(
                    '${template.productType.displayName} • ${template.morningQuantity > 0 && template.eveningQuantity > 0 ? 'Morning + Evening' : template.deliverySlot.displayName}${template.deliveryTime != null ? ' (${template.deliveryTime})' : ''}\n'
                    'Days: ${_weekdaySummary(template.activeWeekdays)}\n'
                    'Rate: $currencySymbol${template.ratePerUnit} • Cost: $currencySymbol${template.costPerUnit}${template.shopMobile != null ? ' • ${template.shopMobile}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _openTemplateDialog(context, template: template);
                      } else if (value == 'toggle') {
                        await provider.updateSupplyTemplate(
                          template.copyWith(isActive: !template.isActive),
                        );
                      } else if (value == 'delete') {
                        await provider.deleteSupplyTemplate(template.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(template.isActive ? 'Disable' : 'Enable'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openTemplateDialog(BuildContext context, {SupplyTemplate? template}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TemplateFormDialog(template: template),
    );
  }
}

class _TemplateFormDialog extends StatefulWidget {
  final SupplyTemplate? template;

  const _TemplateFormDialog({this.template});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _shopController;
  late final TextEditingController _shopMobileController;
  late final TextEditingController _morningQtyController;
  late final TextEditingController _eveningQtyController;
  late final TextEditingController _rateController;
  late final TextEditingController _costController;

  late ProductType _productType;
  late SaleType _saleType;
  late DeliverySlot _deliverySlot;
  TimeOfDay? _deliveryTime;
  late int _prepLeadDays;
  late Set<int> _activeWeekdays;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _shopController = TextEditingController(text: t?.shopName ?? '');
    _shopMobileController = TextEditingController(text: t?.shopMobile ?? '');
    _morningQtyController = TextEditingController(text: t?.morningQuantity.toString() ?? '0');
    _eveningQtyController = TextEditingController(text: t?.eveningQuantity.toString() ?? '0');
    _rateController = TextEditingController(text: t?.ratePerUnit.toString() ?? '');
    _costController = TextEditingController(text: t?.costPerUnit.toString() ?? '');
    _productType = t?.productType ?? ProductType.values.first;
    _saleType = t?.saleType ?? SaleType.values.first;
    _deliverySlot = t?.deliverySlot ?? DeliverySlot.morning;
    _prepLeadDays = t?.prepLeadDays ?? 1;
    _activeWeekdays = {...(t?.activeWeekdays ?? {1, 2, 3, 4, 5, 6})};
    _startDate = t?.startDate;
    _endDate = t?.endDate;

    if ((t?.deliveryTime ?? '').isNotEmpty) {
      final parts = t!.deliveryTime!.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _deliveryTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }
  }

  @override
  void dispose() {
    _shopController.dispose();
    _shopMobileController.dispose();
    _morningQtyController.dispose();
    _eveningQtyController.dispose();
    _rateController.dispose();
    _costController.dispose();
    super.dispose();
  }

  String? _timeAsString() {
    if (_deliveryTime == null) return null;
    return '${_deliveryTime!.hour.toString().padLeft(2, '0')}:${_deliveryTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final morningQty = int.tryParse(_morningQtyController.text) ?? 0;
    final eveningQty = int.tryParse(_eveningQtyController.text) ?? 0;

    if (morningQty + eveningQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one quantity (morning or evening)')),
      );
      return;
    }

    final legacyQty = morningQty + eveningQty > 0 ? morningQty + eveningQty : 1;

    final template = SupplyTemplate(
      id: widget.template?.id,
      shopName: _shopController.text.trim(),
      shopMobile: _shopMobileController.text.trim().isEmpty ? null : _shopMobileController.text.trim(),
      productType: _productType,
      saleType: _saleType,
      quantity: legacyQty,
      morningQuantity: morningQty,
      eveningQuantity: eveningQty,
      ratePerUnit: double.parse(_rateController.text),
      costPerUnit: double.parse(_costController.text),
      deliverySlot: _deliverySlot,
      deliveryTime: _timeAsString(),
      prepLeadDays: _prepLeadDays,
      activeWeekdays: _activeWeekdays,
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.template?.isActive ?? true,
    );

    final provider = context.read<SalesProvider>();
    final ok = widget.template == null
        ? await provider.addSupplyTemplate(template)
        : await provider.updateSupplyTemplate(template);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save template')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return AlertDialog(
      title: Text(widget.template == null ? 'Add Supply Template' : 'Edit Supply Template'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _shopController,
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _shopMobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Shop Mobile',
                    hintText: 'Optional – for tap-to-call',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ProductType>(
                  initialValue: _productType,
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: ProductType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _productType = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<SaleType>(
                  initialValue: _saleType,
                  decoration: const InputDecoration(labelText: 'Sale Type'),
                  items: SaleType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _saleType = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _morningQtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Morning Qty',
                          prefixIcon: Icon(Icons.wb_sunny_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _eveningQtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Evening Qty',
                          prefixIcon: Icon(Icons.nights_stay_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate per Unit'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cost per Unit'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter valid cost';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<DeliverySlot>(
                  initialValue: _deliverySlot,
                  decoration: const InputDecoration(labelText: 'Dispatch Slot'),
                  items: DeliverySlot.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _deliverySlot = v!),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delivery Time (optional)'),
                  subtitle: Text(_deliveryTime?.format(context) ?? 'Not set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _deliveryTime ?? const TimeOfDay(hour: 7, minute: 0),
                      );
                      if (picked != null) setState(() => _deliveryTime = picked);
                    },
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _prepLeadDays,
                  decoration: const InputDecoration(labelText: 'Prep Reminder'),
                  items: const [1, 2]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e day${e == 1 ? '' : 's'} before dispatch'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _prepLeadDays = v!),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Active Weekdays',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weekdayLabels.entries.map((entry) {
                    final selected = _activeWeekdays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _activeWeekdays.add(entry.key);
                          } else if (_activeWeekdays.length > 1) {
                            _activeWeekdays.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date (optional)'),
                  subtitle: Text(_startDate == null ? 'No start limit' : dateFmt.format(_startDate!)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _startDate = null),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date (optional)'),
                  subtitle: Text(_endDate == null ? 'No end limit' : dateFmt.format(_endDate!)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                      if (_endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _endDate = null),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
