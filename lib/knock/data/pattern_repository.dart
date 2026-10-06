import '../knock_pattern.dart';

abstract interface class PatternRepository {
  Future<List<KnockPattern>> load();

  Future<void> save(List<KnockPattern> patterns);

  Future<void> add(KnockPattern pattern);
}
