import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// A tap on something off screen should fail the test, not just print.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
