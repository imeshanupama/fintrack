import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/insight.dart';
import 'insights_provider.dart';
import '../../categories/presentation/category_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _filterType = 'all'; // all, trend, warning, recommendation, prediction

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(insightsNotifierProvider.notifier).generateInsights();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Trends', 'trend'),
                const SizedBox(width: 8),
                _buildFilterChip('Warnings', 'warning'),
                const SizedBox(width: 8),
                _buildFilterChip('Tips', 'recommendation'),
                const SizedBox(width: 8),
                _buildFilterChip('Predictions', 'prediction'),
              ],
            ),
          ),

          // Insights List
          Expanded(
            child: insightsAsync.when(
              data: (insights) {
                final filteredInsights = _filterType == 'all'
                    ? insights
                    : insights.where((i) => i.type == _filterType).toList();

                if (filteredInsights.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No insights yet',
                          style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap refresh to generate insights',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredInsights.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(filteredInsights[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error', style: GoogleFonts.outfit()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
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

  Widget _buildInsightCard(Insight insight) {
    final icon = _getInsightIcon(insight.insightType);
    final color = _getInsightColor(insight.insightPriority);
    final categories = ref.watch(categoryProvider);
    final category = insight.categoryId != null
        ? categories.firstWhere((c) => c.id == insight.categoryId, orElse: () => categories.first)
        : null;

    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(insightsNotifierProvider.notifier).dismissInsight(insight.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insight dismissed')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            context.push('/insight-detail', extra: insight);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (category != null)
                            Text(
                              category.name,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (insight.insightPriority == InsightPriority.critical ||
                        insight.insightPriority == InsightPriority.high)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          insight.priority.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight.description,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
                ),
                if (insight.actionable) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Tap for details',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.trend:
        return Icons.trending_up;
      case InsightType.warning:
        return Icons.warning_amber;
      case InsightType.recommendation:
        return Icons.lightbulb;
      case InsightType.prediction:
        return Icons.analytics;
      case InsightType.achievement:
        return Icons.emoji_events;
    }
  }

  Color _getInsightColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.blue;
      case InsightPriority.low:
        return Colors.green;
    }
  }
}
