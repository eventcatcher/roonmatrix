import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:window_manager/window_manager.dart';

class MacosPageWrapper extends StatefulWidget {
  final String? name;
  final String? macosVersion;
  final VoidCallback? backButtonPressed;
  final ToolBar? toolBar;
  final Widget? additionalFullscreenTitleContent;
  final Widget body;

  const MacosPageWrapper({
    super.key,
    this.name,
    required this.macosVersion,
    this.backButtonPressed,
    required this.toolBar,
    this.additionalFullscreenTitleContent,
    required this.body,
  });

  @override
  State<MacosPageWrapper> createState() => _MacosPageWrapperState();
}

class _MacosPageWrapperState extends State<MacosPageWrapper>
    with WindowListener {
  String? get name => widget.name;
  String? get macosVersion => widget.macosVersion;
  ToolBar? get toolBar => widget.toolBar;
  Widget? get additionalFullscreenTitleContent =>
      widget.additionalFullscreenTitleContent;
  Widget get body => widget.body;

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
    macosVersionMajor = macosVersion != null && macosVersion!.isNotEmpty
        ? int.parse((macosVersion ?? '').split('.').first)
        : 0;
    if (kDebugMode) {
      debugPrint(
          'MacosPageWrapper/initState => macosVersionMajor: $macosVersionMajor');
    }

    super.initState();
  }

  @override
  void didUpdateWidget(MacosPageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    macosVersionMajor = macosVersion != null && macosVersion!.isNotEmpty
        ? int.parse((macosVersion ?? '').split('.').first)
        : 0;
    if (kDebugMode) {
      debugPrint(
          'MacosPageWrapper/didUpdateWidget => macosVersionMajor: $macosVersionMajor');
    }
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
  Widget build(BuildContext context) => MacosWindow(
        child: MacosScaffold(
          toolBar: isFullscreen && macosVersionMajor >= 13 ? null : toolBar,
          children: [
            ContentArea(
              builder: ((context, scrollController) {
                return Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(
                      top: isFullscreen && macosVersionMajor >= 13 ? 38 : 0),
                  child: Material(
                    color: Colors.transparent,
                    child: Theme(
                      data: ThemeData(
                        useMaterial3: true,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Column(
                        children: [
                          name != null &&
                                  isFullscreen &&
                                  macosVersionMajor >= 13
                              ? Container(
                                  padding: EdgeInsets.only(left: 16.0),
                                  color: ColorDefs.toolbarBackgroundColor(
                                      context: context),
                                  height: 40.0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      MacosBackButton(
                                        fillColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        onPressed: () {
                                          if (widget.backButtonPressed !=
                                              null) {
                                            widget.backButtonPressed!();
                                          }
                                          Navigator.pop(context);
                                        },
                                        //hoverColor: MacosColors.systemBlueColor,
                                        mouseCursor: SystemMouseCursors.click,
                                      ),
                                      SizedBox(width: 4.0),
                                      InkWell(
                                        onTap: () {
                                          if (widget.backButtonPressed !=
                                              null) {
                                            widget.backButtonPressed!();
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          name!,
                                          style: TextStyle(
                                            color: ColorDefs.textColor(
                                                context: context),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (additionalFullscreenTitleContent !=
                                          null) ...[
                                        Expanded(child: SizedBox()),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child:
                                              additionalFullscreenTitleContent!,
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : SizedBox(),
                          Expanded(child: widget.body),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
}
