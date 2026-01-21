import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class PageButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final double? iconSize;
  final bool moreInfo;
  final Widget page;
  final ExpandableMenuController? expandableMenuController;

  const PageButton({
    super.key,
    required this.label,
    required this.icon,
    this.iconSize,
    required this.moreInfo,
    required this.page,
    this.expandableMenuController,
  });

  @override
  State<PageButton> createState() => PageButtonState();
}

class PageButtonState extends State<PageButton> {
  String get label => widget.label;
  IconData get icon => widget.icon;
  bool get moreInfo => widget.moreInfo;
  double? get iconSize => widget.iconSize;
  Widget get page => widget.page;
  ExpandableMenuController? get expandableMenuController =>
      widget.expandableMenuController;

  final double paddingLeft = 8.0;
  final Duration dialogDelayToCloseExpandedMenuBefore =
      Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.isDesktopDevice()
        ? Padding(
            padding: EdgeInsets.only(left: paddingLeft),
            child: IconButtonElement(
              label: label,
              noBackground: false,
              withCircle: true,
              icon: Icon(icon, color: Colors.white, size: iconSize),
              moreInfo: moreInfo,
              onPressed: () => showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return page;
                },
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
                padding: EdgeInsets.zero,
                onPressed: () {
                  Future<void>.delayed(dialogDelayToCloseExpandedMenuBefore)
                      .then((_) {
                    if (mounted && context.mounted) {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: 'Dialog',
                        transitionDuration: const Duration(milliseconds: 0),
                        pageBuilder: (_, __, ___) {
                          return page;
                        },
                      );
                    }
                    if (expandableMenuController != null) {
                      expandableMenuController!.close();
                    }
                  });
                },
                icon: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          );
  }
}
