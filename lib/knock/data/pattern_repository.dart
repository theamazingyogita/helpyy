import '../knock_pattern.dart';

/// The signed in user's saved signals.
abstract interface class PatternRepository {
  /// Throws [FormatException] if stored data is unreadable.
  Future<List<KnockPattern>> load();

  /// Replaces all signals. Throws [StorageWriteException].
  Future<void> save(List<KnockPattern> patterns);

  /// Throws [StorageWriteException].
  Future<void> add(KnockPattern pattern);
}
