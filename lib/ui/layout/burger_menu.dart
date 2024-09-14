import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';

class BurgerMenu extends StatefulWidget {
  final Function(String? key) onClose;

  const BurgerMenu({super.key, required this.onClose});

  @override
  BurgerMenuState createState() => BurgerMenuState();
}

class BurgerMenuState extends State<BurgerMenu> {
  late OptionsBloc optionsBloc;
  List<dynamic> popupData = [];

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    initPopupData();

    super.initState();
  }

  void initPopupData() {
    popupData = [];

    popupData.add(BurgerMenuItemData(
      key: "about",
      name: "About",
    ));

    popupData.add(BurgerMenuItemData(
      key: "settings",
      name: "Settings",
    ));
  }

  Widget menuBuilder(List<dynamic> popupData) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(
          height: 56.0,
          child: DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
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
        ...popupData.map((obj) {
          return ListTile(
            title: Text(
              obj.name,
              style: const TextStyle(fontSize: 16.0),
            ),
            onTap: () {
              widget.onClose(obj.key);
              Navigator.pop(context);
            },
          );
        })
      ],
    );
  }

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
