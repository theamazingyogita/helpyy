import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/app/app_theme.dart';
import 'package:helpyy/call/view/call_page.dart';
import 'package:helpyy/call/view/widgets/pulsing_ring.dart';
import 'package:helpyy/calls/data/call_log_repository.dart';
import 'package:helpyy/calls/data/local_call_log_repository.dart';
import 'package:helpyy/knock/knock_pattern.dart';
import 'package:helpyy/ringtone/ringtone_player.dart';
import 'package:helpyy/settings/data/local_settings_repository.dart';
import 'package:helpyy/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';

void main() {
  Future<CallLogRepository> pumpCall(
    WidgetTester tester, {
    int delay = 0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final CallLogRepository log = LocalCallLogRepository(prefs, userId: 'u1');
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: log),
          RepositoryProvider<RingtonePlayer>.value(
            value: silentRingtonePlayer(),
          ),
          RepositoryProvider<SettingsRepository>.value(
            value: LocalSettingsRepository(prefs, userId: 'u1'),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                CallPage.route(
                  KnockPattern(
                    id: '1',
                    callerName: 'Maya',
                    knockCount: 3,
                    delaySeconds: delay,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Ringing animates forever, so wait out the route transition instead of
    // settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return log;
  }

  testWidgets('counts down, then rings', (tester) async {
    await pumpCall(tester, delay: 2);

    expect(find.text('Act natural.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Swipe up to answer'), findsOneWidget);
  });

  testWidgets('cancel during the countdown closes without a call', (
    tester,
  ) async {
    final log = await pumpCall(tester, delay: 5);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(CallPage), findsNothing);
    expect(await log.load(), isEmpty);
  });

  testWidgets(
    'on iPhone the answer button pulses and a tap answers',
    (tester) async {
      final log = await pumpCall(tester);

      expect(find.byType(PulsingRing), findsOneWidget);
      expect(find.text('mobile'), findsOneWidget);
      final width = tester.getSize(find.byType(CallPage)).width;
      final decline = tester.getCenter(find.byTooltip('Decline')).dx;
      final answer = tester.getCenter(find.byTooltip('Answer')).dx;
      expect(decline, moreOrLessEquals(width - answer, epsilon: 0.5));
      await tester.tap(find.byTooltip('Answer'));
      await tester.pump();
      expect(find.byType(PulsingRing), findsNothing);
      expect(find.text('00:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 65));
      expect(find.text('01:05'), findsOneWidget);

      await tester.tap(find.byTooltip('End'));
      await tester.pumpAndSettle();
      expect(find.byType(CallPage), findsNothing);
      expect((await log.load()).single.talkTime, const Duration(seconds: 65));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'on Android swiping up answers',
    (tester) async {
      final log = await pumpCall(tester);

      expect(find.byTooltip('Answer'), findsNothing);
      await tester.drag(find.byIcon(Icons.call), const Offset(0, -150));
      await tester.pump();
      expect(find.text('00:00'), findsOneWidget);

      await tester.tap(find.byTooltip('End'));
      await tester.pumpAndSettle();
      expect((await log.load()).single.answered, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'on Android a short drag springs back and keeps ringing',
    (tester) async {
      await pumpCall(tester);

      await tester.drag(find.byIcon(Icons.call), const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('Swipe up to answer'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
