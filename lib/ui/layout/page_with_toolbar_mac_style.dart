import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarMacStyle extends StatefulWidget {
  final String title;
  final Size standardDesktopSize;
  final WindowManager windowManager;
  final String macosVersion;
  final Widget body;
  final VoidCallback resizeToFullWidth;

  const PageWithToolbarMacStyle({
    super.key,
    required this.title,
    required this.standardDesktopSize,
    required this.windowManager,
    required this.macosVersion,
    required this.body,
    required this.resizeToFullWidth,
  });

  @override
  State<PageWithToolbarMacStyle> createState() =>
      _PageWithToolbarMacStyleState();
}

class _PageWithToolbarMacStyleState extends State<PageWithToolbarMacStyle>
    with WindowListener {
  Size get standardDesktopSize => widget.standardDesktopSize;
  WindowManager get windowManager => widget.windowManager;

  bool isFullscreen = false;

  late int macosVersionMajor;

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
    macosVersionMajor = int.parse(widget.macosVersion.split('.').first);

    super.initState();
  }

  @override
  void didUpdateWidget(PageWithToolbarMacStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) => MacosScaffold(
        toolBar: isFullscreen // && macosVersionMajor < 13
            ? null
            : ToolBar(
                title: Text(widget.title),
                actions: [
                  const ToolBarSpacer(),
                  ToolBarIconButton(
                    label: "",
                    icon: Icon(
                      FontAwesomeIcons.arrowsLeftRight,
                      size: 16.0,
                      color: SharedWidgets.toolbarResizeButtonColor(
                          context: context),
                    ),
                    onPressed: () => widget.resizeToFullWidth(),
                    showLabel: false,
                  ),
                  ToolBarIconButton(
                    label: "",
                    icon: Icon(
                      FontAwesomeIcons.minimize,
                      size: 16.0,
                      color: SharedWidgets.toolbarResizeButtonColor(
                          context: context),
                    ),
                    onPressed: () => windowManager.setSize(standardDesktopSize,
                        animate: true),
                    showLabel: false,
                  ),
                  ToolBarIconButton(
                    label: "",
                    icon: Icon(
                      FontAwesomeIcons.maximize,
                      size: 16.0,
                      color: SharedWidgets.toolbarResizeButtonColor(
                          context: context),
                    ),
                    onPressed: () => windowManager.maximize(),
                    showLabel: false,
                  ),
                  const ToolBarSpacer(),
                ],
              ),
        children: [
          ContentArea(
            builder: ((context, scrollController) {
              return Material(
                //type: MaterialType.transparency,
                child: MacosWindow(
                  child: Container(
                    margin: EdgeInsets.only(top: isFullscreen ? 53 : 0),
                    child: widget.body,
                  ),
                ),
              );
            }),
          ),
        ],
      );
}
