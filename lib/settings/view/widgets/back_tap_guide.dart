import 'package:flutter/material.dart';

import '../../../widgets/brand_text.dart';

class BackTapGuide extends StatelessWidget {
  const BackTapGuide({super.key});

  static const _steps = [
    'In the Shortcuts app, tap +, search for helpyy and add "Double tap '
        'escape call" or "Triple tap escape call". Save it.',
    'Open Settings, then Accessibility, Touch, Back Tap.',
    'Pick Double Tap or Triple Tap and choose that shortcut.',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        BrandText(
          'Back Tap rings your double or triple tap signal from anywhere, '
          'even when helpyy is closed or the phone is locked.',
          style: textTheme.bodySmall,
        ),
        for (final (index, step) in _steps.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text('${index + 1}.', style: textTheme.titleSmall),
              Expanded(child: Text(step, style: textTheme.bodyMedium)),
            ],
          ),
      ],
    );
  }
}
