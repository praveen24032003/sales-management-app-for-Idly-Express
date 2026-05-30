import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../../domain/expense_entry.dart';
import '../../../domain/sales_entry.dart';
import '../../workspace/application/workspace_data_controller.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.workspace});

  final WorkspaceDataController workspace;

  @override
  Widget build(BuildContext context) {
    final sales = [...workspace.sales];
    final expenses = workspace.expenses;

    if (sales.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: const BrandEmptyState(
          icon: Icons.insights_outlined,
          title: 'No data yet',
          message: 'Add sales and expenses to see your business insights here.',
        ),
      );
    }

    final currency = _inrFormat();
    final now = DateTime.now();

    final todaySales = sales.where((s) => _isSameDay(s.date, now)).toList();
    final todayExp = expenses.where((e) => _isSameDay(e.date, now)).toList();
    final monthSales = sales.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
    final monthExp = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final yearSales = sales.where((s) => s.date.year == now.year).toList();
    final yearExp = expenses.where((e) => e.date.year == now.year).toList();

    final todaySalesAmt = _sumSales(todaySales);
    final todayExpAmt = _sumExpenses(todayExp);
    final todayProfit = _sumProfit(todaySales) - todayExpAmt;
    final todayQuantity = todaySales.fold<int>(0, (sum, sale) => sum + sale.quantity);
    final todayCollection = todaySales.fold<double>(0, (sum, sale) => sum + (sale.paidAmount ?? 0));

    final monthSalesAmt = _sumSales(monthSales);
    final monthExpAmt = _sumExpenses(monthExp);
    final monthProfit = _sumProfit(monthSales) - monthExpAmt;

    final yearSalesAmt = _sumSales(yearSales);
    final yearProfit = _sumProfit(yearSales) - _sumExpenses(yearExp);

    final totalPaid = sales.fold<double>(0, (s, sale) => s + (sale.paidAmount ?? 0));
    final totalPending = sales.fold<double>(0, (s, sale) => s + sale.pendingAmount);

    // Monthly profit bars (this year)
    final monthProfitBars = <_ChartBar>[];
    for (var m = 1; m <= 12; m++) {
      final mSales = yearSales.where((s) => s.date.month == m).toList();
      if (mSales.isEmpty) continue;
      final mExp = yearExp.where((e) => e.date.month == m).toList();
      monthProfitBars.add(_ChartBar(
        label: DateFormat('MMM').format(DateTime(now.year, m)),
        value: _sumProfit(mSales) - _sumExpenses(mExp),
      ));
    }

    // Daily profit bars (this month)
    final dailyBars = _buildDailyBars(monthSales, monthExp);

    // Monthly revenue horizontal bars
    double maxMonthRev = 0;
    final monthRevBars = <_ChartBar>[];
    for (var m = 1; m <= 12; m++) {
      final mSales = yearSales.where((s) => s.date.month == m).toList();
      if (mSales.isEmpty) continue;
      final rev = _sumSales(mSales);
      if (rev > maxMonthRev) maxMonthRev = rev;
      monthRevBars.add(_ChartBar(label: DateFormat('MMM').format(DateTime(now.year, m)), value: rev));
    }

    // Top shops
    final shopRows = _buildShopRows(sales);
    final maxShopSales = shopRows.isEmpty ? 1.0 : shopRows.first.sales;
    final todayShopRows = _buildShopRows(todaySales);
    final topTodayShop = todayShopRows.isEmpty ? null : todayShopRows.first;

    final brand = context.brand;

    return DefaultTabController(
      length: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: brand.surfaceCardAlpha,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brand.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights sections',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: brand.textStrong,
                            fontSize: 17,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe between Today, Month, Year, Collections, and Top shops instead of one long page.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: brand.textMuted,
                            height: 1.35,
                            fontSize: 11.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: BrandTokens.primary,
                  unselectedLabelColor: brand.textMuted,
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                  unselectedLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  indicator: BoxDecoration(
                    color: brand.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: BrandTokens.primary.withValues(alpha: 0.10)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(999),
                  tabs: const [
                    Tab(height: 34, text: 'Today'),
                    Tab(height: 34, text: 'This month'),
                    Tab(height: 34, text: 'This year'),
                    Tab(height: 34, text: 'Collections'),
                    Tab(height: 34, text: 'Top shops'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  _InsightsScrollPage(
                    children: [
                      _SectionHeader(icon: Icons.today_rounded, title: "Today's summary"),
                      const SizedBox(height: 10),
                      _TodaySummaryCard(
                        salesAmt: todaySalesAmt,
                        expAmt: todayExpAmt,
                        profit: todayProfit,
                        currency: currency,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Qty booked',
                              value: todayQuantity.toString(),
                              accent: BrandTokens.primary,
                              icon: Icons.inventory_2_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiTile(
                              label: 'Collection',
                              value: currency.format(todayCollection),
                              accent: BrandTokens.accentOutstanding,
                              icon: Icons.payments_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (topTodayShop != null) ...[
                        const SizedBox(height: 10),
                        _CardContainer(
                          title: 'Top shop today',
                          child: _HorizontalBar(
                            label: topTodayShop.label,
                            value: topTodayShop.sales,
                            maxValue: topTodayShop.sales,
                            displayValue: _compactInr(topTodayShop.sales),
                            color: BrandTokens.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  _InsightsScrollPage(
                    children: [
                      _SectionHeader(icon: Icons.calendar_month_rounded, title: 'This month'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Revenue',
                              value: currency.format(monthSalesAmt),
                              accent: BrandTokens.accentSales,
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiTile(
                              label: monthProfit >= 0 ? 'Profit' : 'Loss',
                              value: currency.format(monthProfit.abs()),
                              accent: monthProfit >= 0 ? const Color(0xFF2E9E5B) : const Color(0xFFD64545),
                              icon: monthProfit >= 0 ? Icons.savings_outlined : Icons.trending_down_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (dailyBars.length > 1) ...[
                        const SizedBox(height: 10),
                        _CardContainer(
                          title: 'Daily profit — this month',
                          child: _ProfitBarChart(bars: dailyBars),
                        ),
                      ],
                    ],
                  ),
                  _InsightsScrollPage(
                    children: [
                      _SectionHeader(icon: Icons.bar_chart_rounded, title: 'This year'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Revenue',
                              value: currency.format(yearSalesAmt),
                              accent: BrandTokens.accentSales,
                              icon: Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiTile(
                              label: yearProfit >= 0 ? 'Profit' : 'Loss',
                              value: currency.format(yearProfit.abs()),
                              accent: yearProfit >= 0 ? const Color(0xFF2E9E5B) : const Color(0xFFD64545),
                              icon: yearProfit >= 0 ? Icons.savings_outlined : Icons.trending_down_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (monthProfitBars.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CardContainer(
                          title: 'Monthly profit & loss',
                          child: _ProfitBarChart(bars: monthProfitBars),
                        ),
                      ],
                      if (monthRevBars.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CardContainer(
                          title: 'Monthly revenue',
                          child: Column(
                            children: monthRevBars
                                .map((bar) => _HorizontalBar(
                                      label: bar.label,
                                      value: bar.value,
                                      maxValue: maxMonthRev,
                                      displayValue: _compactInr(bar.value),
                                      color: BrandTokens.accentSales,
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _InsightsScrollPage(
                    children: [
                      _SectionHeader(icon: Icons.account_balance_wallet_outlined, title: 'Collections'),
                      const SizedBox(height: 10),
                      _CardContainer(
                        title: 'Paid vs outstanding',
                        child: _CollectionVisual(paid: totalPaid, pending: totalPending, currency: currency),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Today collected',
                              value: currency.format(todayCollection),
                              accent: BrandTokens.accentOutstanding,
                              icon: Icons.payments_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiTile(
                              label: 'Outstanding',
                              value: currency.format(totalPending),
                              accent: const Color(0xFFD37B17),
                              icon: Icons.hourglass_bottom_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _InsightsScrollPage(
                    children: [
                      _SectionHeader(icon: Icons.storefront_rounded, title: 'Top shops'),
                      const SizedBox(height: 10),
                      if (shopRows.isNotEmpty)
                        _CardContainer(
                          title: 'Ranked by sales amount',
                          child: Column(
                            children: shopRows
                                .take(8)
                                .map((row) => _HorizontalBar(
                                      label: row.label,
                                      value: row.sales,
                                      maxValue: maxShopSales,
                                      displayValue: _compactInr(row.sales),
                                      color: BrandTokens.primary,
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── UI widgets ───────────────────────────────────────────────────────────────

class _InsightsScrollPage extends StatelessWidget {
  const _InsightsScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(color: brand.primarySoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: BrandTokens.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: brand.textStrong,
                fontSize: 16,
              ),
        ),
      ],
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.salesAmt,
    required this.expAmt,
    required this.profit,
    required this.currency,
  });

  final double salesAmt, expAmt, profit;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? const Color(0xFF2E9E5B) : const Color(0xFFD64545);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: brand.surfaceCardAlpha,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TodayMetric(
                  icon: Icons.trending_up_rounded,
                  label: 'Sales',
                  value: currency.format(salesAmt),
                  color: BrandTokens.accentSales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TodayMetric(
                  icon: Icons.receipt_long_outlined,
                  label: 'Expenses',
                  value: currency.format(expAmt),
                  color: BrandTokens.accentExpense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: profitColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded,
                  color: profitColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProfit ? 'Today profit' : 'Today loss',
                      style: TextStyle(color: profitColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      currency.format(profit.abs()),
                      style: TextStyle(color: profitColor, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: brand.textStrong, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label, value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      constraints: const BoxConstraints(minHeight: 102),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      decoration: BoxDecoration(
        color: brand.surfaceCardAlpha,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: brand.textMuted, fontWeight: FontWeight.w700, fontSize: 11.5)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: brand.textStrong, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: brand.surfaceCardAlpha,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 13),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.displayValue,
    required this.color,
  });

  final String label, displayValue;
  final double value, maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w700, color: brand.textBody, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayValue,
                style: TextStyle(fontWeight: FontWeight.w800, color: brand.textStrong, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionVisual extends StatelessWidget {
  const _CollectionVisual({
    required this.paid,
    required this.pending,
    required this.currency,
  });

  final double paid, pending;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final total = paid + pending;
    final paidFlex = total > 0 ? ((paid / total) * 100).round().clamp(1, 99) : 50;
    final pendingFlex = 100 - paidFlex;
    const paidColor = Color(0xFF2E9E5B);
    const pendingColor = Color(0xFFE07A30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                Flexible(flex: paidFlex, child: Container(color: paidColor)),
                Flexible(flex: pendingFlex, child: Container(color: pendingColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const _LegendDot(color: paidColor, label: 'Collected'),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                currency.format(paid),
                style: const TextStyle(fontWeight: FontWeight.w800, color: paidColor),
              ),
            ),
            const _LegendDot(color: pendingColor, label: 'Pending'),
            const SizedBox(width: 6),
            Text(
              currency.format(pending),
              style: const TextStyle(fontWeight: FontWeight.w800, color: pendingColor),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Vertical P&L bar chart ────────────────────────────────────────────────────

class _ChartBar {
  const _ChartBar({required this.label, required this.value});

  final String label;
  final double value;
}

class _ProfitBarChart extends StatelessWidget {
  const _ProfitBarChart({required this.bars});

  final List<_ChartBar> bars;

  static const double _topRegion = 92;
  static const double _bottomRegion = 64;

  @override
  Widget build(BuildContext context) {
    final maxAbs = bars.fold<double>(0, (peak, bar) => bar.value.abs() > peak ? bar.value.abs() : peak);
    final safeMax = maxAbs == 0 ? 1.0 : maxAbs;
    final hasLoss = bars.any((bar) => bar.value < 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _LegendDot(color: Color(0xFF2E9E5B), label: 'Profit'),
            const SizedBox(width: 16),
            const _LegendDot(color: Color(0xFFD64545), label: 'Loss'),
            const Spacer(),
            Text(
              'Peak ${_compactInr(maxAbs)}',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _topRegion + (hasLoss ? _bottomRegion : 0) + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: bars.map((bar) {
              final positive = bar.value >= 0;
              final fraction = bar.value.abs() / safeMax;
              final fullHeight = fraction * (positive ? _topRegion : _bottomRegion);
              final barHeight = bar.value == 0 ? 0.0 : (fullHeight < 4 ? 4.0 : fullHeight);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      SizedBox(
                        height: _topRegion,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            height: positive ? barHeight : 0,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E9E5B),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1.5, color: Theme.of(context).dividerColor),
                      if (hasLoss)
                        SizedBox(
                          height: _bottomRegion,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: double.infinity,
                              height: positive ? 0 : barHeight,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD64545),
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        bar.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────────

class _ReportRow {
  const _ReportRow({
    required this.label,
    required this.sales,
    required this.profit,
  });

  final String label;
  final double sales, profit;
}

List<_ReportRow> _buildShopRows(List<SalesEntry> sales) {
  final grouped = <String, List<SalesEntry>>{};
  for (final sale in sales) {
    grouped.putIfAbsent(sale.shopName, () => []).add(sale);
  }
  final rows = grouped.entries
      .map((e) => _ReportRow(label: e.key, sales: _sumSales(e.value), profit: _sumProfit(e.value)))
      .toList()
    ..sort((a, b) => b.sales.compareTo(a.sales));
  return rows;
}

List<_ChartBar> _buildDailyBars(List<SalesEntry> sales, List<ExpenseEntry> expenses) {
  final groupedSales = <String, List<SalesEntry>>{};
  final groupedExp = <String, List<ExpenseEntry>>{};

  for (final s in sales) {
    final key = s.date.toIso8601String().split('T').first;
    groupedSales.putIfAbsent(key, () => []).add(s);
  }
  for (final e in expenses) {
    final key = e.date.toIso8601String().split('T').first;
    groupedExp.putIfAbsent(key, () => []).add(e);
  }

  final allKeys = {...groupedSales.keys, ...groupedExp.keys}.toList()..sort();
  return allKeys.reversed.take(14).toList().reversed.map((key) {
    final daySales = groupedSales[key] ?? const <SalesEntry>[];
    final dayExp = groupedExp[key] ?? const <ExpenseEntry>[];
    final date = DateTime.parse(key);
    return _ChartBar(
      label: DateFormat('d/M').format(date),
      value: _sumProfit(daySales) - _sumExpenses(dayExp),
    );
  }).toList();
}

NumberFormat _inrFormat() => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

double _sumSales(List<SalesEntry> sales) => sales.fold(0, (s, e) => s + e.totalSalesAmount);
double _sumProfit(List<SalesEntry> sales) => sales.fold(0, (s, e) => s + e.profit);
double _sumExpenses(List<ExpenseEntry> expenses) => expenses.fold(0, (s, e) => s + e.amount);

String _compactInr(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 100000) return '$sign₹${(abs / 100000).toStringAsFixed(abs >= 1000000 ? 0 : 1)}L';
  if (abs >= 1000) return '$sign₹${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
  return '$sign₹${abs.toStringAsFixed(0)}';
}
