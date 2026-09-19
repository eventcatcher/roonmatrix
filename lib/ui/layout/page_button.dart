import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/expandable_button_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class PageButton extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String label;
  final double size;
  final Icon icon;
  final bool moreInfo;
  final Widget page;
  final ExpandableMenuController? expandableMenuController;

  const PageButton({
    super.key,
    required this.navigatorKey,
    required this.label,
    required this.size,
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
  double get size => widget.size;
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
            padding: EdgeInsets.only(left: paddingLeft),
            child: ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(CircleBorder()),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: WidgetStateProperty.all(Size.zero),
                fixedSize: WidgetStateProperty.all(
                  Size.square(
                    size * Globals.mobileExpandableInnerIconSizeFactor,
                  ),
                ),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                backgroundColor: WidgetStateProperty.all(
                  moreInfo
                      ? CupertinoColors.activeOrange.color
                      : CupertinoColors.activeBlue.color,
                ), // <-- Button color
                overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.green.shade700; // <-- Splash color
                  }
                  return Colors.transparent;
                }),
              ),
              child: icon,
              onPressed: () {
                Future<void>.delayed(dialogDelayToCloseExpandedMenuBefore).then(
                  (_) {
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
                  },
                );
              },
            ),

            // CircleAvatar(
            //   radius: size / 2 * Globals.mobileExpandableInnerIconSizeFactor,
            //   backgroundColor: moreInfo
            //       ? CupertinoColors.activeOrange.color
            //       : CupertinoColors.activeBlue.color,
            //   child: IconButton(
            //     mouseCursor: SystemMouseCursors.click,
            //     padding: EdgeInsets.zero,
            //     onPressed: () {
            //       Future<void>.delayed(
            //         dialogDelayToCloseExpandedMenuBefore,
            //       ).then((_) {
            //         if (mounted && context.mounted) {
            //           SharedWidgets.openPage(
            //             context: context,
            //             navigatorKey: navigatorKey,
            //             page: page,
            //           );
            //         }
            //         if (expandableMenuController != null) {
            //           expandableMenuController!.close();
            //         }
            //       });
            //     },
            //     icon: icon,
            //   ),
            // ),
          );
  }
}
