import 'package:flutter/material.dart';
import 'pages/settings_page.dart';
import 'pages/measure_page.dart';
import 'pages/review_export_page2.dart';
import 'pages/stack_diagram_page.dart';
import 'widgets/top_start_controls.dart';
import 'widgets/measure_pass_controls.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 1; // Start with measure tab

  List<Widget> _buildPages() {
    return [
      const SettingsPage(),
      const MeasurePage(),
      const StackDiagramPage(),
      ReviewExportPage(
        onNavigateToMeasureTab: (int tabIndex) {
          setState(() {
            _currentIndex = tabIndex;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 譛ｬ譁・・繝壹・繧ｸ縺ｮ縺ｿ・井ｸ企Κ繝舌・縺ｯ蟒・ｭ｢・・
      body: _buildPages()[_currentIndex],
      // 荳矩Κ縺ｫ縲卦opPassControls 竊・NavigationBar縲阪・鬆・〒邵ｦ遨阪∩
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1),
            if (_currentIndex == 1) const MeasurePassControls(),
            if (_currentIndex == 1) const SizedBox(height: 4),
            NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.settings), label: '\u6761\u4ef6\u5165\u529b'),
                NavigationDestination(icon: Icon(Icons.speed), label: '\u6e2c\u5b9a'),
                NavigationDestination(icon: Icon(Icons.bubble_chart), label: '\u7a4d\u5c64\u56f3'),
                NavigationDestination(icon: Icon(Icons.assignment), label: '\u78ba\u8a8d\u30fb\u51fa\u529b'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




