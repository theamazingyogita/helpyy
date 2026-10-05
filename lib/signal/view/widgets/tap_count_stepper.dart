import 'package:flutter/material.dart';

import '../../../widgets/handwritten.dart';

class TapCountStepper extends StatelessWidget {
  const TapCountStepper({
    super.key,
    required this.count,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int count;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: Theme.of(context).colorScheme.outline);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        IconButton(
          tooltip: 'Fewer taps',
          style: IconButton.styleFrom(side: side),
          onPressed: count > min ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Handwritten('$count taps', fontSize: 30),
        IconButton(
          tooltip: 'More taps',
          style: IconButton.styleFrom(side: side),
          onPressed: count < max ? () => onChanged(count + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
