import 'package:flutter/material.dart';

import 'eyebrow.dart';
import 'brand_text.dart';

/// Eyebrow label, big headline and optional body text, as used at the top of
/// most screens.
class ScreenHeading extends StatelessWidget {
  const ScreenHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Eyebrow(eyebrow),
        BrandText(title, style: textTheme.displaySmall),
        if (body case final body?) BrandText(body, style: textTheme.bodyMedium),
      ],
    );
  }
}
