import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../../domain/business_types.dart';
import '../../../domain/supply_template.dart';
import '../../workspace/application/workspace_data_controller.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    super.key,
    required this.workspace,
    this.initialTemplateId,
  });

  final WorkspaceDataController workspace;
  final String? initialTemplateId;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  bool _openedInitialTemplate = false;

  Future<void> _openForm(BuildContext context, {SupplyTemplate? template}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateFormSheet(workspace: widget.workspace, template: template),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openedInitialTemplate) {
      return;
    }

    final templateId = widget.initialTemplateId;
    if (templateId == null) {
      return;
    }

    final matches = widget.workspace.templates.where((template) => template.id == templateId);
    _openedInitialTemplate = true;
    if (matches.isEmpty) {
      return;
    }

    final template = matches.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openForm(context, template: template);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.workspace,
      builder: (context, _) {
        final templates = widget.workspace.templates;
        final activeCount = templates.where((t) => t.isActive).length;
        final isEmpty = templates.isEmpty;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
            child: isEmpty
                ? BrandEmptyState(
                    icon: Icons.repeat_outlined,
                    title: 'No templates yet',
                    message: 'Add recurring morning or evening supply templates to populate dispatch automatically.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add template'),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        sliver: SliverToBoxAdapter(
                          child: BrandSectionHeader(
                            title: 'Supply templates',
                            subtitle: '$activeCount active of ${templates.length} total',
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                        sliver: SliverList.separated(
                          itemCount: templates.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return _TemplateRow(
                              template: template,
                              onEdit: () => _openForm(context, template: template),
                              onToggle: () => widget.workspace.toggleTemplateActive(template),
                              onDelete: () => widget.workspace.deleteTemplate(template.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButton: isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add template'),
                ),
        );
      },
    );
  }
}

String _weekdaySummary(Set<int> days) {
  const labels = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };
  final sorted = days.toList()..sort();
  return sorted.map((day) => labels[day] ?? day.toString()).join(', ');
}

String _slotSummary(SupplyTemplate template) {
  if (template.morningQuantity > 0 && template.eveningQuantity > 0) {
    return 'Morning ${template.morningQuantity} • Evening ${template.eveningQuantity}';
  }
  return '${template.deliverySlot.displayName} ${template.quantity}';
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.template,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SupplyTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: context.brand.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.repeat_rounded, color: BrandTokens.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                    if (!template.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.brand.warningBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Disabled',
                          style: TextStyle(color: context.brand.warningFg, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${template.productType.displayName} • ${_slotSummary(template)}',
                  style: TextStyle(color: context.brand.textBody, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Days: ${_weekdaySummary(template.activeWeekdays)}',
                  style: TextStyle(color: context.brand.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Template options',
            icon: Icon(Icons.more_vert_rounded, color: context.brand.textMuted),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggle();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'toggle', child: Text(template.isActive ? 'Disable' : 'Enable')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateFormSheet extends StatefulWidget {
  const _TemplateFormSheet({
    required this.workspace,
    this.template,
  });

  final WorkspaceDataController workspace;
  final SupplyTemplate? template;

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopController;
  late final TextEditingController _mobileController;
  late final TextEditingController _morningQtyController;
  late final TextEditingController _eveningQtyController;
  late final TextEditingController _rateController;
  late final TextEditingController _costController;

  late ProductType _productType;
  late SaleType _saleType;
  late DeliverySlot _deliverySlot;
  late Set<int> _activeWeekdays;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _shopController = TextEditingController(text: template?.shopName ?? '');
    _mobileController = TextEditingController(text: template?.shopMobile ?? '');
    _morningQtyController = TextEditingController(text: '${template?.morningQuantity ?? 0}');
    _eveningQtyController = TextEditingController(text: '${template?.eveningQuantity ?? 0}');
    _rateController = TextEditingController(text: '${template?.ratePerUnit ?? 3.5}');
    _costController = TextEditingController(text: '${template?.costPerUnit ?? 2.5}');
    _productType = template?.productType ?? ProductType.idly;
    _saleType = template?.saleType ?? SaleType.wholesale;
    _deliverySlot = template?.deliverySlot ?? DeliverySlot.morning;
    _activeWeekdays = {...(template?.activeWeekdays ?? {1, 2, 3, 4, 5, 6, 7})};
    _startDate = template?.startDate;
    _endDate = template?.endDate;
  }

  @override
  void dispose() {
    _shopController.dispose();
    _mobileController.dispose();
    _morningQtyController.dispose();
    _eveningQtyController.dispose();
    _rateController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final morningQty = int.parse(_morningQtyController.text);
    final eveningQty = int.parse(_eveningQtyController.text);
    final quantity = morningQty + eveningQty == 0 ? 1 : morningQty + eveningQty;

    final template = SupplyTemplate(
      id: widget.template?.id ?? '',
      organizationId: widget.template?.organizationId ?? '',
      shopName: _shopController.text.trim(),
      productType: _productType,
      saleType: _saleType,
      quantity: quantity,
      ratePerUnit: double.parse(_rateController.text),
      costPerUnit: double.parse(_costController.text),
      deliverySlot: _deliverySlot,
      activeWeekdays: _activeWeekdays,
      prepLeadDays: 1,
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.template?.isActive ?? true,
      morningQuantity: morningQty,
      eveningQuantity: eveningQty,
      shopMobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
    );

    await widget.workspace.saveTemplate(template);
    if (mounted && widget.workspace.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');

    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.brand.surfaceSheet,
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
                      color: context.brand.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: context.brand.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.repeat_rounded, color: BrandTokens.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.template == null ? 'Add template' : 'Edit template',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: context.brand.textStrong),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              TextFormField(
                controller: _shopController,
                decoration: const InputDecoration(labelText: 'Shop name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter shop name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Shop mobile'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _TemplateEnumDropdown<ProductType>(
                label: 'Product',
                value: _productType,
                values: ProductType.values,
                itemLabel: (value) => value.displayName,
                onChanged: (value) => setState(() => _productType = value),
              ),
              const SizedBox(height: 12),
              _TemplateEnumDropdown<SaleType>(
                label: 'Sale type',
                value: _saleType,
                values: SaleType.values,
                itemLabel: (value) => value.displayName,
                onChanged: (value) => setState(() => _saleType = value),
              ),
              const SizedBox(height: 12),
              _TemplateEnumDropdown<DeliverySlot>(
                label: 'Default slot',
                value: _deliverySlot,
                values: DeliverySlot.values,
                itemLabel: (value) => value.displayName,
                onChanged: (value) => setState(() => _deliverySlot = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _morningQtyController,
                      decoration: const InputDecoration(labelText: 'Morning qty'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || int.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _eveningQtyController,
                      decoration: const InputDecoration(labelText: 'Evening qty'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || int.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(labelText: 'Rate'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'Cost'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final selected = _activeWeekdays.contains(weekday);
                  return FilterChip(
                    label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _activeWeekdays.add(weekday);
                        } else {
                          _activeWeekdays.remove(weekday);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_startDate == null ? 'Start date' : 'Start: ${formatter.format(_startDate!)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_endDate == null ? 'End date' : 'End: ${formatter.format(_endDate!)}'),
                trailing: const Icon(Icons.event_busy),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('Save template')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateEnumDropdown<T> extends StatelessWidget {
  const _TemplateEnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values.map((item) => DropdownMenuItem(value: item, child: Text(itemLabel(item)))).toList(),
      onChanged: (nextValue) {
        if (nextValue != null) {
          onChanged(nextValue);
        }
      },
    );
  }
}
