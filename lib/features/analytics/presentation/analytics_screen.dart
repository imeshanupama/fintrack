import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analytics_provider.dart';
import 'widgets/spending_bar_chart.dart';
import 'widgets/spending_line_chart.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_comparison_chart.dart';
import 'widgets/chart_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _showIncome = false;
  String _period = 'week'; // 'week', 'month', 'year'
  String _chartType = 'bar'; // 'bar', 'line'

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    // Define colors
    final incomeColor = Colors.green;
    final expenseColor = Colors.redAccent;
    final activeColor = _showIncome ? incomeColor : expenseColor;

    // Use dynamic maps based on period and type
    Map<String, double> breakdownData;
    Map<int, double> chartData;
    Map<int, double> previousChartData;
    
    // Select Data Source
    if (_showIncome) {
      if (_period == 'year') {
        breakdownData = analytics.incomeYearlyCategory;
        chartData = analytics.incomeYearlyChart;
        previousChartData = analytics.previousIncomeYearlyChart;
      } else if (_period == 'month') {
        breakdownData = analytics.incomeMonthlyCategory;
        chartData = analytics.incomeMonthlyChart;
        previousChartData = analytics.previousIncomeMonthlyChart;
      } else {
        breakdownData = analytics.incomeWeeklyCategory;
        chartData = analytics.incomeWeeklyChart;
        previousChartData = analytics.previousIncomeWeeklyChart;
      }
    } else {
      if (_period == 'year') {
        breakdownData = analytics.yearlyCategorySpending;
        chartData = analytics.yearlyChartData;
        previousChartData = analytics.previousYearlyChartData;
      } else if (_period == 'month') {
        breakdownData = analytics.monthlyCategorySpending;
        chartData = analytics.monthlyChartData;
        previousChartData = analytics.previousMonthlyChartData;
      } else {
        breakdownData = analytics.weeklyCategorySpending;
        chartData = analytics.weeklyChartData;
        previousChartData = analytics.previousWeeklyChartData;
      }
    }

    final title = _showIncome ? 'Income' : 'Expense';
    String periodTitle = 'Weekly';
    if (_period == 'month') periodTitle = 'Monthly';
    if (_period == 'year') periodTitle = 'Yearly';

    final isEmpty = chartData.values.every((v) => v == 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/calendar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income/Expense Toggle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showIncome ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_showIncome ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: !_showIncome ? expenseColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showIncome ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _showIncome ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: _showIncome ? incomeColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Time Period Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodChip('Week', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip('Month', 'month'),
                const SizedBox(width: 8),
                _buildPeriodChip('Year', 'year'),
              ],
            ),
            const SizedBox(height: 24),

            // Spending Trend Chart
            ChartCard(
              title: '$periodTitle $title Trend',
              subtitle: 'Track your spending patterns over time',
              isEmpty: isEmpty,
              emptyMessage: 'No $title data for this period',
              chart: Column(
                children: [
                  // Chart Type Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChartTypeChip('Bar', 'bar', Icons.bar_chart),
                      const SizedBox(width: 8),
                      _buildChartTypeChip('Line', 'line', Icons.show_chart),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart
                  _chartType == 'bar'
                      ? SpendingBarChart(
                          spending: chartData,
                          color: activeColor,
                          period: _period,
                        )
                      : SpendingLineChart(
                          spending: chartData,
                          color: activeColor,
                          period: _period,
                          showGradient: true,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Period Comparison Chart
            ChartCard(
              title: 'Period Comparison',
              subtitle: 'Compare current vs previous period',
              isEmpty: isEmpty,
              emptyMessage: 'No data available for comparison',
              chart: MonthlyComparisonChart(
                currentPeriod: chartData,
                previousPeriod: previousChartData,
                period: _period,
                currentColor: activeColor,
                previousColor: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),

            // Category Breakdown Chart
            ChartCard(
              title: '$title Breakdown by Category',
              subtitle: 'See where your money goes',
              isEmpty: breakdownData.isEmpty,
              emptyMessage: 'No category data available',
              chart: CategoryPieChart(
                categoryData: breakdownData,
                isDonut: true,
                showLegend: true,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeChip(String label, String value, IconData icon) {
    final isSelected = _chartType == value;
    return GestureDetector(
      onTap: () => setState(() => _chartType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
