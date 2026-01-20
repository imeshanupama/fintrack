import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/insight.dart';
import '../../categories/presentation/category_provider.dart';

class InsightDetailScreen extends ConsumerWidget {
  final Insight insight;

  const InsightDetailScreen({super.key, required this.insight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final category = insight.categoryId != null
        ? categories.firstWhere((c) => c.id == insight.categoryId, orElse: () => categories.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insight Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getInsightColor(insight.insightPriority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getInsightIcon(insight.insightType),
                    color: _getInsightColor(insight.insightPriority),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.insightType.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insight.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              insight.description,
              style: GoogleFonts.outfit(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Category
            if (category != null) ...[
              _buildInfoCard(
                'Category',
                category.name,
                Icon(category.icon, color: Color(category.colorValue)),
              ),
              const SizedBox(height: 16),
            ],

            // Priority
            _buildInfoCard(
              'Priority',
              insight.priority.toUpperCase(),
              Icon(Icons.priority_high, color: _getInsightColor(insight.insightPriority)),
            ),
            const SizedBox(height: 16),

            // Metadata
            if (insight.metadata != null && insight.metadata!.isNotEmpty) ...[
              Text(
                'Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: insight.metadata!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatMetadataKey(entry.key),
                              style: GoogleFonts.outfit(color: Colors.grey),
                            ),
                            Text(
                              _formatMetadataValue(entry.key, entry.value),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Icon icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMetadataKey(String key) {
    return key.split(RegExp(r'(?=[A-Z])')).join(' ').capitalize();
  }

  String _formatMetadataValue(String key, dynamic value) {
    if (value is double) {
      if (key.contains('percentage') || key.contains('Change')) {
        return '${value.toStringAsFixed(1)}%';
      }
      return '\$${value.toStringAsFixed(2)}';
    }
    return value.toString();
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
