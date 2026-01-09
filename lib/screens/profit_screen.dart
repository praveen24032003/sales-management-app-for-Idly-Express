import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../widgets/summary_card.dart';

/// Profit Analysis Screen with charts and comparisons
class ProfitScreen extends StatelessWidget {
  const ProfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Analysis'),
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profit Summary Cards
                Text(
                  'Profit Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    SummaryCard(
                      title: "Today's Profit",
                      value: currencyFormat.format(provider.todayTotalProfit),
                      icon: Icons.today,
                      valueColor: provider.todayTotalProfit >= 0
                          ? context.profitColor
                          : context.lossColor,
                    ),
                    SummaryCard(
                      title: "This Month",
                      value: currencyFormat.format(provider.monthTotalProfit),
                      icon: Icons.calendar_month,
                      valueColor: provider.monthTotalProfit >= 0
                          ? context.profitColor
                          : context.lossColor,
                    ),
                    SummaryCard(
                      title: "This Year",
                      value: currencyFormat.format(provider.yearTotalProfit),
                      icon: Icons.calendar_today,
                      valueColor: provider.yearTotalProfit >= 0
                          ? context.profitColor
                          : context.lossColor,
                    ),
                    SummaryCard(
                      title: "Profit Margin",
                      value: _calculateMargin(provider),
                      icon: Icons.percent,
                      valueColor: context.profitColor,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Wholesale vs Retail Comparison
                Text(
                  'Wholesale vs Retail',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildComparisonCard(context, provider, currencyFormat),

                const SizedBox(height: 24),

                // Monthly Profit Chart
                Text(
                  'Monthly Profit Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 250,
                      child: _buildMonthlyProfitChart(context, provider),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Wholesale vs Retail Pie Chart
                Text(
                  'Profit Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: _buildPieChart(context, provider),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Daily Profit This Month
                Text(
                  'Daily Profit (This Month)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: _buildDailyProfitChart(context, provider),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _calculateMargin(SalesProvider provider) {
    if (provider.yearTotalSales == 0) return '0%';
    final margin = (provider.yearTotalProfit / provider.yearTotalSales) * 100;
    return '${margin.toStringAsFixed(1)}%';
  }

  Widget _buildComparisonCard(
      BuildContext context, SalesProvider provider, NumberFormat format) {
    final wholesaleProfit = provider.wholesaleProfit;
    final retailProfit = provider.retailProfit;
    final total = wholesaleProfit + retailProfit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.warehouse, color: Colors.blue, size: 32),
                      ),
                      const SizedBox(height: 8),
                      const Text('Wholesale'),
                      const SizedBox(height: 4),
                      Text(
                        format.format(wholesaleProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: wholesaleProfit >= 0
                              ? context.profitColor
                              : context.lossColor,
                        ),
                      ),
                      if (total > 0)
                        Text(
                          '${((wholesaleProfit / total) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.store, color: Colors.orange, size: 32),
                      ),
                      const SizedBox(height: 8),
                      const Text('Retail'),
                      const SizedBox(height: 4),
                      Text(
                        format.format(retailProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: retailProfit >= 0
                              ? context.profitColor
                              : context.lossColor,
                        ),
                      ),
                      if (total > 0)
                        Text(
                          '${((retailProfit / total) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyProfitChart(BuildContext context, SalesProvider provider) {
    final monthlyProfits = provider.monthlyProfits;
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    // Get max value for Y axis
    double maxY = monthlyProfits.values.fold<double>(0.0, (a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barGroups: monthlyProfits.entries.map((entry) {
          final isPositive = entry.value >= 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.abs(),
                color: isPositive ? context.profitColor : context.lossColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt() - 1;
                if (index >= 0 && index < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, SalesProvider provider) {
    final wholesaleProfit = provider.wholesaleProfit;
    final retailProfit = provider.retailProfit;

    if (wholesaleProfit <= 0 && retailProfit <= 0) {
      return const Center(
        child: Text('No profit data available'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (wholesaleProfit > 0)
                  PieChartSectionData(
                    value: wholesaleProfit,
                    color: Colors.blue,
                    title: 'W',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (retailProfit > 0)
                  PieChartSectionData(
                    value: retailProfit,
                    color: Colors.orange,
                    title: 'R',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Wholesale', Colors.blue),
            const SizedBox(height: 8),
            _buildLegendItem('Retail', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildDailyProfitChart(BuildContext context, SalesProvider provider) {
    final dailyProfits = provider.dailyProfitsThisMonth;

    if (dailyProfits.isEmpty) {
      return const Center(
        child: Text('No data for this month'),
      );
    }

    double maxY = dailyProfits.values.fold<double>(0.0, (a, b) => a.abs() > b.abs() ? a : b).abs();
    if (maxY <= 0) maxY = 1000;

    final spots = dailyProfits.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        minY: -maxY * 0.1,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0');
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}K',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: context.profitColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: context.profitColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
