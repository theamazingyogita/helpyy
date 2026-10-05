import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'app_logo.dart';

final _brand = RegExp(r'helpyy(\.)?', caseSensitive: false);
final _wordAfter = RegExp(r'[\s\w]');

/// Builds [text] with every "helpyy" drawn like the logo: lowercase, in the
/// handwriting face, with the yellow dot.
///
/// The dot is left off when other punctuation follows ("on helpyy?"), so
/// sentences do not end up with two marks.
TextSpan brandSpan(String text, {TextStyle? style, required Color dotColor}) {
  final base = style ?? const TextStyle();
  final logo = base.copyWith(
    fontFamily: handwritingFont,
    fontSize: (base.fontSize ?? 14) * 1.2,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in _brand.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    spans.add(TextSpan(text: 'helpyy', style: logo));
    final next = match.end < text.length ? text[match.end] : null;
    final hadDot = match.group(1) != null;
    if (hadDot || next == null || _wordAfter.hasMatch(next)) {
      spans.add(
        TextSpan(
          text: '.',
          style: logo.copyWith(
            color: dotColor,
            fontSize: logo.fontSize! * dotScale,
          ),
        ),
      );
    }
    start = match.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return TextSpan(style: style, children: spans);
}

/// [Text] that draws the brand name like the logo. See [brandSpan].
class BrandText extends StatelessWidget {
  const BrandText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    return Text.rich(
      brandSpan(
        text,
        style: style,
        dotColor: Theme.of(context).colorScheme.secondary,
      ),
      textAlign: textAlign,
    );
  }
}
