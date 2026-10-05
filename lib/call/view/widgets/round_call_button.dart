import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'pulsing_ring.dart';

class RoundCallButton extends StatelessWidget {
  const RoundCallButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isPulsing = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isPulsing;

  @override
  Widget build(BuildContext context) {
    final onCall = AppColors.of(context).onCall;
    final button = IconButton.filled(
      iconSize: 32,
      padding: const EdgeInsets.all(20),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onCall,
      ),
      tooltip: label,
      icon: Icon(icon),
      onPressed: onPressed,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        isPulsing ? PulsingRing(color: color, child: button) : button,
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: onCall),
        ),
      ],
    );
  }
}
