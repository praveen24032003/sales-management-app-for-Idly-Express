import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../balances/presentation/shop_balances_screen.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../templates/presentation/templates_screen.dart';
import '../../workspace/application/workspace_data_controller.dart';
import '../theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.workspace,
    required this.organizationName,
    required this.inviteCode,
  });

  final WorkspaceDataController workspace;
  final String organizationName;
  final String inviteCode;

  static const _themeOptions = <ButtonSegment<ThemeMode>>[
    ButtonSegment(value: ThemeMode.system, label: Text('System')),
    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return AnimatedBuilder(
      animation: workspace,
      builder: (context, _) {
        final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
        final brand = context.brand;
        return DecoratedBox(
          decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const BrandSectionHeader(
                title: 'Settings',
                subtitle: 'Appearance, workspace info, collections, templates, and contacts for this organization.',
              ),
              const SizedBox(height: 16),
              BrandCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(icon: Icons.palette_outlined, label: 'Appearance'),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: _themeOptions,
                      selected: {themeController.mode},
                      onSelectionChanged: (selection) {
                        themeController.setMode(selection.first);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Use System, Light, or Dark. The selection is saved on this device.',
                      style: TextStyle(color: brand.textMuted, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BrandCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(icon: Icons.badge_outlined, label: 'Invite'),
                    const SizedBox(height: 12),
                    Text(
                      organizationName,
                      style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      inviteCode,
                      style: TextStyle(fontWeight: FontWeight.w900, color: brand.primaryDeep, fontSize: 18, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share this code only when you want another device or teammate to join this workspace.',
                      style: TextStyle(color: brand.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BrandCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(icon: Icons.cloud_sync_outlined, label: 'Workspace sync'),
                    const SizedBox(height: 12),
                    Text(
                      workspace.isOnline
                          ? 'Records are syncing live across signed-in devices.'
                          : 'Offline mode is active. New writes stay queued and replay automatically when the device reconnects.',
                      style: TextStyle(color: brand.textBody, height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    _SyncInfoRow(label: 'Queued writes', value: '${workspace.pendingQueueCount}'),
                    _SyncInfoRow(label: 'Sales', value: '${workspace.sales.length}'),
                    _SyncInfoRow(label: 'Expenses', value: '${workspace.expenses.length}'),
                    _SyncInfoRow(label: 'Templates', value: '${workspace.templates.length}'),
                    _SyncInfoRow(label: 'Contacts', value: '${workspace.contacts.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BrandCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ShopBalancesScreen(workspace: workspace)),
                ),
                child: _NavRow(
                  icon: Icons.account_balance_wallet_outlined,
                  accent: BrandTokens.accentOutstanding,
                  title: 'Pending Collections',
                  subtitle: 'Outstanding ${currency.format(workspace.outstandingAmount)} across current sales.',
                ),
              ),
              const SizedBox(height: 14),
              BrandCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Supply templates')),
                      body: TemplatesScreen(workspace: workspace),
                    ),
                  ),
                ),
                child: _NavRow(
                  icon: Icons.repeat_rounded,
                  accent: BrandTokens.accentSales,
                  title: 'Supply Templates',
                  subtitle: '${workspace.templates.where((t) => t.isActive).length} active of ${workspace.templates.length} recurring templates.',
                ),
              ),
              const SizedBox(height: 14),
              BrandCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ContactsScreen(workspace: workspace)),
                ),
                child: _NavRow(
                  icon: Icons.people_outline,
                  accent: BrandTokens.primary,
                  title: 'Contacts',
                  subtitle: '${workspace.contacts.length} saved for this organization.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncInfoRow extends StatelessWidget {
  const _SyncInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: brand.textMuted, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(color: brand.textStrong, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Row(
      children: [
        Icon(icon, size: 18, color: BrandTokens.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: brand.textStrong,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: brand.textMuted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: brand.textMuted),
        ],
      ),
    );
  }
}
