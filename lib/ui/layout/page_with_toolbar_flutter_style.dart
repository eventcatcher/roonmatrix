import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/slider_expandable.dart';
import 'package:roonmatrix/ui/layout/slider_mobile.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarFlutterStyle extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final String activeSliderIp;
  final double sliderDefaultValue;
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
    required this.activeSliderIp,
    required this.sliderDefaultValue,
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
  GlobalKey<ScaffoldState> get scaffoldKey => widget.scaffoldKey;
  String get title => widget.title;
  String get activeSliderIp => widget.activeSliderIp;
  double get sliderDefaultValue => widget.sliderDefaultValue;
  bool get withTabController => widget.withTabController;
  int get tabLength => widget.tabLength;
  PreferredSizeWidget? get tabBar => widget.tabBar;
  List<Widget>? get actions => widget.actions;
  bool get showExpandableSpeedSlider => widget.showExpandableSpeedSlider;
  Size get standardDesktopSize => widget.standardDesktopSize;
  double get scrollSpeedDevice => widget.scrollSpeedDevice;
  Widget? get drawer => widget.drawer;
  Widget get body => widget.body;
  VoidCallback? get backButtonPressed => widget.backButtonPressed;
  VoidCallback get resizeToFullWidth => widget.resizeToFullWidth;
  Function({required double height})? get setAppBarHeight =>
      widget.setAppBarHeight;
  Function({required double speed})? get sliderUpdateValue =>
      widget.sliderUpdateValue;

  bool isFullscreen = false;

  String get sliderName =>
      activeSliderIp.isNotEmpty && mainBloc.state.info[activeSliderIp] != null
          ? mainBloc.state.info[activeSliderIp]['name']
          : activeSliderIp;

  late MainBloc mainBloc;
  late PreferredSizeWidget appBarWithActions;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);

    if (Globals.isDesktopDevice()) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        bool isFullscreenStatus = await windowManager.isFullScreen();

        if (mounted) {
          setState(() {
            isFullscreen = isFullscreenStatus;
          });
        }
      });

      windowManager.addListener(this);
    }

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
        title: Text(title),
        leading: title == Globals.mainWindowTitle
            ? null
            : BackButton(
                onPressed: () {
                  if (backButtonPressed != null) {
                    backButtonPressed!();
                  }
                  Navigator.pop(context);
                },
              ),
        actions: [
          Row(
            children: [
              if (actions != null) ...actions!,
              if (Globals.isDesktopDevice() && !isFullscreen) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    iconSize: 16.0,
                    padding: EdgeInsets.zero,
                    onPressed: () => resizeToFullWidth(),
                    icon: Icon(
                      FontAwesomeIcons.arrowsLeftRight,
                      color:
                          ColorDefs.toolbarResizeButtonColor(context: context),
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
                      color:
                          ColorDefs.toolbarResizeButtonColor(context: context),
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
                        color: ColorDefs.toolbarResizeButtonColor(
                            context: context),
                      ),
                    ),
                  ),
              ]
            ],
          ),
          if (Globals.isMobileDevice() && sliderUpdateValue != null)
            Container(
              width: showExpandableSpeedSlider ? 188.0 : 150.0,
              padding: showExpandableSpeedSlider
                  ? EdgeInsets.only(top: 5.0, right: 8.0)
                  : null,
              child: showExpandableSpeedSlider
                  ? Stack(
                      children: [
                        Positioned(
                          right: 53.0,
                          top: 18.0,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 120.0),
                            child: Text(
                              sliderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SliderExpandable(
                          width: 236.0,
                          value: scrollSpeedDevice,
                          updateValue: (double value) =>
                              sliderUpdateValue!(speed: value),
                        ),
                      ],
                    )
                  : Center(
                      child: Stack(
                        children: [
                          Positioned(
                            right: 10.0,
                            top: -1.0,
                            child: SizedBox(
                              width: 116.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sliderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliderMobile(
                            min: Globals.sliderMinValue,
                            max: Globals.sliderMaxValue,
                            defaultValue: sliderDefaultValue,
                            value: scrollSpeedDevice,
                            updateValue: (double value) =>
                                sliderUpdateValue!(speed: value),
                          ),
                        ],
                      ),
                    ),
            ),
        ],
        bottom: withTabController == true && tabBar != null ? tabBar : null,
      );

  @override
  Widget build(BuildContext context) => withTabController
      ? DefaultTabController(
          initialIndex: 0,
          length: tabLength,
          child: Scaffold(
            key: scaffoldKey,
            appBar: appBarWithActions,
            drawer: drawer,
            body: SafeArea(child: body),
          ),
        )
      : Scaffold(
          key: scaffoldKey,
          appBar: appBarWithActions,
          drawer: drawer,
          body: SafeArea(child: body),
        );
}
