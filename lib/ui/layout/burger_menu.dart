import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

class BurgerMenu extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String selectedDeviceIp;
  final Map<String, dynamic> info;
  final double? navigationTop;
  final bool noPop;
  final Future<void> Function({
    required String? key,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
  })
  onClose;

  const BurgerMenu({
    super.key,
    required this.translations,
    required this.selectedDeviceIp,
    required this.info,
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
  Future<void> Function({
    required String? key,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
  })
  get onClose => widget.onClose;

  final double navigationTopFallback = 84.0;
  final double navigationTopIos = 32.0;
  final double fontSize = 16.0;

  String selectedDeviceIp = '';
  String selectedDeviceIpBefore = '';
  bool deviceSelectedAndReady = false;
  bool isMatrixDevice = false;
  Map<String, dynamic> info = {};
  List<BurgerMenuItemData> popupData = [];
  Widget menuWidget = SizedBox();

  late StreamSubscription mainStreamSubscription;
  late MainBloc mainBloc;

  @override
  void initState() {
    selectedDeviceIp = widget.selectedDeviceIp;
    info = widget.info;
    mainBloc = BlocProvider.of<MainBloc>(context);

    mainStreamSubscription = mainBloc.stream.listen((MainState mainState) {
      if (mainState is MainStateLoaded) {
        if (selectedDeviceIpBefore != mainState.selectedDeviceIp) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              setState(() {
                selectedDeviceIp = mainState.selectedDeviceIp;
                info = mainState.info;
                initPopupData();
              });
            }
          });
        }
      }
    });

    initPopupData();
    selectedDeviceIp = widget.selectedDeviceIp;

    super.initState();
  }

  void initPopupData() {
    popupData = [];

    selectedDeviceIpBefore = selectedDeviceIp;

    deviceSelectedAndReady =
        selectedDeviceIp.isNotEmpty && info[selectedDeviceIp] != null;
    isMatrixDevice =
        selectedDeviceIp.isNotEmpty &&
        info[selectedDeviceIp] != null &&
        (!(info[selectedDeviceIp] as Map<String, dynamic>).containsKey(
              'display_cover',
            ) ||
            info[selectedDeviceIp]['display_cover'] == false);

    popupData.add(
      BurgerMenuItemData(
        key: "about",
        name:
            translations['menuEntryAbout'] ??
            "About ${Globals.mainWindowTitle}",
      ),
    );

    popupData.add(
      BurgerMenuItemData(
        key: "settings",
        name: translations['menuEntrySettings'] ?? "Settings",
      ),
    );

    popupData.add(
      BurgerMenuItemData(
        key: "separator-navigation",
        name: translations['menuEntryNavigation'] ?? 'Navigation',
      ),
    );

    popupData.add(
      BurgerMenuItemData(
        key: "backToMain",
        name: translations['backToMainViewLabel'] ?? 'Back to main page',
      ),
    );

    popupData.add(
      BurgerMenuItemData(
        key: "selectDeviceBefore",
        name:
            translations['selectDeviceBeforeLabel'] ?? 'Select previous device',
      ),
    );

    popupData.add(
      BurgerMenuItemData(
        key: "selectDeviceNext",
        name: translations['selectDeviceNextLabel'] ?? 'Select next device',
      ),
    );

    if (deviceSelectedAndReady == true) {
      popupData.add(
        BurgerMenuItemData(
          key: "separator-view",
          name: translations['menuEntryView'] ?? 'View',
        ),
      );

      popupData.add(
        BurgerMenuItemData(
          key: "config",
          name: translations['configButtonText'] ?? 'Config',
        ),
      );

      popupData.add(
        BurgerMenuItemData(
          key: "control",
          name: translations['controlButtonText'] ?? 'Control',
        ),
      );

      if (isMatrixDevice == true) {
        popupData.add(
          BurgerMenuItemData(
            key: "message",
            name: translations['messageButtonText'] ?? 'Message',
          ),
        );

        popupData.add(
          BurgerMenuItemData(
            key: "liveControl",
            name: translations['liveControlButtonText'] ?? 'Live Control',
          ),
        );
      }

      popupData.add(
        BurgerMenuItemData(
          key: "monitoring",
          name: translations['infoButtonText'] ?? 'Monitoring',
        ),
      );

      popupData.add(
        BurgerMenuItemData(
          key: "log",
          name: translations['logButtonText'] ?? 'Log',
        ),
      );

      if (Globals.isDesktopDevice()) {
        popupData.add(
          BurgerMenuItemData(
            key: "miniPlayer",
            name: translations['miniPlayerPageHeaderText'] ?? 'Mini Player',
          ),
        );
      }
    }

    menuWidget = menuBuilder(popupData);
  }

  Widget menuBuilder(List<BurgerMenuItemData> popupData) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorDefs.buttonAreaBackgroundColor(context: context),
        shape: RoundedRectangleBorder(
          // borderRadius: BorderRadius.only(
          //   topRight: Radius.circular(24.0),
          //   bottomRight: Radius.circular(24.0),
          // ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (!Globals.inIosStyle())
            SizedBox(
              height: navigationTop ?? navigationTopFallback,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: ColorDefs.burgerMenuHeadlineColor(context: context),
                ),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Text(
                    translations['mainMenuHeader'] ?? 'Main menu',
                    style: TextStyle(
                      color: Globals.brightness() == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: popupData.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0.0, color: Colors.grey),
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return popupData[index].key.startsWith('separator')
                    ? Container(
                        height: 28.0,
                        color: ColorDefs.burgerMenuHeadlineColor(
                          context: context,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: Text(
                              popupData[index].name,
                              style: TextStyle(
                                color: ColorDefs.textColor(context: context),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListTile(
                        title: Text(
                          popupData[index].name,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: ColorDefs.textColor(context: context),
                          ),
                        ),
                        onTap: () async {
                          await onClose(
                            key: popupData[index].key,
                            selectedDeviceIp: selectedDeviceIp,
                            info: info,
                          );
                          if (mounted && context.mounted && !noPop) {
                            Navigator.pop(context);
                          }
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return menuWidget;
  }

  @override
  Future<void> dispose() async {
    mainStreamSubscription.cancel();

    super.dispose();
  }
}

class BurgerMenuItemData {
  String key;
  String name;

  BurgerMenuItemData({required this.key, required this.name});
}
