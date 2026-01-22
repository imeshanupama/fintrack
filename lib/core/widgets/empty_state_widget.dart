import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? color;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with circular background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: effectiveColor,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5)),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),

            // Action button (optional)
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: effectiveColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}
