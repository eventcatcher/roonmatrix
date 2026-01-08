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
  final bool withTabController;
  final int tabLength;
  final PreferredSizeWidget? tabBar;
  final List<Widget>? actions;
  final bool showExpandableSpeedSlider;
  final Size standardDesktopSize;
  final double scrollSpeedDevice;
  final Widget? drawer;
  final Widget body;
  final VoidCallback? backButtonPressed;
  final VoidCallback resizeToFullWidth;
  final Function({required double height})? setAppBarHeight;
  final Function({required double speed})? sliderUpdateValue;

  const PageWithToolbarFlutterStyle({
    super.key,
    required this.scaffoldKey,
    required this.title,
    this.withTabController = false,
    this.tabLength = 2,
    this.tabBar,
    this.actions,
    required this.showExpandableSpeedSlider,
    required this.standardDesktopSize,
    required this.scrollSpeedDevice,
    this.drawer,
    required this.body,
    this.backButtonPressed,
    required this.resizeToFullWidth,
    this.setAppBarHeight,
    this.sliderUpdateValue,
  });

  @override
  State<PageWithToolbarFlutterStyle> createState() =>
      _PageWithToolbarFlutterStyleState();
}

class _PageWithToolbarFlutterStyleState
    extends State<PageWithToolbarFlutterStyle> with WindowListener {
  bool get withTabController => widget.withTabController;
  bool get showExpandableSpeedSlider => widget.showExpandableSpeedSlider;
  Size get standardDesktopSize => widget.standardDesktopSize;
  double get scrollSpeedDevice => widget.scrollSpeedDevice;
  Function({required double speed})? get sliderUpdateValue =>
      widget.sliderUpdateValue;
  Function({required double height})? get setAppBarHeight =>
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
    if (setAppBarHeight != null) {
      setAppBarHeight!(height: appBarHeight);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(PageWithToolbarFlutterStyle oldWidget) {
    super.didUpdateWidget(oldWidget);

    appBarWithActions = getAppBar();
    double appBarHeight = appBarWithActions.preferredSize.height;
    if (setAppBarHeight != null) {
      setAppBarHeight!(height: appBarHeight);
    }
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      isFullscreen = true;
      appBarWithActions = getAppBar();
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      isFullscreen = false;
      appBarWithActions = getAppBar();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  PreferredSizeWidget getAppBar() => AppBar(
        title: Text(widget.title),
        leading: widget.title == 'RoonMatrix'
            ? null
            : BackButton(
                onPressed: () {
                  if (widget.backButtonPressed != null) {
                    widget.backButtonPressed!();
                  }
                  Navigator.pop(context);
                },
              ),
        actions: [
          Row(
            children: [
              if (widget.actions != null) ...widget.actions!,
              if (SharedWidgets.isDesktopDevice() && !isFullscreen) ...[
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
                  padding:
                      EdgeInsets.only(right: Platform.isMacOS ? 16.0 : 4.0),
                  child: IconButton(
                    iconSize: 16.0,
                    padding: EdgeInsets.zero,
                    onPressed: () => windowManager.setSize(standardDesktopSize,
                        animate: true),
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
              ]
            ],
          ),
          if (SharedWidgets.isMobileDevice() && sliderUpdateValue != null)
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
                          sliderUpdateValue!(speed: value),
                    )
                  : SliderMobile(
                      value: scrollSpeedDevice,
                      updateValue: (double value) =>
                          sliderUpdateValue!(speed: value),
                    ),
            ),
        ],
        bottom: widget.withTabController == true && widget.tabBar != null
            ? widget.tabBar
            : null,
      );

  @override
  Widget build(BuildContext context) => withTabController
      ? DefaultTabController(
          initialIndex: 0,
          length: widget.tabLength,
          child: Scaffold(
            key: widget.scaffoldKey,
            appBar: appBarWithActions,
            drawer: widget.drawer,
            body: SafeArea(child: widget.body),
          ),
        )
      : Scaffold(
          key: widget.scaffoldKey,
          appBar: appBarWithActions,
          drawer: widget.drawer,
          body: SafeArea(child: widget.body),
        );
}
