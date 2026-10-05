import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/app/app_theme.dart';
import 'package:helpyy/shell/app_navigation_bar.dart';

void main() {
  Future<List<int>> pumpBar(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme().copyWith(platform: platform),
        home: Scaffold(
          bottomNavigationBar: AppNavigationBar(
            selectedIndex: 0,
            onSelected: taps.add,
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('uses a Cupertino tab bar on iOS', (tester) async {
    final taps = await pumpBar(tester, TargetPlatform.iOS);

    final bar = tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    expect(bar.activeColor, buildAppTheme().colorScheme.primary);
    expect(find.byIcon(CupertinoIcons.house_fill), findsOneWidget);

    expect(find.text('Calls'), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.phone));
    expect(taps, [1]);
  });

  testWidgets('uses a Material navigation bar on Android', (tester) async {
    final taps = await pumpBar(tester, TargetPlatform.android);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.labelBehavior, NavigationDestinationLabelBehavior.alwaysHide);
    await tester.tap(find.byTooltip('Settings'));
    expect(taps, [2]);
  });
}
