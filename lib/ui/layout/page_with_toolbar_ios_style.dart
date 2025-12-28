import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/slider_expandable.dart';
import 'package:roonmatrix/ui/layout/slider_mobile.dart';

class PageWithToolbarIosStyle extends StatefulWidget {
  final String title;
  final bool showExpandableSpeedSlider;
  final double scrollSpeedDevice;
  final AnimationController animationController;
  final bool isDrawerOpen;
  final Widget body;
  final VoidCallback resizeToFullWidth;
  final Function({required double height}) setAppBarHeight;
  final Function({required double speed}) sliderUpdateValue;
  final Function({required bool open}) setDrawerState;

  const PageWithToolbarIosStyle({
    super.key,
    required this.title,
    required this.showExpandableSpeedSlider,
    required this.scrollSpeedDevice,
    required this.animationController,
    required this.isDrawerOpen,
    required this.body,
    required this.resizeToFullWidth,
    required this.setAppBarHeight,
    required this.sliderUpdateValue,
    required this.setDrawerState,
  });

  @override
  State<PageWithToolbarIosStyle> createState() =>
      _PageWithToolbarIosStyleState();
}

class _PageWithToolbarIosStyleState extends State<PageWithToolbarIosStyle> {
  bool get showExpandableSpeedSlider => widget.showExpandableSpeedSlider;
  double get scrollSpeedDevice => widget.scrollSpeedDevice;
  AnimationController get animationController => widget.animationController;
  Function({required double speed}) get sliderUpdateValue =>
      widget.sliderUpdateValue;
  Function({required double height}) get setAppBarHeight =>
      widget.setAppBarHeight;
  Function({required bool open}) get setDrawerState => widget.setDrawerState;

  late ObstructingPreferredSizeWidget appBarWithActions;
  late bool isDrawerOpen;

  @override
  void initState() {
    isDrawerOpen = widget.isDrawerOpen;
    appBarWithActions = getAppBar();
    double appBarHeight = appBarWithActions.preferredSize.height;
    setAppBarHeight(height: appBarHeight);

    super.initState();
  }

  @override
  void didUpdateWidget(PageWithToolbarIosStyle oldWidget) {
    super.didUpdateWidget(oldWidget);

    isDrawerOpen = widget.isDrawerOpen;
    appBarWithActions = getAppBar();
    double appBarHeight = appBarWithActions.preferredSize.height;
    setAppBarHeight(height: appBarHeight);
  }

  ObstructingPreferredSizeWidget getAppBar() => CupertinoNavigationBar(
        key: ValueKey('navigationBar-$isDrawerOpen'),
        brightness: SharedWidgets.brightness(),
        middle: Text(widget.title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: AnimatedIcon(
              icon: AnimatedIcons.menu_close, progress: animationController),
          onPressed: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
              setDrawerState(open: isDrawerOpen);
              isDrawerOpen
                  ? animationController.forward()
                  : animationController.reverse();
            });
          },
        ),
        trailing: SharedWidgets.inIosStyle()
            ? Container(
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
              )
            : null,
      );

  @override
  Widget build(BuildContext context) => Material(
        child: CupertinoPageScaffold(
          navigationBar: appBarWithActions,
          child: widget.body,
        ),
      );
}
