import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/slider_expandable.dart';
import 'package:roonmatrix/ui/layout/slider_mobile.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarFlutterStyle extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final bool showExpandableSpeedSlider;
  final Size standardDesktopSize;
  final double scrollSpeedDevice;
  final WindowManager windowManager;
  final Widget? drawer;
  final Widget body;
  final VoidCallback resizeToFullWidth;
  final Function({required double height}) setAppBarHeight;
  final Function({required double speed}) sliderUpdateValue;

  const PageWithToolbarFlutterStyle({
    super.key,
    required this.scaffoldKey,
    required this.title,
    required this.showExpandableSpeedSlider,
    required this.standardDesktopSize,
    required this.scrollSpeedDevice,
    required this.windowManager,
    this.drawer,
    required this.body,
    required this.resizeToFullWidth,
    required this.setAppBarHeight,
    required this.sliderUpdateValue,
  });

  @override
  State<PageWithToolbarFlutterStyle> createState() =>
      _PageWithToolbarFlutterStyleState();
}

class _PageWithToolbarFlutterStyleState
    extends State<PageWithToolbarFlutterStyle> with WindowListener {
  bool get showExpandableSpeedSlider => widget.showExpandableSpeedSlider;
  Size get standardDesktopSize => widget.standardDesktopSize;
  double get scrollSpeedDevice => widget.scrollSpeedDevice;
  WindowManager get windowManager => widget.windowManager;
  Function({required double speed}) get sliderUpdateValue =>
      widget.sliderUpdateValue;
  Function({required double height}) get setAppBarHeight =>
      widget.setAppBarHeight;

  bool isFullscreen = false;

  late PreferredSizeWidget appBarWithActions;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      bool isFullscreenStatus = await windowManager.isFullScreen();

      if (mounted) {
        setState(() {
          isFullscreen = isFullscreenStatus;
        });
      }
    });

    windowManager.addListener(this);

    appBarWithActions = getAppBar();
    double appBarHeight = appBarWithActions.preferredSize.height;
    setAppBarHeight(height: appBarHeight);

    super.initState();
  }

  @override
  void didUpdateWidget(PageWithToolbarFlutterStyle oldWidget) {
    super.didUpdateWidget(oldWidget);

    appBarWithActions = getAppBar();
    double appBarHeight = appBarWithActions.preferredSize.height;
    setAppBarHeight(height: appBarHeight);
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      isFullscreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      isFullscreen = false;
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  PreferredSizeWidget getAppBar() => AppBar(
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  iconSize: 16.0,
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.resizeToFullWidth(),
                  icon: Icon(
                    FontAwesomeIcons.arrowsLeftRight,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: Platform.isMacOS ? 16.0 : 4.0),
                child: IconButton(
                  iconSize: 16.0,
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      windowManager.setSize(standardDesktopSize, animate: true),
                  icon: Icon(
                    FontAwesomeIcons.minimize,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                ),
              ),
              if (Platform.isMacOS)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: IconButton(
                    iconSize: 16.0,
                    padding: EdgeInsets.zero,
                    onPressed: () => windowManager.maximize(),
                    icon: Icon(
                      FontAwesomeIcons.maximize,
                      color: SharedWidgets.toolbarResizeButtonColor(
                          context: context),
                    ),
                  ),
                ),
            ],
          ),
          if (SharedWidgets.isMobileDevice())
            Container(
              width: showExpandableSpeedSlider ? 188.0 : 150.0,
              padding: showExpandableSpeedSlider
                  ? EdgeInsets.only(top: 5.0, right: 8.0)
                  : null,
              child: showExpandableSpeedSlider
                  ? SliderExpandable(
                      width: 236.0,
                      value: scrollSpeedDevice,
                      updateValue: (double value) =>
                          sliderUpdateValue(speed: value),
                    )
                  : SliderMobile(
                      value: scrollSpeedDevice,
                      updateValue: (double value) =>
                          sliderUpdateValue(speed: value),
                    ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
      key: widget.scaffoldKey,
      appBar: SharedWidgets.isDesktopDevice() && isFullscreen
          ? null
          : appBarWithActions,
      drawer: widget.drawer,
      body: SafeArea(child: widget.body));
}
