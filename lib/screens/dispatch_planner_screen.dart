import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/supply_template_model.dart';
import '../models/sales_entry_model.dart';
import '../models/dispatch_leave_model.dart';
import '../providers/sales_provider.dart';
import '../services/database_service.dart';
import '../widgets/payment_bottom_sheet.dart';

/// 7-day dispatch planning screen.
/// Shows active templates for the next 7 days with swipe gestures:
///   Right swipe → dispatch + payment prompt
///   Left swipe → mark leave
class DispatchPlannerScreen extends StatefulWidget {
  const DispatchPlannerScreen({super.key});

  @override
  State<DispatchPlannerScreen> createState() => _DispatchPlannerScreenState();
}

class _DispatchPlannerScreenState extends State<DispatchPlannerScreen> {
  static const _days = 7;
  List<SupplyTemplate> _templates = [];
  // key: 'templateId_YYYY-MM-DD_slotIndex'
  Set<String> _dispatchedKeys = {};
  Set<String> _leaveKeys = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final templates = await DatabaseService.instance.getAllSupplyTemplates();
    final now = DateTime.now();

    // Gather dispatched and leave keys for next 7 days
    final dispatched = <String>{};
    final leaves = <String>{};

    for (final t in templates) {
      if (!t.isActive) continue;
      for (int d = 0; d < _days; d++) {
        final date = DateTime(now.year, now.month, now.day + d);
        if (!t.isActiveOnDate(date)) continue;
        final dateStr = date.toIso8601String().split('T').first;

        final slots = _getSlots(t);
        for (final slot in slots) {
          final hasEntry = await DatabaseService.instance.hasDispatchEntry(t.id!, date, slot);
          if (hasEntry) dispatched.add('${t.id}_${dateStr}_${slot.index}');
          final hasLeave = await DatabaseService.instance.hasDispatchLeave(t.id!, date, slot);
          if (hasLeave) leaves.add('${t.id}_${dateStr}_${slot.index}');
        }
      }
    }

