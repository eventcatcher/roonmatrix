import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/menubar_widget.dart';
import 'package:roonmatrix/ui/start_page.dart';

class MainShell extends StatefulWidget {
  final String title;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final GlobalKey<NavigatorState> navigatorKey;
  final Function(BuildContext context) exportDeviceList;

  const MainShell({
    super.key,
    required this.title,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.navigatorKey,
    required this.exportDeviceList,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String get title => widget.title;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  Function(BuildContext context) get exportDeviceList =>
      widget.exportDeviceList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (Platform.isWindows || Platform.isLinux)
            SizedBox(
              height: 24.0,
              child: MenubarWidget(
                  minDesktopSize: minDesktopSize,
                  standardDesktopSize: standardDesktopSize,
                  navigatorKey: navigatorKey,
                  exportDeviceList: exportDeviceList,
                  child: SizedBox()),
            ),
          Expanded(
            child: Navigator(
              key: navigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (_) => StartPage(
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    title: title,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
