import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/macos_page_wrapper.dart';
import 'package:roonmatrix/ui/layout/macos_tappable_icon_back_button.dart';
import 'package:roonmatrix/ui/layout/macos_tappable_text_back_button.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarMacStyle extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String title;
  final Size standardDesktopSize;
  final String macosVersion;
  final bool showResizeButtons;
  final List<ToolbarItem>? actions;
  final Widget? additionalFullscreenTitleContent;
  final Widget body;
  final VoidCallback? backButtonPressed;
  final VoidCallback resizeToFullWidth;

  const PageWithToolbarMacStyle({
    super.key,
    required this.translations,
    required this.title,
    required this.standardDesktopSize,
    required this.macosVersion,
    this.showResizeButtons = true,
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
  Map<String, dynamic> get translations => widget.translations;
  String get title => widget.title;
  Size get standardDesktopSize => widget.standardDesktopSize;
  String get macosVersion => widget.macosVersion;
  bool get showResizeButtons => widget.showResizeButtons;
  List<ToolbarItem>? get actions => widget.actions;
  Widget? get additionalFullscreenTitleContent =>
      widget.additionalFullscreenTitleContent;
  Widget get body => widget.body;
  VoidCallback? get backButtonPressed => widget.backButtonPressed;
  VoidCallback get resizeToFullWidth => widget.resizeToFullWidth;

  final double iconSize = 16.0;

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
    macosVersionMajor = macosVersion.isNotEmpty
        ? int.parse(macosVersion.split('.').first)
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
    name: title == Globals.mainWindowTitle ? null : title,
    macosVersion: macosVersion,
    backButtonPressed: backButtonPressed,
    toolBar: ToolBar(
      titleWidth: Globals.extendedTitleWidth,
      title: title == Globals.mainWindowTitle
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(title),
            )
          : MacosTappableTextBackButton(
              text: title,
              onPressed: backButtonPressed,
            ),
      leading: title == Globals.mainWindowTitle
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: MacosTappableIconBackButton(onPressed: backButtonPressed),
            ),
      actions: [
        if (actions != null && actions!.isNotEmpty) ...[
          const ToolBarSpacer(),
          ...actions!,
        ],
        if (!isFullscreen && showResizeButtons == true) ...[
          const ToolBarSpacer(),
          ToolBarIconButton(
            label: translations['fullWidthResizeButtonLabel'] ?? 'Full width',
            tooltipMessage:
                translations['fullWidthResizeButtonLabel'] ?? 'Full width',
            icon: FaIcon(
              FontAwesomeIcons.arrowsLeftRight,
              size: iconSize,
              color: ColorDefs.toolbarResizeButtonColor(context: context),
            ),
            onPressed: () => resizeToFullWidth(),
            showLabel: false,
          ),
          ToolBarIconButton(
            label: translations['minimizeResizeButtonLabel'] ?? 'Minimize',
            tooltipMessage:
                translations['minimizeResizeButtonLabel'] ?? 'Minimize',
            icon: Icon(
              Icons.photo_size_select_small,
              size: iconSize,
              color: ColorDefs.toolbarResizeButtonColor(context: context),
            ),
            onPressed: () => windowManager.setSize(
              Size(Globals.minDesktopWidth, Globals.minDesktopHeight + 24),
              animate: true,
            ),
            showLabel: false,
          ),
          ToolBarIconButton(
            label: translations['mediumResizeButtonLabel'] ?? 'Medium size',
            tooltipMessage:
                translations['mediumResizeButtonLabel'] ?? 'Medium size',
            icon: Icon(
              Icons.photo_size_select_large,
              size: iconSize,
              color: ColorDefs.toolbarResizeButtonColor(context: context),
            ),
            onPressed: () =>
                windowManager.setSize(standardDesktopSize, animate: true),
            showLabel: false,
          ),
          ToolBarIconButton(
            label: translations['maximizeResizeButtonLabel'] ?? 'Maximize',
            tooltipMessage:
                translations['maximizeResizeButtonLabel'] ?? 'Maximize',
            icon: Icon(
              Icons.photo_size_select_actual_outlined,
              size: iconSize,
              color: ColorDefs.toolbarResizeButtonColor(context: context),
            ),
            onPressed: () => windowManager.maximize(),
            showLabel: false,
          ),
        ],
        if (showResizeButtons == true) const ToolBarSpacer(),
      ],
    ),
    additionalFullscreenTitleContent: additionalFullscreenTitleContent,
    body: body,
  );
}
