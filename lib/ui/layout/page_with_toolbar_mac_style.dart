import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:window_manager/window_manager.dart';

class PageWithToolbarMacStyle extends StatefulWidget {
  final String title;
  final Size standardDesktopSize;
  final WindowManager windowManager;
  final Widget body;
  final VoidCallback resizeToFullWidth;

  const PageWithToolbarMacStyle({
    super.key,
    required this.title,
    required this.standardDesktopSize,
    required this.windowManager,
    required this.body,
    required this.resizeToFullWidth,
  });

  @override
  State<PageWithToolbarMacStyle> createState() =>
      _PageWithToolbarMacStyleState();
}

class _PageWithToolbarMacStyleState extends State<PageWithToolbarMacStyle> {
  Size get standardDesktopSize => widget.standardDesktopSize;
  WindowManager get windowManager => widget.windowManager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(PageWithToolbarMacStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => MacosScaffold(
        toolBar: ToolBar(
          title: Center(child: Text(widget.title)),
          titleWidth: 1000.0,
          actions: [
            const ToolBarSpacer(),
            ToolBarIconButton(
              label: "",
              icon: Icon(
                FontAwesomeIcons.arrowsLeftRight,
                size: 16.0,
                color: SharedWidgets.toolbarResizeButtonColor(context: context),
              ),
              onPressed: () => widget.resizeToFullWidth(),
              showLabel: false,
            ),
            ToolBarIconButton(
              label: "",
              icon: Icon(
                FontAwesomeIcons.minimize,
                size: 16.0,
                color: SharedWidgets.toolbarResizeButtonColor(context: context),
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
                color: SharedWidgets.toolbarResizeButtonColor(context: context),
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
                child: MacosWindow(
                  child: widget.body,
                ),
              );
            }),
          ),
        ],
      );
}