    if (mounted) {
      setState(() {
        _templates = templates.where((t) => t.isActive).toList();
        _dispatchedKeys = dispatched;
        _leaveKeys = leaves;
        _loading = false;
      });
    }
  }

  List<DeliverySlot> _getSlots(SupplyTemplate t) {
    final slots = <DeliverySlot>[];
    if (t.morningQuantity > 0) slots.add(DeliverySlot.morning);
    if (t.eveningQuantity > 0) slots.add(DeliverySlot.evening);
    if (slots.isEmpty) slots.add(t.deliverySlot);
    return slots;
  }

  int _getQty(SupplyTemplate t, DeliverySlot slot) {
    if (slot == DeliverySlot.morning && t.morningQuantity > 0) return t.morningQuantity;
    if (slot == DeliverySlot.evening && t.eveningQuantity > 0) return t.eveningQuantity;
    return t.quantity;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    final dateStr = '${date.day}/${date.month}';

    if (diff == 0) return 'Today ($dateStr)';
    if (diff == 1) return 'Tomorrow ($dateStr)';

    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday]} ($dateStr)';
  }

  Future<void> _dispatch(SupplyTemplate t, DateTime date, DeliverySlot slot) async {
    final qty = _getQty(t, slot);
    final result = await DispatchPaymentResult.show(
      context,
      shopName: t.shopName,
      quantity: qty,
      ratePerUnit: t.ratePerUnit,
      slot: slot,
    );
    if (result == null) return;

    final entry = SalesEntry(
      date: date,
      shopName: t.shopName,
      orderType: OrderType.everydaySupply,
      deliverySlot: slot,
      deliveryTime: t.deliveryTime,
      prepLeadDays: t.prepLeadDays,
      productType: t.productType,
      saleType: t.saleType,
      ratePerUnit: t.ratePerUnit,
      quantity: qty,
      costPerUnit: t.costPerUnit,
      paymentStatus: result.status,
      paidAmount: result.paidAmount,
      notes: 'Dispatched via planner',
    );

    if (mounted) {
      await Provider.of<SalesProvider>(context, listen: false).addEntry(entry);
    }

    final dateStr = date.toIso8601String().split('T').first;
    setState(() => _dispatchedKeys.add('${t.id}_${dateStr}_${slot.index}'));
  }

  Future<void> _markLeave(SupplyTemplate t, DateTime date, DeliverySlot slot) async {
    final dateStr = date.toIso8601String().split('T').first;
    final key = '${t.id}_${dateStr}_${slot.index}';

    if (_leaveKeys.contains(key)) {
      // Toggle off
      await DatabaseService.instance.deleteDispatchLeave(t.id!, date, slot);
      setState(() => _leaveKeys.remove(key));
    } else {
      final leave = DispatchLeave(
        templateId: t.id!,
        leaveDate: date,
        deliverySlot: slot,
        createdAt: DateTime.now(),
      );
      await DatabaseService.instance.insertDispatchLeave(leave);
      setState(() => _leaveKeys.add(key));
    }
  }

  Future<bool> _confirmLeaveAction({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
    required bool undo,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(undo ? 'Undo leave?' : 'Mark leave?'),
        content: Text(
          undo
              ? 'Remove leave for ${template.shopName} on ${_dayLabel(date)} ${slot.displayName.toLowerCase()}?'
              : 'Mark ${template.shopName} as leave on ${_dayLabel(date)} ${slot.displayName.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(undo ? 'Undo' : 'Confirm'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _showLeaveSnackBar({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${template.shopName} marked leave for ${slot.displayName.toLowerCase()}'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _markLeave(template, date, slot);
            },
          ),
        ),
      );
  }

  Future<void> _handleLeaveSwipe(SupplyTemplate template, DateTime date, DeliverySlot slot, bool isLeave) async {
    final confirmed = await _confirmLeaveAction(
      template: template,
      date: date,
      slot: slot,
      undo: isLeave,
    );
    if (!confirmed) return;

    await _markLeave(template, date, slot);
    if (!isLeave && mounted) {
      _showLeaveSnackBar(template: template, date: date, slot: slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffold = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        title: const Text('Dispatch Planner'),
        backgroundColor: scaffold,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDays(isDark),
    );
  }

  Widget _buildDays(bool isDark) {
    final now = DateTime.now();
    final days = List.generate(_days, (i) => DateTime(now.year, now.month, now.day + i));

    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: days.length,
      itemBuilder: (context, di) {
        final date = days[di];
        final dayTemplates = _templates.where((t) => t.isActiveOnDate(date)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _dayLabel(date),
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dayTemplates.length} shops',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (dayTemplates.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text('No dispatch for this day', style: TextStyle(color: textSecondary, fontSize: 13)),
              )
            else
              ...dayTemplates.expand((t) {
                final slots = _getSlots(t);
                return slots.map((slot) => _buildTile(t, date, slot, isDark, textPrimary, textSecondary));
              }),
          ],
        );
      },
    );
  }

  Widget _buildTile(
    SupplyTemplate t,
    DateTime date,
    DeliverySlot slot,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final dateStr = date.toIso8601String().split('T').first;
    final key = '${t.id}_${dateStr}_${slot.index}';
    final isDispatched = _dispatchedKeys.contains(key);
    final isLeave = _leaveKeys.contains(key);
    final qty = _getQty(t, slot);
    final surface = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Dismissible(
      key: ValueKey(key),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.25,
        DismissDirection.endToStart: 0.25,
      },
      confirmDismiss: (dir) async {
        if (isDispatched) {
          HapticFeedback.heavyImpact();
          return false;
        }
        HapticFeedback.mediumImpact();
        if (dir == DismissDirection.startToEnd) {
          await _dispatch(t, date, slot);
        } else {
          await _handleLeaveSwipe(t, date, slot, isLeave);
        }
        return false; // Keep in list — state updated via setState
      },
      background: _swipeBackground(
        color: const Color(0xFF059669),
        icon: Icons.local_shipping_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        color: const Color(0xFFE53E3E),
        icon: Icons.do_not_disturb_alt_rounded,
        alignment: Alignment.centerRight,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isLeave
              ? const Color(0xFFE53E3E).withValues(alpha: isDark ? 0.15 : 0.08)
              : isDispatched
                ? const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.08)
                  : surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isLeave
              ? const Color(0xFFE53E3E).withValues(alpha: 0.3)
                : isDispatched
                ? const Color(0xFF059669).withValues(alpha: 0.3)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: isLeave
              ? const Color(0xFFE53E3E).withValues(alpha: 0.15)
                : isDispatched
                ? const Color(0xFF059669).withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(
              isLeave
                  ? Icons.do_not_disturb_alt_rounded
                  : isDispatched
                      ? Icons.check_circle_rounded
                      : (slot == DeliverySlot.morning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
              color: isLeave
                  ? const Color(0xFFE53E3E)
                  : isDispatched
                      ? const Color(0xFF059669)
                      : Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          title: Text(
            t.shopName,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: isLeave ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${slot.displayName} · $qty pcs · $currencySymbol${(qty * t.ratePerUnit).toStringAsFixed(0)}',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (t.shopMobile != null && t.shopMobile!.isNotEmpty)
                GestureDetector(
                  onTap: () => _call(t.shopMobile!),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary, size: 16),
                  ),
                ),
              if (isLeave || isDispatched)
                const SizedBox(width: 6),
              if (isLeave)
                GestureDetector(
                  onTap: () => _handleLeaveSwipe(t, date, slot, true),
                  child: Text('Undo leave', style: TextStyle(color: const Color(0xFFE53E3E), fontSize: 11, fontWeight: FontWeight.w600)),
                )
              else if (isDispatched)
                Text('Done', style: TextStyle(color: const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({required Color color, required IconData icon, required Alignment alignment}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
