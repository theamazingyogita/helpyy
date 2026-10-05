import 'package:equatable/equatable.dart';

/// A saved signal: how to knock, and who calls when you do.
///
/// With no [rhythm] any [knockCount] taps in a row match. With a rhythm the
/// gaps between knocks have to match too.
class KnockPattern extends Equatable {
  const KnockPattern({
    required this.id,
    required this.callerName,
    required this.knockCount,
    this.rhythm,
    this.delaySeconds = 0,
  });

  factory KnockPattern.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'callerName': final String callerName,
      'knockCount': final int knockCount,
      'delaySeconds': final int delaySeconds,
    }) {
      return KnockPattern(
        id: id,
        callerName: callerName,
        knockCount: knockCount,
        delaySeconds: delaySeconds,
        rhythm: switch (json['rhythm']) {
          null => null,
          final List<Object?> gaps => [
            for (final gap in gaps)
              gap is int ? gap : throw FormatException('Bad gap', gap),
          ],
          final other => throw FormatException('Bad rhythm', other),
        },
      );
    }
    throw FormatException('Not a knock pattern', json);
  }

  final String id;
  final String callerName;
  final int knockCount;

  /// Milliseconds between consecutive knocks, for custom rhythms.
  final List<int>? rhythm;

  final int delaySeconds;

  bool matches(List<int> gaps) {
    if (gaps.length + 1 != knockCount) return false;
    final rhythm = this.rhythm;
    if (rhythm == null) return true;
    // Nobody knocks the same rhythm twice to the millisecond. Short gaps get
    // a fixed allowance, long ones a proportional one.
    for (var i = 0; i < rhythm.length; i++) {
      final allowed = rhythm[i] * 0.35 > 150 ? rhythm[i] * 0.35 : 150;
      if ((gaps[i] - rhythm[i]).abs() > allowed) return false;
    }
    return true;
  }

  /// Whether one set of knocks could set off both signals.
  bool overlaps(KnockPattern other) {
    if (other.knockCount != knockCount) return false;
    if (other.rhythm case final otherRhythm?) {
      return matches(otherRhythm);
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'callerName': callerName,
    'knockCount': knockCount,
    'rhythm': rhythm,
    'delaySeconds': delaySeconds,
  };

  @override
  List<Object?> get props => [id, callerName, knockCount, rhythm, delaySeconds];
}
