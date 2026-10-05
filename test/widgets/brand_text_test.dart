import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/app/app_theme.dart';
import 'package:helpyy/widgets/brand_text.dart';

void main() {
  List<String> parts(String text) {
    final span = brandSpan(text, dotColor: Colors.amber);
    return [for (final child in span.children!) (child as TextSpan).text!];
  }

  test('draws the brand as the logo with its dot', () {
    expect(parts('Join helpyy'), ['Join ', 'helpyy', '.']);
    expect(parts('helpyy gives you'), ['helpyy', '.', ' gives you']);
  });

  test('uses an existing full stop as the dot', () {
    expect(parts('Love helpyy.'), ['Love ', 'helpyy', '.']);
  });

  test('skips the dot before other punctuation', () {
    expect(parts('Already on helpyy?'), ['Already on ', 'helpyy', '?']);
  });

  test('matches any case and writes it lowercase', () {
    expect(parts('HELPYY IS LISTENING'), ['helpyy', '.', ' IS LISTENING']);
  });

  test('logo parts use the handwriting font and the dot colour', () {
    final span = brandSpan('helpyy', dotColor: Colors.amber);
    final [name, dot] = span.children!.cast<TextSpan>();
    expect(name.style?.fontFamily, handwritingFont);
    expect(dot.style?.color, Colors.amber);
  });
}
