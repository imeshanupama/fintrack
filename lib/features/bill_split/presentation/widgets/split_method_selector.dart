import 'package:flutter/material.dart';

enum SplitMethod { equal, custom, percentage }

class SplitMethodSelector extends StatelessWidget {
  final SplitMethod selectedMethod;
  final ValueChanged<SplitMethod> onMethodChanged;

  const SplitMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SplitMethod>(
      segments: const [
        ButtonSegment<SplitMethod>(
          value: SplitMethod.equal,
          label: Text('Equal'),
          icon: Icon(Icons.pie_chart_outline),
        ),
        ButtonSegment<SplitMethod>(
          value: SplitMethod.custom,
          label: Text('Custom'),
          icon: Icon(Icons.edit),
        ),
        ButtonSegment<SplitMethod>(
          value: SplitMethod.percentage,
          label: Text('Percentage'),
          icon: Icon(Icons.percent),
        ),
      ],
      selected: {selectedMethod},
      onSelectionChanged: (Set<SplitMethod> newSelection) {
        onMethodChanged(newSelection.first);
      },
    );
  }
}
