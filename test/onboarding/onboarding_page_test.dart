import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/auth/log_in/view/log_in_page.dart';
import 'package:helpyy/auth/sign_up/view/sign_up_page.dart';
import 'package:helpyy/widgets/app_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  Future<void> pumpIntro(WidgetTester tester) => tester.pumpHelpyy(
    detector: MockKnockDetector(),
    hasSeenIntro: false,
    signedIn: false,
  );

  testWidgets('walks through the intro and lands on log in', (tester) async {
    await pumpIntro(tester);

    expect(find.text('Need an easy way out?'), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text("we've all been there"), findsOneWidget);
    await tester.tap(find.text('Show me how'));
    await tester.pumpAndSettle();
    expect(find.text('Tap the back of your phone.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your phone rings.'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('I have an account'), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(LogInPage), findsOneWidget);
    expect(find.byType(SignUpPage), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_intro'), isTrue);
  });

  testWidgets('skip lands on log in, and sign up opens only from its link', (
    tester,
  ) async {
    await pumpIntro(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(LogInPage), findsOneWidget);
    expect(find.byType(SignUpPage), findsNothing);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(LogInPage), findsOneWidget);
  });
}
