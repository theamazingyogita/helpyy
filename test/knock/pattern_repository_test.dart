import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/knock/data/local_pattern_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const mom = KnockPattern(
    id: '1',
    callerName: 'Mom',
    knockCount: 3,
    rhythm: [300, 300],
  );
  const boss = KnockPattern(id: '2', callerName: 'Boss', knockCount: 4);

  Future<LocalPatternRepository> repositoryWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalPatternRepository(
      await SharedPreferences.getInstance(),
      userId: 'u1',
    );
  }

  test('loads nothing when nothing is stored', () async {
    final repository = await repositoryWith({});

    expect(await repository.load(), isEmpty);
  });

  test('adds patterns and loads them back in order', () async {
    final repository = await repositoryWith({});

    await repository.add(mom);
    await repository.add(boss);

    expect(await repository.load(), [mom, boss]);
  });

  test('save replaces what was stored', () async {
    final repository = await repositoryWith({});
    await repository.save([mom, boss]);

    await repository.save([boss]);

    expect(await repository.load(), [boss]);
  });

  test('throws FormatException for corrupt data', () async {
    final repository = await repositoryWith({
      'user:u1:knock_patterns': ['not json'],
    });

    expect(repository.load(), throwsFormatException);
  });
}
