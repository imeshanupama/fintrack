import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/forecast_model.dart';

class ForecastCardWidget extends StatelessWidget {
  final ForecastModel forecast;
  final String currencySymbol;
  final VoidCallback? onTap;

  const ForecastCardWidget({
    super.key,
    required this.forecast,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTrendColor(forecast.trend).withOpacity(0.1),
                _getTrendColor(forecast.trend).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTrendColor(forecast.trend).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: _getTrendColor(forecast.trend),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Month Forecast',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(forecast.forecastDate),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Predicted Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencySymbol,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getTrendColor(forecast.trend),
                    ),
                  ),
                  Text(
                    forecast.predictedAmount.toStringAsFixed(2),
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _getTrendColor(forecast.trend),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Confidence Range
              Row(
                children: [
                  Icon(
                    forecast.isReliable ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: forecast.isReliable ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '±${forecast.confidenceRange.toStringAsFixed(0)}% confidence',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Trend Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getTrendColor(forecast.trend).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTrendColor(forecast.trend).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      forecast.trendIcon,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getTrendColor(forecast.trend),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      forecast.trendDescription,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getTrendColor(forecast.trend),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (forecast.reason != null) ...[
                const SizedBox(height: 12),
                Text(
                  forecast.reason!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increasing':
        return Colors.red.shade600;
      case 'decreasing':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
