/// Represents a suggested category for a transaction
class CategorySuggestion {
  final String categoryId;
  final double confidence; // 0.0 to 1.0
  final String reason; // Why this category was suggested
  final String? matchedPattern; // The pattern that triggered this suggestion

  CategorySuggestion({
    required this.categoryId,
    required this.confidence,
    required this.reason,
    this.matchedPattern,
  });

  /// Returns confidence as a percentage (0-100)
  int get confidencePercentage => (confidence * 100).round();

  /// Whether this suggestion is confident enough to show to user
  bool get isConfident => confidence >= 0.6;

  /// Confidence level description
  String get confidenceLevel {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.75) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }
}
