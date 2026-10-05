import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/knock_pattern.dart';

void main() {
  const rhythm = KnockPattern(
    id: '1',
    callerName: 'Mom',
    knockCount: 3,
    rhythm: [300, 900],
  );
  const threeTaps = KnockPattern(id: '2', callerName: 'Boss', knockCount: 3);
  const fourTaps = KnockPattern(id: '3', callerName: 'Sam', knockCount: 4);

  group('matches', () {
    test('a rhythm accepts the same rhythm knocked a little off', () {
      expect(rhythm.matches([420, 700]), isTrue);
    });

    test('a rhythm rejects a different rhythm', () {
      expect(rhythm.matches([900, 300]), isFalse);
    });

    test('a tap count accepts any rhythm with that many taps', () {
      expect(threeTaps.matches([100, 900]), isTrue);
      expect(threeTaps.matches([500, 200]), isTrue);
    });

    test('rejects a different number of knocks', () {
      expect(rhythm.matches([300]), isFalse);
      expect(threeTaps.matches([300, 300, 300]), isFalse);
    });
  });

  group('overlaps', () {
    test('a tap count overlaps a rhythm with as many knocks', () {
      expect(threeTaps.overlaps(rhythm), isTrue);
      expect(rhythm.overlaps(threeTaps), isTrue);
    });

    test('different counts never overlap', () {
      expect(threeTaps.overlaps(fourTaps), isFalse);
    });

    test('rhythms overlap only when they match', () {
      const close = KnockPattern(
        id: '4',
        callerName: 'X',
        knockCount: 3,
        rhythm: [350, 850],
      );
      const far = KnockPattern(
        id: '5',
        callerName: 'Y',
        knockCount: 3,
        rhythm: [900, 300],
      );
      expect(rhythm.overlaps(close), isTrue);
      expect(rhythm.overlaps(far), isFalse);
    });
  });

  test('survives a json round trip', () {
    expect(KnockPattern.fromJson(rhythm.toJson()), rhythm);
    expect(KnockPattern.fromJson(threeTaps.toJson()), threeTaps);
  });

  test('rejects json with missing fields', () {
    expect(() => KnockPattern.fromJson({'id': '1'}), throwsFormatException);
  });

  test('rejects json with a bad rhythm', () {
    expect(
      () => KnockPattern.fromJson({
        ...threeTaps.toJson(),
        'rhythm': ['fast'],
      }),
      throwsFormatException,
    );
  });
}
