import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/slider_expandable.dart';
import 'package:roonmatrix/ui/layout/slider_mobile.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class PageWithToolbarIosStyle extends StatefulWidget {
  final String title;
  final String activeSliderIp;
  final double sliderDefaultValue;
  final bool showExpandableSpeedSlider;
  final double scrollSpeedDevice;
  final AnimationController animationController;
  final bool isDrawerOpen;
  final Widget body;
  final Function({required double height}) setAppBarHeight;
  final Function({required double speed})? sliderUpdateValue;
  final Function({required bool open}) setDrawerState;

  const PageWithToolbarIosStyle({
    super.key,
    required this.title,
    required this.activeSliderIp,
    required this.sliderDefaultValue,
    required this.showExpandableSpeedSlider,
    required this.scrollSpeedDevice,
    required this.animationController,
    required this.isDrawerOpen,
    required this.body,
    required this.setAppBarHeight,
    this.sliderUpdateValue,
    required this.setDrawerState,
  });

  @override
  State<PageWithToolbarIosStyle> createState() =>
      _PageWithToolbarIosStyleState();
}

class _PageWithToolbarIosStyleState extends State<PageWithToolbarIosStyle> {
  String get title => widget.title;
  String get activeSliderIp => widget.activeSliderIp;
  double get sliderDefaultValue => widget.sliderDefaultValue;
  bool get showExpandableSpeedSlider => widget.showExpandableSpeedSlider;
  double get scrollSpeedDevice => widget.scrollSpeedDevice;
  AnimationController get animationController => widget.animationController;
  Widget get body => widget.body;
  Function({required double height}) get setAppBarHeight =>
      widget.setAppBarHeight;
  Function({required double speed})? get sliderUpdateValue =>
      widget.sliderUpdateValue;
  Function({required bool open}) get setDrawerState => widget.setDrawerState;

  String get sliderName =>
      activeSliderIp.isNotEmpty && mainBloc.state.info[activeSliderIp] != null
          ? mainBloc.state.info[activeSliderIp]['name']
          : activeSliderIp;

  late MainBloc mainBloc;
  late ObstructingPreferredSizeWidget appBarWithActions;
  late bool isDrawerOpen;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
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
        brightness: Globals.brightness(),
        middle: Text(title),
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
        trailing: Globals.inIosStyle() && sliderUpdateValue != null
            ? Container(
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
                    : Column(
                        children: [
                          SliderMobile(
                            min: Globals.sliderMinValue,
                            max: Globals.sliderMaxValue,
                            defaultValue: sliderDefaultValue,
                            value: scrollSpeedDevice,
                            updateValue: (double value) =>
                                sliderUpdateValue!(speed: value),
                          ),
                          Text(
                            sliderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
              )
            : null,
      );

  @override
  Widget build(BuildContext context) => Material(
        child: CupertinoPageScaffold(
          navigationBar: appBarWithActions,
          child: body,
        ),
      );
}
