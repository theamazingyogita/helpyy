import 'package:flutter/material.dart';

import '../calls/view/calls_tab.dart';
import '../home/view/home_tab.dart';
import '../settings/view/settings_tab.dart';
import 'app_navigation_bar.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kept alive so Home keeps listening while another tab is open.
      body: IndexedStack(
        index: _tab,
        children: const [HomeTab(), CallsTab(), SettingsTab()],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}
