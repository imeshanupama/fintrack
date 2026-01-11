import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/savings_goal.dart';
import '../../../settings/presentation/settings_provider.dart';

class SavingsGoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  const SavingsGoalCard({
    super.key, 
    required this.goal, 
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).currency;
    final currencyFormat = NumberFormat.simpleCurrency(name: currency);
    final progress = goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0;
    final progressPercent = (progress * 100).clamp(0, 100).toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(goal.colorValue).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(goal.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                        color: Color(goal.colorValue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Target: ${currencyFormat.format(goal.targetAmount)}',
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(goal.savedAmount),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: GoogleFonts.outfit(
                            color: Color(goal.colorValue),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[100],
                  color: Color(goal.colorValue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'reset') onReset();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                const PopupMenuItem(value: 'reset', child: Text('Reset Progress')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Goal', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
