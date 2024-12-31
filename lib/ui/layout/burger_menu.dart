import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class BurgerMenu extends StatefulWidget {
  final Map<String, dynamic> translations;
  final bool noPop;
  final Function(String? key) onClose;

  const BurgerMenu(
      {super.key,
      required this.translations,
      this.noPop = false,
      required this.onClose});

  @override
  BurgerMenuState createState() => BurgerMenuState();
}

class BurgerMenuState extends State<BurgerMenu> {
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
      name: widget.translations['menuEntryAbout'] ?? "About",
    ));

    popupData.add(BurgerMenuItemData(
      key: "settings",
      name: widget.translations['menuEntrySettings'] ?? "Settings",
    ));
  }

  Widget menuBuilder(List<dynamic> popupData) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: 56.0,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: SharedWidgets.inIosStyle()
                    ? CupertinoColors.systemGrey
                    : Colors.blue,
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Center(
                  child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
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
                      fontSize: 16.0,
                      color: SharedWidgets.textColor(context: context),
                    ),
                  ),
                  onTap: () {
                    widget.onClose(popupData[index].key);
                    if (!widget.noPop) {
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
