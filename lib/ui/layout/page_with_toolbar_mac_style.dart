import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/macos_page_wrapper.dart';
import 'package:roonmatrix/ui/layout/macos_tappable_icon_back_button.dart';
import 'package:roonmatrix/ui/layout/macos_tappable_text_back_button.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarMacStyle extends StatefulWidget {
  final String title;
  final Size standardDesktopSize;
  final String macosVersion;
  final List<ToolbarItem>? actions;
  final Widget? additionalFullscreenTitleContent;
  final Widget body;
  final VoidCallback? backButtonPressed;
  final VoidCallback resizeToFullWidth;

  const PageWithToolbarMacStyle({
    super.key,
    required this.title,
    required this.standardDesktopSize,
    required this.macosVersion,
    this.actions,
    this.additionalFullscreenTitleContent,
    required this.body,
    this.backButtonPressed,
    required this.resizeToFullWidth,
  });

  @override
  State<PageWithToolbarMacStyle> createState() =>
      _PageWithToolbarMacStyleState();
}

class _PageWithToolbarMacStyleState extends State<PageWithToolbarMacStyle>
    with WindowListener {
  Size get standardDesktopSize => widget.standardDesktopSize;
  List<ToolbarItem>? get actions => widget.actions;
  Widget? get additionalFullscreenTitleContent =>
      widget.additionalFullscreenTitleContent;

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
    macosVersionMajor = widget.macosVersion.isNotEmpty
        ? int.parse(widget.macosVersion.split('.').first)
        : 0;

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
  Widget build(BuildContext context) => MacosPageWrapper(
        name: widget.title == 'RoonMatrix' ? null : widget.title,
        macosVersion: widget.macosVersion,
        toolBar: ToolBar(
          titleWidth: 500.0,
          title: widget.title == 'RoonMatrix'
              ? Text(widget.title)
              : MacosTappableTextBackButton(
                  text: widget.title,
                  onPressed: widget.backButtonPressed,
                ),
          leading: widget.title == 'RoonMatrix'
              ? null
              : MacosTappableIconBackButton(
                  onPressed: widget.backButtonPressed,
                ),
          actions: [
            if (actions != null && actions!.isNotEmpty) ...[
              const ToolBarSpacer(),
              ...actions!,
            ],
            if (!isFullscreen) ...[
              const ToolBarSpacer(),
              ToolBarIconButton(
                label: "",
                icon: Icon(
                  FontAwesomeIcons.arrowsLeftRight,
                  size: 16.0,
                  color:
                      SharedWidgets.toolbarResizeButtonColor(context: context),
                ),
                onPressed: () => widget.resizeToFullWidth(),
                showLabel: false,
              ),
              ToolBarIconButton(
                label: "",
                icon: Icon(
                  FontAwesomeIcons.minimize,
                  size: 16.0,
                  color:
                      SharedWidgets.toolbarResizeButtonColor(context: context),
                ),
                onPressed: () =>
                    windowManager.setSize(standardDesktopSize, animate: true),
                showLabel: false,
              ),
              ToolBarIconButton(
                label: "",
                icon: Icon(
                  FontAwesomeIcons.maximize,
                  size: 16.0,
                  color:
                      SharedWidgets.toolbarResizeButtonColor(context: context),
                ),
                onPressed: () => windowManager.maximize(),
                showLabel: false,
              ),
            ],
            const ToolBarSpacer(),
          ],
        ),
        additionalFullscreenTitleContent: additionalFullscreenTitleContent,
        body: widget.body,
      );
}
