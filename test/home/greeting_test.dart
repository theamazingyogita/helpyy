import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/home/greeting.dart';

void main() {
  test('greets by time of day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 3)), 'Up late');
    expect(greetingFor(DateTime(2026, 1, 1, 9)), 'Good morning');
    expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 1, 1, 20)), 'Good evening');
  });
}
