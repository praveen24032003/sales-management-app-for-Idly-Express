import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../../domain/business_types.dart';
import '../../../domain/expense_entry.dart';
import '../../../domain/sales_entry.dart';
import '../../app_shell/application/app_session_controller.dart';
import '../../balances/presentation/shop_balances_screen.dart';
import '../../dispatch/presentation/dispatch_screen.dart';
import '../../sales/presentation/sale_editor_sheet.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/theme_controller.dart';
import '../../workspace/application/workspace_data_controller.dart';
import 'insights_screen.dart';

class WorkspaceShellScreen extends StatefulWidget {
  const WorkspaceShellScreen({super.key});

  @override
  State<WorkspaceShellScreen> createState() => _WorkspaceShellScreenState();
}

class _WorkspaceShellScreenState extends State<WorkspaceShellScreen> {
  int _currentIndex = 0;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _ShellDestination(
      label: 'Dispatch',
      icon: Icons.delivery_dining_outlined,
      selectedIcon: Icons.delivery_dining_rounded,
    ),
    _ShellDestination(
      label: 'Sales',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
    ),
    _ShellDestination(
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionController>();
    final workspace = context.watch<WorkspaceDataController>();
    final organization = session.activeOrganization!;

    final pages = [
      _FeatureOverviewPage(
        organizationName: organization.name,
        inviteCode: organization.inviteCode,
        workspace: workspace,
        onTabSwitch: (index) => setState(() => _currentIndex = index),
      ),
      DispatchScreen(workspace: workspace),
      _SalesTab(workspace: workspace),
      _ExpensesTab(workspace: workspace),
    ];

    return Scaffold(
      backgroundColor: context.brand.surfaceTop,
      appBar: AppBar(
        backgroundColor: context.brand.surfaceCard,
        foregroundColor: context.brand.textStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandGlyph(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    organization.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: context.brand.textStrong,
                      fontSize: 16,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    organization.role.label,
                    style: TextStyle(
                      color: context.brand.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.brand.border),
        ),
        actions: [
          IconButton(
            tooltip: 'Insights',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Insights'),
                    backgroundColor: ctx.brand.surfaceCard,
                    foregroundColor: ctx.brand.textStrong,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                  ),
                  body: InsightsScreen(workspace: workspace),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Settings'),
                    backgroundColor: ctx.brand.surfaceCard,
                    foregroundColor: ctx.brand.textStrong,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                  ),
                  body: SettingsScreen(
                    workspace: workspace,
                    organizationName: organization.name,
                    inviteCode: organization.inviteCode,
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              switch (value) {
                case 'theme-light':
                  await Provider.of<ThemeController>(context, listen: false).setMode(ThemeMode.light);
                case 'theme-dark':
                  await Provider.of<ThemeController>(context, listen: false).setMode(ThemeMode.dark);
                case 'theme-system':
                  await Provider.of<ThemeController>(context, listen: false).setMode(ThemeMode.system);
                case 'switch-org':
                  await session.clearActiveOrganization();
                case 'sign-out':
                  await session.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'theme-light',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.light_mode_outlined, size: 20),
                  title: Text('Light mode'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'theme-dark',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.dark_mode_outlined, size: 20),
                  title: Text('Dark mode'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'theme-system',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.brightness_auto_outlined, size: 20),
                  title: Text('Use system theme'),
                  dense: true,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'switch-org',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.swap_horiz_rounded, size: 20),
                  title: Text('Switch organization'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'sign-out',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded, size: 20),
                  title: Text('Sign out'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: TweenAnimationBuilder<double>(
        key: ValueKey(_currentIndex),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (ctx, t, child) {
          final scale = t.clamp(0.0, 1.5);
          final dy = (1 - t) * 14;
          return Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: 60,
          height: 60,
          child: FloatingActionButton(
            backgroundColor: BrandTokens.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            highlightElevation: 10,
            shape: const CircleBorder(),
            onPressed: () {
              if (_currentIndex == 3) {
                _openAddExpense(context, workspace);
              } else {
                _openAddSale(context, workspace);
              }
            },
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _ShellBottomBar(
        selectedIndex: _currentIndex,
        reserveCenterSlot: true,
        onSelected: (value) => setState(() => _currentIndex = value),
        destinations: _destinations,
      ),
    );
  }

  Future<void> _openAddSale(BuildContext context, WorkspaceDataController workspace) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaleEditorSheet(workspace: workspace),
    );
  }

  Future<void> _openAddExpense(BuildContext context, WorkspaceDataController workspace) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(
        key: const ValueKey('expense-form-new'),
        workspace: workspace,
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.selectedIndex,
    required this.reserveCenterSlot,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final bool reserveCenterSlot;
  final ValueChanged<int> onSelected;
  final List<_ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return BottomAppBar(
      padding: EdgeInsets.zero,
      color: brand.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 14,
      shape: reserveCenterSlot ? const CircularNotchedRectangle() : null,
      notchMargin: reserveCenterSlot ? 7 : 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: reserveCenterSlot
                ? [
                    Expanded(child: _ShellNavButton(destination: destinations[0], selected: selectedIndex == 0, onTap: () => onSelected(0))),
                    Expanded(child: _ShellNavButton(destination: destinations[1], selected: selectedIndex == 1, onTap: () => onSelected(1))),
                    const SizedBox(width: 76),
                    Expanded(child: _ShellNavButton(destination: destinations[2], selected: selectedIndex == 2, onTap: () => onSelected(2))),
                    Expanded(child: _ShellNavButton(destination: destinations[3], selected: selectedIndex == 3, onTap: () => onSelected(3))),
                  ]
                : List<Widget>.generate(
                    destinations.length,
                    (index) => Expanded(
                      child: _ShellNavButton(
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        onTap: () => onSelected(index),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavButton extends StatelessWidget {
  const _ShellNavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final activeColor = BrandTokens.primary;
    final inactiveColor = brand.textMuted;
    final color = selected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureOverviewPage extends StatefulWidget {
  const _FeatureOverviewPage({
    required this.organizationName,
    required this.inviteCode,
    required this.workspace,
    required this.onTabSwitch,
  });

  final String organizationName;
  final String inviteCode;
  final WorkspaceDataController workspace;
  final void Function(int tab) onTabSwitch;

  @override
  State<_FeatureOverviewPage> createState() => _FeatureOverviewPageState();
}

class _FeatureOverviewPageState extends State<_FeatureOverviewPage> {
  bool _showProfit = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brand = context.brand;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final now = DateTime.now();
    final greeting = _greetingFor(DateTime.now());
    final today = DateFormat('EEEE, dd MMM').format(DateTime.now());
    final workspace = widget.workspace;
    final todaySales = workspace.sales
        .where((sale) => sale.date.year == now.year && sale.date.month == now.month && sale.date.day == now.day)
        .toList();
    final todayCollectionsTotal = todaySales.fold<double>(0, (sum, sale) => sum + (sale.paidAmount ?? 0));
    final todayBookedMorning = workspace.bookedQuantityForDate(now, slot: DeliverySlot.morning);
    final todayBookedEvening = workspace.bookedQuantityForDate(now, slot: DeliverySlot.evening);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: brand.surfaceCardAlpha,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: brand.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: brand.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.storefront_rounded, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting,',
                            style: theme.textTheme.bodyMedium?.copyWith(color: brand.textMuted, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.organizationName,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            today,
                            style: theme.textTheme.bodySmall?.copyWith(color: brand.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: workspace.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      label: workspace.isOnline ? 'Online' : 'Offline',
                      tone: workspace.isOnline ? _ChipTone.success : _ChipTone.muted,
                    ),
                    _StatusChip(
                      icon: Icons.sync_rounded,
                      label: 'Queued ${workspace.pendingQueueCount}',
                      tone: workspace.pendingQueueCount > 0 ? _ChipTone.warning : _ChipTone.muted,
                    ),
                  ],
                ),
                if (workspace.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            workspace.errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (workspace.isLoading)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: brand.surfaceCardAlpha,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: brand.border),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisSpacing = 14.0;
                const mainAxisSpacing = 14.0;
                const targetCardHeight = 152.0;
                final cardWidth = (constraints.maxWidth - crossAxisSpacing) / 2;
                return Container(
                  key: const ValueKey('overviewMetricsGrid'),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: cardWidth / targetCardHeight,
                    children: [
                      _MetricCard(
                        label: 'Today sales',
                        value: currency.format(workspace.todaySalesTotal),
                        icon: Icons.trending_up_rounded,
                        accent: BrandTokens.accentSales,
                        onTap: () => widget.onTabSwitch(2),
                      ),
                      _MetricCard(
                        label: 'Today expenses',
                        value: currency.format(workspace.todayExpenseTotal),
                        icon: Icons.receipt_long_outlined,
                        accent: BrandTokens.accentExpense,
                        onTap: () => widget.onTabSwitch(3),
                      ),
                      _MetricCard(
                        label: 'Outstanding',
                        value: currency.format(workspace.outstandingAmount),
                        icon: Icons.hourglass_bottom_rounded,
                        accent: BrandTokens.accentOutstanding,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ShopBalancesScreen(workspace: workspace)),
                        ),
                      ),
                      _MetricCard(
                        label: 'Today collection',
                        value: currency.format(todayCollectionsTotal),
                        icon: Icons.payments_rounded,
                        accent: BrandTokens.primary,
                        onTap: () => widget.onTabSwitch(2),
                      ),
                      _MetricCard(
                        label: 'Booked morning',
                        value: '$todayBookedMorning',
                        icon: Icons.wb_sunny_outlined,
                        accent: BrandTokens.primary,
                        onTap: () => widget.onTabSwitch(1),
                      ),
                      _MetricCard(
                        label: 'Booked evening',
                        value: '$todayBookedEvening',
                        icon: Icons.brightness_3_outlined,
                        accent: BrandTokens.primaryDeep,
                        onTap: () => widget.onTabSwitch(1),
                      ),
                      _MetricCard(
                        label: 'Profit',
                        value: _showProfit ? currency.format(workspace.totalProfit) : 'Tap to reveal',
                        icon: Icons.savings_outlined,
                        accent: BrandTokens.accentProfit,
                        onTap: () => setState(() => _showProfit = !_showProfit),
                        revealOnTap: true,
                        revealed: _showProfit,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

enum _SalesFilter { today, week, month, all }

enum _SalesPaymentFilter { all, paid, pending }

enum _SalesSortMode { newest, alphabetical }

class _SalesTab extends StatefulWidget {
  const _SalesTab({required this.workspace});

  final WorkspaceDataController workspace;

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  _SalesFilter _filter = _SalesFilter.today;
  _SalesPaymentFilter _paymentFilter = _SalesPaymentFilter.all;
  _SalesSortMode _sortMode = _SalesSortMode.newest;

  List<SalesEntry> _filteredSales() {
    final now = DateTime.now();
    final all = [...widget.workspace.sales];
    final List<SalesEntry> filtered;
    switch (_filter) {
      case _SalesFilter.today:
        filtered = all
            .where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day)
            .toList();
      case _SalesFilter.week:
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        filtered = all.where((s) => !s.date.isBefore(weekStart)).toList();
      case _SalesFilter.month:
        filtered = all.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
      case _SalesFilter.all:
        filtered = all;
    }

    final paymentFiltered = filtered.where((sale) {
      switch (_paymentFilter) {
        case _SalesPaymentFilter.all:
          return true;
        case _SalesPaymentFilter.paid:
          return sale.pendingAmount <= 0.01;
        case _SalesPaymentFilter.pending:
          return sale.pendingAmount > 0.01;
      }
    }).toList();

    switch (_sortMode) {
      case _SalesSortMode.newest:
        paymentFiltered.sort((a, b) => b.date.compareTo(a.date));
      case _SalesSortMode.alphabetical:
        paymentFiltered.sort((a, b) {
          final nameCompare = a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase());
          if (nameCompare != 0) {
            return nameCompare;
          }
          return b.date.compareTo(a.date);
        });
    }

    return paymentFiltered;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final sales = _filteredSales();
    final filterTotal = sales.fold<double>(0, (s, sale) => s + sale.totalSalesAmount);
    final isEmpty = widget.workspace.sales.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: isEmpty
            ? BrandEmptyState(
                icon: Icons.point_of_sale_outlined,
                title: 'No sales yet',
                message: 'Tap "Add sale" to record your first order for this organization.',
                action: FilledButton.icon(
                  onPressed: () => _openSaleEditor(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add sale'),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: BrandCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BrandSectionHeader(
                              title: 'Sales',
                              subtitle: '${sales.length} entries • ${currency.format(filterTotal)}',
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Period',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: context.brand.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(label: 'Today', selected: _filter == _SalesFilter.today, onTap: () => setState(() => _filter = _SalesFilter.today)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'This week', selected: _filter == _SalesFilter.week, onTap: () => setState(() => _filter = _SalesFilter.week)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'This month', selected: _filter == _SalesFilter.month, onTap: () => setState(() => _filter = _SalesFilter.month)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'All time', selected: _filter == _SalesFilter.all, onTap: () => setState(() => _filter = _SalesFilter.all)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Status and sorting',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: context.brand.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(label: 'All status', selected: _paymentFilter == _SalesPaymentFilter.all, onTap: () => setState(() => _paymentFilter = _SalesPaymentFilter.all)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'Paid', selected: _paymentFilter == _SalesPaymentFilter.paid, onTap: () => setState(() => _paymentFilter = _SalesPaymentFilter.paid)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'Pending', selected: _paymentFilter == _SalesPaymentFilter.pending, onTap: () => setState(() => _paymentFilter = _SalesPaymentFilter.pending)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'Newest', selected: _sortMode == _SalesSortMode.newest, onTap: () => setState(() => _sortMode = _SalesSortMode.newest)),
                                  const SizedBox(width: 8),
                                  _FilterChip(label: 'A-Z', selected: _sortMode == _SalesSortMode.alphabetical, onTap: () => setState(() => _sortMode = _SalesSortMode.alphabetical)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (sales.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No sales for this period',
                          style: TextStyle(color: context.brand.textMuted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      sliver: SliverList.separated(
                        itemCount: sales.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return _SaleRow(
                            sale: sale,
                            currency: currency,
                            onEdit: () => _openSaleEditor(context, sale: sale),
                            onDelete: () => _deleteSale(context, sale),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _openSaleEditor(BuildContext context, {SalesEntry? sale}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaleEditorSheet(
        workspace: widget.workspace,
        existingSale: sale,
      ),
    );
  }

  Future<void> _deleteSale(BuildContext context, SalesEntry sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sale?'),
        content: Text('Remove the sale entry for ${sale.shopName} on ${DateFormat('dd MMM yyyy').format(sale.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.workspace.deleteSale(sale.id, deletedSale: sale);
    if (!context.mounted) return;

    if (widget.workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale deleted')));
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BrandTokens.primary : brand.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? BrandTokens.primary : brand.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : brand.textLabel,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.sale,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final SalesEntry sale;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingTone = sale.pendingAmount > 0 ? _ChipTone.warning : _ChipTone.success;
    return BrandCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
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
            child: const Icon(Icons.storefront_rounded, color: BrandTokens.primary),
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
                        sale.shopName,
                        style: TextStyle(fontWeight: FontWeight.w800, color: context.brand.textStrong, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currency.format(sale.totalSalesAmount),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: context.brand.textStrong),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('dd MMM').format(sale.date)} • ${sale.productType.displayName} • ${sale.deliverySlot.displayName}',
                  style: TextStyle(color: context.brand.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusChip(
                      icon: sale.pendingAmount > 0 ? Icons.hourglass_bottom_rounded : Icons.check_circle_rounded,
                      label: sale.pendingAmount > 0 ? 'Pending ${currency.format(sale.pendingAmount)}' : 'Paid',
                      tone: pendingTone,
                    ),
                    if (sale.deliveryTime?.isNotEmpty == true)
                      _StatusChip(
                        icon: Icons.schedule_rounded,
                        label: sale.deliveryTime!,
                        tone: _ChipTone.muted,
                      ),
                    if (sale.customerMobile?.isNotEmpty == true)
                      _StatusChip(
                        icon: Icons.phone_rounded,
                        label: sale.customerMobile!,
                        tone: _ChipTone.muted,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_SaleAction>(
            tooltip: 'Sale options',
            icon: Icon(Icons.more_vert_rounded, color: context.brand.textMuted),
            onSelected: (action) {
              switch (action) {
                case _SaleAction.edit:
                  onEdit();
                case _SaleAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SaleAction.edit, child: Text('Edit sale')),
              PopupMenuItem(value: _SaleAction.delete, child: Text('Delete sale')),
            ],
          ),
        ],
      ),
    );
  }
}

enum _SaleAction { edit, delete }

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.workspace});

  final WorkspaceDataController workspace;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final total = workspace.todayExpenseTotal;
    final count = workspace.expenses.length;
    final isEmpty = workspace.expenses.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: isEmpty
            ? BrandEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No expenses yet',
                message: 'Record fuel, food, and maintenance to see today\'s spend at a glance.',
                action: FilledButton.icon(
                  onPressed: () => _openExpenseForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add expense'),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: BrandSectionHeader(
                        title: 'Expenses',
                        subtitle: '$count entries • ${currency.format(total)} today',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    sliver: SliverList.separated(
                      itemCount: workspace.expenses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final expense = workspace.expenses[index];
                        return BrandCard(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          onTap: () => _openExpenseForm(context, expense: expense),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: BrandTokens.accentExpense.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_expenseIcon(expense.category), color: BrandTokens.accentExpense),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.category.displayName,
                                      style: TextStyle(fontWeight: FontWeight.w800, color: context.brand.textStrong, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(expense.date),
                                      style: TextStyle(color: context.brand.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        expense.notes!,
                                        style: TextStyle(color: context.brand.textBody, fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currency.format(expense.amount),
                                style: TextStyle(fontWeight: FontWeight.w900, color: context.brand.textStrong, fontSize: 16),
                              ),
                              PopupMenuButton<_ExpenseAction>(
                                tooltip: 'Expense options',
                                icon: Icon(Icons.more_vert_rounded, color: context.brand.textMuted),
                                onSelected: (action) {
                                  switch (action) {
                                    case _ExpenseAction.edit:
                                      _openExpenseForm(context, expense: expense);
                                    case _ExpenseAction.delete:
                                      _deleteExpense(context, expense);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: _ExpenseAction.edit, child: Text('Edit expense')),
                                  PopupMenuItem(value: _ExpenseAction.delete, child: Text('Delete expense')),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _expenseIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.petrol:
        return Icons.local_gas_station_outlined;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.other:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _openExpenseForm(BuildContext context, {ExpenseEntry? expense}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(
        key: ValueKey('expense-form-${expense?.id ?? 'new'}'),
        workspace: workspace,
        expense: expense,
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context, ExpenseEntry expense) async {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          'Remove the ${expense.category.displayName.toLowerCase()} expense of ${currency.format(expense.amount)} on ${DateFormat('dd MMM yyyy').format(expense.date)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await workspace.deleteExpense(expense.id);
    if (!context.mounted) {
      return;
    }

    if (workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
    }
  }
}

enum _ExpenseAction { edit, delete }

enum _ChipTone { brand, success, warning, muted }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final palette = switch (tone) {
      _ChipTone.brand => (bg: brand.primarySoft, fg: brand.primaryDeep, border: brand.border),
      _ChipTone.success => (bg: brand.successBg, fg: brand.successFg, border: brand.successBorder),
      _ChipTone.warning => (bg: brand.warningBg, fg: brand.warningFg, border: brand.warningBorder),
      _ChipTone.muted => (bg: brand.surfaceSoft, fg: brand.textLabel, border: brand.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _OverviewHighlightCard extends StatelessWidget {
  const _OverviewHighlightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Container(
      width: 176,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.16), brand.surfaceCardAlpha],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.15,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: brand.textStrong,
              height: 1.05,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: brand.textMuted, height: 1.28, fontSize: 11),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.18)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
    this.revealOnTap = false,
    this.revealed = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool revealOnTap;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final cardKey = ValueKey('metricCard_${label.toLowerCase().replaceAll(' ', '_')}');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          key: cardKey,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brand.surfaceCardAlpha,
                accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: brand.border),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.18)
                    : accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 17, color: accent),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      revealOnTap
                          ? (revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined)
                          : Icons.arrow_outward_rounded,
                      size: 18,
                      color: brand.textMuted,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: brand.textMuted,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  revealOnTap && !revealed ? 'Tap to reveal' : value,
                  key: ValueKey('${label}_${revealOnTap && !revealed ? 'hidden' : value}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: brand.textStrong,
                    height: 1.04,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.18)],
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

class _SyncRow extends StatelessWidget {
  const _SyncRow({required this.label, required this.count, required this.icon});

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: brand.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: brand.textBody, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: brand.primarySoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: brand.border),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: brand.primaryDeep, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet({super.key, required this.workspace, this.expense});

  final WorkspaceDataController workspace;
  final ExpenseEntry? expense;

  bool get isEditing => expense != null;

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late ExpenseCategory _category;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _hydrateFromExpense();
  }

  @override
  void didUpdateWidget(covariant _ExpenseFormSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expense?.id != widget.expense?.id) {
      _hydrateFromExpense();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _hydrateFromExpense() {
    final expense = widget.expense;
    _category = expense?.category ?? ExpenseCategory.petrol;
    _selectedDate = expense?.date ?? DateTime.now();
    _amountController.text = expense != null ? _formatAmount(expense.amount) : '';
    _notesController.text = expense?.notes ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final expense = ExpenseEntry(
      id: widget.expense?.id ?? '',
      organizationId: widget.expense?.organizationId ?? '',
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      category: _category,
      amount: double.parse(_amountController.text),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await widget.workspace.saveExpense(expense);
    if (mounted && widget.workspace.errorMessage == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Expense updated' : 'Expense saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        color: BrandTokens.accentExpense.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: BrandTokens.accentExpense),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Edit expense' : 'Add expense',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: context.brand.textStrong),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expense date'),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 12),
                        Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _EnumDropdown<ExpenseCategory>(
                  label: 'Category',
                  value: _category,
                  values: ExpenseCategory.values,
                  itemLabel: (value) => value.displayName,
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an amount.';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter an amount greater than zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g., HP petrol pump receipt',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(widget.isEditing ? 'Update expense' : 'Save expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
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
      items: values
          .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
          .toList(),
      onChanged: (nextValue) {
        if (nextValue != null) {
          onChanged(nextValue);
        }
      },
    );
  }
}
