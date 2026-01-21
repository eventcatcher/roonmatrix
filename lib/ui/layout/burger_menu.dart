import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class BurgerMenu extends StatefulWidget {
  final Map<String, dynamic> translations;
  final double? navigationTop;
  final bool noPop;
  final Function(String? key) onClose;

  const BurgerMenu({
    super.key,
    required this.translations,
    required this.navigationTop,
    this.noPop = false,
    required this.onClose,
  });

  @override
  BurgerMenuState createState() => BurgerMenuState();
}

class BurgerMenuState extends State<BurgerMenu> {
  Map<String, dynamic> get translations => widget.translations;
  double? get navigationTop => widget.navigationTop;
  bool get noPop => widget.noPop;
  Function(String? key) get onClose => widget.onClose;

  final double navigationTopFallback = 84.0;
  final double navigationTopIos = 32.0;
  final double fontSize = 16.0;

  List<dynamic> popupData = [];

  @override
  void initState() {
    initPopupData();

    super.initState();
  }

  void initPopupData() {
    popupData = [];

    popupData.add(BurgerMenuItemData(
      key: "about",
      name: translations['menuEntryAbout'] ??
          "About ${SharedWidgets.mainWindowTitle}",
    ));

    popupData.add(BurgerMenuItemData(
      key: "settings",
      name: translations['menuEntrySettings'] ?? "Settings",
    ));
  }

  Widget menuBuilder(List<dynamic> popupData) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: SharedWidgets.inIosStyle()
                ? navigationTopIos
                : navigationTop ?? navigationTopFallback,
            child: SharedWidgets.inIosStyle()
                ? Container(
                    decoration: BoxDecoration(
                      color: SharedWidgets.bugerMenuHeadlineColor(
                          context: context),
                    ),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    child: Center(
                        child: Text(
                      translations['mainMenuHeader'] ?? 'Main menu',
                      style: TextStyle(color: Colors.white, fontSize: fontSize),
                    )),
                  )
                : DrawerHeader(
                    decoration: BoxDecoration(
                      color: SharedWidgets.bugerMenuHeadlineColor(
                          context: context),
                    ),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    child: Center(
                        child: Text(
                      translations['mainMenuHeader'] ?? 'Main menu',
                      style: TextStyle(color: Colors.white, fontSize: fontSize),
                    )),
                  ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: popupData.length,
              separatorBuilder: (context, index) => const Divider(
                height: 0.0,
                color: Colors.grey,
              ),
              padding: EdgeInsets.zero,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    popupData[index].name,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: SharedWidgets.textColor(context: context),
                    ),
                  ),
                  onTap: () {
                    onClose(popupData[index].key);
                    if (!noPop) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return menuBuilder(popupData);
  }
}

class BurgerMenuItemData {
  String key;
  String name;

  BurgerMenuItemData({required this.key, required this.name});
}
