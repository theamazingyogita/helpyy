import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onBack, this.trailing});

  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
              ),
            ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
