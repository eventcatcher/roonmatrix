import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class PageButton extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String label;
  final Icon icon;
  final bool moreInfo;
  final Widget page;
  final ExpandableMenuController? expandableMenuController;

  const PageButton({
    super.key,
    required this.navigatorKey,
    required this.label,
    required this.icon,
    required this.moreInfo,
    required this.page,
    this.expandableMenuController,
  });

  @override
  State<PageButton> createState() => PageButtonState();
}

class PageButtonState extends State<PageButton> {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  String get label => widget.label;
  Icon get icon => widget.icon;
  bool get moreInfo => widget.moreInfo;
  Widget get page => widget.page;
  ExpandableMenuController? get expandableMenuController =>
      widget.expandableMenuController;

  final double paddingLeft = 8.0;
  final Duration dialogDelayToCloseExpandedMenuBefore = Duration(
    milliseconds: 500,
  );

  @override
  Widget build(BuildContext context) {
    return Globals.isDesktopDevice() &&
            MediaQuery.of(context).size.width >
                Globals.mobilePageButtonsMaxWidth
        ? Padding(
            padding: EdgeInsets.only(left: paddingLeft),
            child: IconButtonElement(
              label: label,
              noBackground: false,
              withCircle: true,
              icon: icon,
              moreInfo: moreInfo,
              onPressed: () => SharedWidgets.openPage(
                context: context,
                navigatorKey: navigatorKey,
                page: page,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: moreInfo
                  ? CupertinoColors.activeOrange.color
                  : CupertinoColors.activeBlue.color,
              child: IconButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                onPressed: () {
                  Future<void>.delayed(
                    dialogDelayToCloseExpandedMenuBefore,
                  ).then((_) {
                    if (mounted && context.mounted) {
                      SharedWidgets.openPage(
                        context: context,
                        navigatorKey: navigatorKey,
                        page: page,
                      );
                    }
                    if (expandableMenuController != null) {
                      expandableMenuController!.close();
                    }
                  });
                },
                icon: icon,
              ),
            ),
          );
  }
}
