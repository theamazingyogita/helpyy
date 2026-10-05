import 'package:flutter/material.dart';

class CircleIcon extends StatelessWidget {
  const CircleIcon(this.icon, {super.key, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Icon(icon, size: size * 0.45),
    );
  }
}
