import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The app icon: the handwritten h with its yellow dot on blue, as a
/// rounded tile.
class AppMonogram extends StatelessWidget {
  const AppMonogram({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // The corner of an iOS app icon, roughly.
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SvgPicture.asset(
        'assets/images/logo_monogram.svg',
        width: size,
        height: size,
        semanticsLabel: 'helpyy logo',
      ),
    );
  }
}
