import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/control_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/helper/animated_list_helper.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

class StartPage extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final String title;

  const StartPage({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.title,
  });

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> with TickerProviderStateMixin {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  String get title => widget.title;

  final double smallCoverSize = 150;
  final double bigCoverSize = 250;
  double maxCoverSize = 150; // set to 0: cover is half of height of the window
  final double zoneTitleAreaMinHeight = 17;
  final double zoneTitleAreaHeight = 34;
  final double treeFontSize = 12;
  final double noDevicesFoundRectSize = 184;
  final int flexDevice = 1;
  final int flexCoverRow = 1;
  final Color coverRowBackgroundColor = Colors.grey.shade200;

  GlobalKey windowKey = GlobalKey();
  GlobalKey<AnimatedListState> coverListKey = GlobalKey<AnimatedListState>();
  Map<String, dynamic> info = {};
  Map<String, dynamic> translations = {};
  List<String> devices = [];

  Display? primaryDisplay;
  List<CoverModel> coverList = [];
  String aboutAppMessage = '';
  double width = 1280;
  double height = 768;

  bool translationsLoaded = false;
  bool idle = false;
  bool saveIdle = false;
  bool settingsPageLoaded = false;
  bool _isDrawerOpen = false;
  bool moreInfo = false;
  bool coverRowActiv = false;
  bool coverRowTrack = false;
  bool coverRowDynamicSize = false;

  late SettingsBloc settingsBloc;
  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String appVersionAndBuildNumber;

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

  void openAboutModal(
          {required BuildContext context,
          required String aboutAppMessage,
          required Map<String, dynamic> translations}) =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          mainBloc.openAboutModal(
              context: context,
              aboutAppMessage: aboutAppMessage,
              translations: translations);
        }
      });

  void openSettingsPage() =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await showGeneralDialog(
            context: context,
            //barrierColor: Colors.black12.withOpacity(0.6), // Background color
            barrierDismissible: false,
            barrierLabel: 'Dialog',
            transitionDuration: const Duration(milliseconds: 0),
            pageBuilder: (_, __, ___) {
              return SettingsPage(
                close: () {
                  Navigator.pop(context);
                },
              );
            },
          );
        }
      });

  getFormattedDateString(
      {required String date,
      String languageCode = 'de',
      String format = 'dd.MM.yyyy hh:mm:ss'}) {
    String formattedDate =
        DateFormat(format, languageCode).format(DateTime.parse(date));

    return formattedDate;
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.height;
    height = MediaQuery.of(context).size.height;
    // if (kDebugMode) {
    //   print(
    //       'StartPage => updateSizes, caller: $caller, width: $width, height: $height');
    // }
  }

  Map<String, dynamic>? getZoneDataForControlId(Map<String, dynamic>? info) {
    Map<String, dynamic>? zone;

    if (info != null && info != {} && info.keys.contains('channels')) {
      String? controlId = info['control_id'];
      Map<String, dynamic> channels = info['channels'];

      if (controlId != null &&
          controlId.isNotEmpty &&
          channels.keys.contains(controlId)) {
        if (channels[controlId] == 'webserver') {
          List<String> controlIdParts = info['control_id'].split('-');
          String serverName = controlIdParts[0];
          String zoneName = controlIdParts[1];
          if (info['web_playouts'][serverName] != null) {
            List<dynamic> zones = info['web_playouts'][serverName];
            zone = zones.firstWhereOrNull(
                (dynamic el) => (el['zone'] as String) == zoneName);
          }
        } else {
          String zoneName = channels[controlId];
          if (info['roon_playouts'][zoneName] != null) {
            zone = info['roon_playouts'][zoneName];
          }
        }
      }
    }

    return zone;
  }

  List<CoverModel> getCovers(Map<String, dynamic>? info) {
    List<CoverModel> covers = [];

    if (info != null && info != {}) {
      if (info.keys.isNotEmpty) {
        Map<String, dynamic> roonPlayouts =
            info[info.keys.first]['roon_playouts'];
        Map<String, dynamic> channels = info[info.keys.first]['channels'];

        for (String zoneName in roonPlayouts.keys) {
          dynamic zone = roonPlayouts[zoneName];
          String? coverUrl = zone['cover'];

          if (coverUrl != null &&
              coverUrl.isNotEmpty &&
              channels.values.contains(zoneName)) {
            CoverModel coverModel = CoverModel(
              zoneName: zoneName,
              coverUrl: coverUrl,
              track: zone['track'],
            );

            covers.add(coverModel);
          }
        }

        Map<String, dynamic> webPlayouts =
            info[info.keys.first]['web_playouts'];
        for (String serverName in webPlayouts.keys) {
          List<dynamic> zones = webPlayouts[serverName];
          for (dynamic zone in zones) {
            String zoneName = '$serverName-${zone['zone']}';
            String? coverUrl = zone['cover'];
            if (coverUrl != null &&
                coverUrl.isNotEmpty &&
                channels.keys.contains(zoneName)) {
              CoverModel coverModel = CoverModel(
                zoneName: zoneName,
                coverUrl: coverUrl,
                track: zone['track'],
              );

              covers.add(coverModel);
            }
          }
        }
      }
    }

    return covers;
  }

  Widget getCoverWidget({
    required CoverModel coverModel,
  }) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: coverRowDynamicSize
            ? null
            : BoxConstraints(
                maxWidth: maxCoverSize,
                maxHeight: maxCoverSize,
              ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // constraints.maxHeight gets the height of the AnimatedList
            double coverHeight = constraints.maxHeight;
            if (kDebugMode) {
              debugPrint('constraints.maxHeight: ${constraints.maxHeight}');
            }
            double coverWidth = coverHeight;

            return Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 1.0),
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //     color: Colors.white,
                  //     width: 1.0,
                  //   ),
                  // ),
                  width: coverWidth,
                  height: coverHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 2000),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      // transitionBuilder: (Widget child, Animation<double> animation) {
                      //   return ScaleTransition(scale: animation, child: child);
                      // },
                      child: Image.network(
                        coverModel
                            .coverUrl, // if imageUrl changed, the transition will be animated
                        key: ValueKey('CoverRow${coverModel.coverUrl}'),
                        fit: BoxFit.cover,
                        width: coverRowDynamicSize ? double.infinity : null,
                        height: coverRowDynamicSize ? double.infinity : null,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: coverWidth - 14,
                      ),
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        color: Color.fromARGB(200, 0, 0, 0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 2.0),
                        child: Text(
                          '${translations['zoneSelectionLabel'] ?? 'Zone'}: ${coverModel.zoneName}${coverRowTrack == true && constraints.maxHeight > 169 ? ', ${translations['coverTrackHeader'] ?? 'Track'}: ${coverModel.track}' : ''}',
                          style: TextStyle(
                            fontSize: constraints.maxHeight > 250 ? 12.0 : 9.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget getCoverRow(info) {
    if (kDebugMode) {
      debugPrint('getCoverRow => covers to display: ${coverList.length}');
    }

    Widget coverRowList = AnimatedList(
      key: coverListKey,
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(), // <-- pagewide scrolling
      initialItemCount: coverList.length,
      itemBuilder: (context, index, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            child: getCoverWidget(coverModel: coverList[index]),
          ),
        );
      },
    );

    final keyContext = windowKey.currentContext;
    if (keyContext != null && !coverRowDynamicSize) {
      final box = keyContext.findRenderObject() as RenderBox;
      maxCoverSize = box.size.height > 500 ? bigCoverSize : smallCoverSize;
    }

    return coverRowDynamicSize == true
        ? Expanded(
            flex: flexCoverRow,
            child: Container(
              color: coverRowBackgroundColor,
              child: coverRowList,
            ))
        : ConstrainedBox(
            constraints: BoxConstraints(
              // minHeight: 80, // <-- darf nie kleiner als 80 Pixel werden
              maxHeight: maxCoverSize, // optional: maximal 150 Pixel hoch
            ),
            child: Align(
              // <-- Flexibles Kind, das sich anpasst!
              alignment: Alignment.center,
              child: Column(
                children: [
                  // Expanded(
                  //   child: Container(),
                  // ),

                  //  Container(
                  //     constraints: BoxConstraints(
                  //       maxHeight: maxCoverSize + zoneTitleAreaHeight,
                  //     ),
                  //     child: Container(color: Colors.orange, child: coverRowList),
                  //   ),

                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      color: coverRowBackgroundColor,
                      child: coverRowList,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void itemsToRemove({required List<CoverModel> newList}) {
    List<int> indexesToRemove = [];
    coverList.asMap().forEach((index, item) {
      CoverModel? obj = newList.firstWhereOrNull((CoverModel el) =>
          el.coverUrl == item.coverUrl && el.zoneName == item.zoneName);
      if (obj == null) {
        indexesToRemove.add(index);
      }
    });

    if (indexesToRemove.isNotEmpty) {
      AnimatedListHelper.removeMultipleAnimatedItems(
        listKey: coverListKey,
        itemList: coverList,
        indexesToRemove: indexesToRemove,
        buildItem: (item, animation) => SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: animation,
          child: getCoverWidget(coverModel: item),
        ),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void itemsToAdd({required List<CoverModel> newList}) {
    List<CoverModel> newItems = [];
    newList.asMap().forEach((index, item) {
      CoverModel? obj = coverList.firstWhereOrNull((CoverModel el) =>
          el.coverUrl == item.coverUrl && el.zoneName == item.zoneName);
      if (obj == null) {
        newItems.add(item);
      }
    });

    if (newItems.isNotEmpty) {
      AnimatedListHelper.insertMultipleAnimatedItems(
        listKey: coverListKey,
        itemList: coverList,
        startIndex: coverList.length,
        newItems: newItems,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  void updateInCoverlist({required List<CoverModel> newList}) {
    final bool replace =
        false; // true: remove inactive and add new content, false: replace content

    List<int> indexesToUpdate = [];
    List<int> indexesToAdd = [];
    newList.asMap().forEach((index, item) {
      int coverlistIndex =
          coverList.indexWhere((CoverModel el) => el.zoneName == item.zoneName);
      if (coverlistIndex == -1) {
        indexesToAdd.add(index);
      } else {
        coverList[coverlistIndex] = item;
      }
    });

    if (!replace) {
      AnimatedListHelper.insertMultipleAnimatedItems(
        listKey: coverListKey,
        itemList: coverList,
        startIndex: coverList.length,
        newItems: indexesToAdd.map((int idx) => newList[idx]).toList(),
        duration: const Duration(milliseconds: 500),
      );
    }

    if (indexesToAdd.isNotEmpty) {
      coverList.asMap().forEach((index, item) {
        int newlistIndex =
            newList.indexWhere((CoverModel el) => el.zoneName == item.zoneName);
        if (newlistIndex == -1) {
          indexesToUpdate.add(index);
        }
      });

      for (int newListIndex in indexesToAdd) {
        int updateIndex = indexesToUpdate.removeLast();
        if (replace == true) {
          coverList[updateIndex] = newList[newListIndex];
        } else {
          AnimatedListHelper.removeMultipleAnimatedItems(
            listKey: coverListKey,
            itemList: coverList,
            indexesToRemove: indexesToUpdate,
            buildItem: (item, animation) => SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: animation,
              child: getCoverWidget(coverModel: item),
            ),
            duration: const Duration(seconds: 2),
          );
        }
      }
    }
  }

  openBurgerMenuItem(String? key) {
    if (key == 'about') {
      openAboutModal(
          context: context,
          aboutAppMessage: aboutAppMessage,
          translations: translations);
    }
    if (key == 'settings') {
      openSettingsPage();
    }
  }

  burgerMenuRaw(bool noPop) => BurgerMenu(
        translations: translations,
        noPop: noPop,
        onClose: (String? key) {
          setState(() => _isDrawerOpen = false);
          return openBurgerMenuItem(key);
        },
      );

  burgerMenu() => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          aboutAppMessage = translationsState.aboutAppMessage;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return const SizedBox();
        }

        return SharedWidgets.inIosStyle()
            ? burgerMenuRaw(true)
            : Drawer(
                child: burgerMenuRaw(false),
              );
      });

  String replaceCodes(String str) {
    if (str.length > 1 && str.startsWith('[') && str.endsWith(']')) {
      str = jsonDecode(str.replaceAll("'", '"')).join(
          ' '); // maybe troublemaker (should be replaced in python part on device)
      str = str.replaceAll('< ', ', ');
      str = str.replaceAll(' >', ': ');
    }

    return str;
  }

  List<Widget> mobileButtons1(orientation, i, zoneName, index) => [
        if (orientation == Orientation.portrait)
          Text('${i['playcount']}',
              softWrap: true,
              overflow: TextOverflow.fade,
              style: const TextStyle(fontSize: 9)),
        if (orientation == Orientation.landscape)
          Text(
            '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: i['time'])}\n${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'zone'}: ${i['playcount']}  ',
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontSize: 11),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return ConfigPage(
                    name: i['name'],
                    ip: devices[index],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return ControlPage(
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.control_camera,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return MessagePage(
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.message_outlined,
                color: Colors.white,
                size: 19.0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => showGeneralDialog(
                context: context,
                // barrierColor: Colors
                //     .black12
                //     .withOpacity(0.6), // Background color
                barrierDismissible: false,
                barrierLabel: 'Dialog',
                transitionDuration: const Duration(milliseconds: 0),
                pageBuilder: (_, __, ___) {
                  return LiveControlPage(
                    ip: devices[index],
                    name: i['name'],
                    close: () {
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              icon: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ];

  List<Widget> mobileButtons2(orientation, i, zoneName, index) => [
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showGeneralDialog(
                  context: context,
                  // barrierColor: Colors
                  //     .black12
                  //     .withOpacity(0.6), // Background color
                  barrierDismissible: false,
                  barrierLabel: 'Dialog',
                  transitionDuration: const Duration(milliseconds: 0),
                  pageBuilder: (_, __, ___) {
                    return InfoPage(
                      name: i['name'],
                      ip: devices[index],
                      close: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showGeneralDialog(
                  context: context,
                  // barrierColor: Colors
                  //     .black12
                  //     .withOpacity(0.6), // Background color
                  barrierDismissible: false,
                  barrierLabel: 'Dialog',
                  transitionDuration: const Duration(milliseconds: 0),
                  pageBuilder: (_, __, ___) {
                    return LogPage(
                      name: i['name'],
                      ip: devices[index],
                      close: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                icon: const Icon(
                  Icons.terminal,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ];

  body() => BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (translationsState is! TranslationsStateLoaded ||
            !translationsLoaded) {
          return const SizedBox();
        }

        return BlocBuilder(
            bloc: settingsBloc,
            builder: (context, SettingsState settingsState) {
              if (settingsState is! SettingsStateLoaded) {
                return SizedBox();
              }

              moreInfo = settingsState.moreInfo;
              coverRowActiv = settingsState.coverRowActiv;
              coverRowTrack = settingsState.coverRowTrack;
              coverRowDynamicSize = settingsState.coverRowDynamicSize;

              return BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    if (mainState is! MainStateLoaded) {
                      return SizedBox();
                    }

                    if ((mainState.ipStart == null ||
                            mainState.ipEnd == null) &&
                        !settingsPageLoaded) {
                      settingsPageLoaded = true;
                      openSettingsPage();
                    }

                    devices = mainState.devices;
                    info = mainState.info;
                    idle = mainState.idle;

                    if (mainState.searchFilter.isNotEmpty &&
                        devices.isNotEmpty) {
                      devices = devices
                          .where((String el) => (info[el]['name'] as String)
                              .toLowerCase()
                              .contains(
                                  (mainState.searchFilter['main'] as String)
                                      .toLowerCase()))
                          .toList();
                    }

                    // devices = [
                    //   // enable this to test with multiple fake-devices
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices,
                    //   ...devices
                    // ];

                    List<CoverModel> coverListNew = getCovers(info);
                    if (coverListNew.length != coverList.length) {
                      itemsToRemove(newList: coverListNew);
                      itemsToAdd(newList: coverListNew);
                    } else {
                      updateInCoverlist(newList: coverListNew);
                    }

                    if (kDebugMode) {
                      print(
                          'state changed => rebuild, devices: ${devices.length}, idle: $idle');
                    }
                    return OrientationBuilder(builder:
                        (BuildContext context, Orientation orientation) {
                      return Container(
                        key: windowKey,
                        color: SharedWidgets.windowBackgroundColor(
                            context: context),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Stack(
                                children: [
                                  // searchfield area
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8.0, right: 8.0),
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      direction: Axis.horizontal,
                                      children: [
                                        SearchField(
                                          type: 'main',
                                          controller:
                                              mainBloc.getSearchController(
                                                  type: 'main'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (mainState.logMessage.isNotEmpty)
                                SizedBox(
                                  height: 300.0,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(
                                                SharedWidgets.inIosStyle()
                                                    ? 8
                                                    : 5)),
                                      ),
                                      color: Colors.lightBlueAccent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                translations['debugMessage'] ??
                                                    'Debug Messages:',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListView(
                                                children: [
                                                  Text(mainState.logMessage),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                flex: flexDevice,
                                child: idle == true
                                    ? LoadingIndicatorBig(
                                        message: translations['scanMessage'] ??
                                            'scan for devices')
                                    : devices.isEmpty
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  mainBloc
                                                      .getSearchController(
                                                          type: 'main')
                                                      .clear();
                                                  mainBloc.setSearchFilter(
                                                      type: 'main', filter: '');
                                                  mainBloc.searching(
                                                      idle: true);
                                                },
                                                child: Container(
                                                  width: noDevicesFoundRectSize,
                                                  height:
                                                      noDevicesFoundRectSize,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.deepOrange,
                                                      width: 5.0,
                                                    ),
                                                    borderRadius: BorderRadius
                                                        .all(Radius.circular(
                                                            SharedWidgets
                                                                    .inIosStyle()
                                                                ? 8
                                                                : 5)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.deepOrange
                                                            .withValues(
                                                                alpha: 0.15),
                                                        spreadRadius: 0,
                                                        blurRadius: 0,
                                                      ),
                                                    ],
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Center(
                                                    child: Text(
                                                      translations[
                                                              'scanNoFoundMessage'] ??
                                                          'no devices found',
                                                      style: TextStyle(
                                                        color: SharedWidgets
                                                            .textColor(
                                                                context:
                                                                    context),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ListView.separated(
                                            key: ValueKey(
                                                'deviceList${devices.length}'),
                                            separatorBuilder:
                                                (context, index) =>
                                                    const Divider(
                                                      color: Colors.white,
                                                      height: 1,
                                                    ),
                                            itemCount: devices.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              dynamic i = info[devices[index]];

                                              String zoneName = '';
                                              if (i['control_id'] != null) {
                                                String controlId =
                                                    i['control_id'];
                                                if (i['channels'] != null &&
                                                    i['channels'][controlId] !=
                                                        null) {
                                                  if (i['channels']
                                                          [controlId] ==
                                                      'webserver') {
                                                    zoneName = controlId;
                                                  } else {
                                                    zoneName = i['channels']
                                                        [controlId];
                                                  }
                                                }
                                              }

                                              Map<String, dynamic>? zone =
                                                  getZoneDataForControlId(i);
                                              String? coverUrl = zone != null &&
                                                      zone['cover'] != null &&
                                                      (zone['cover'] as String)
                                                          .isNotEmpty
                                                  ? zone['cover']
                                                  : null;

                                              return Container(
                                                color: SharedWidgets
                                                    .tileBackgroundColor(
                                                        context: context),
                                                height: Platform.isAndroid &&
                                                        orientation ==
                                                            Orientation
                                                                .portrait &&
                                                        moreInfo == true
                                                    ? 100
                                                    : 83.0,
                                                child: Stack(
                                                  children: [
                                                    ListTile(
                                                      minLeadingWidth: 28,
                                                      tileColor: Colors
                                                          .lightBlueAccent,
                                                      iconColor: Colors.black,
                                                      textColor: SharedWidgets
                                                          .textColor(
                                                              context: context),
                                                      leading: SizedBox(
                                                        width: 40,
                                                        height: 40,
                                                        child: IconButton(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          onPressed: () =>
                                                              showGeneralDialog(
                                                            context: context,
                                                            // barrierColor: Colors
                                                            //     .black12
                                                            //     .withOpacity(
                                                            //         0.6), // Background color
                                                            barrierDismissible:
                                                                false,
                                                            barrierLabel:
                                                                'Dialog',
                                                            transitionDuration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        0),
                                                            pageBuilder:
                                                                (_, __, ___) {
                                                              return CoverPage(
                                                                index: index,
                                                                name: i['name'],
                                                                ip: devices[
                                                                    index],
                                                                translations:
                                                                    translations,
                                                              );
                                                            },
                                                          ),
                                                          icon:
                                                              AnimatedSwitcher(
                                                            duration: Duration(
                                                                milliseconds:
                                                                    2000),
                                                            switchInCurve:
                                                                Curves.easeIn,
                                                            switchOutCurve:
                                                                Curves.easeOut,
                                                            child: coverUrl !=
                                                                    null
                                                                ? Image.network(
                                                                    coverUrl,
                                                                    key: ValueKey(
                                                                        'DeviceCover$coverUrl'),
                                                                  )
                                                                : SvgPicture
                                                                    .asset(
                                                                    'assets/svg/8-8-led-matrix-display-unit.svg',
                                                                    allowDrawingOutsideViewBox:
                                                                        false,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    clipBehavior:
                                                                        Clip.hardEdge,
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        i['name'],
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        style: (Platform
                                                                    .isMacOS ||
                                                                Platform
                                                                    .isWindows ||
                                                                Platform
                                                                    .isLinux)
                                                            ? const TextStyle(
                                                                fontSize: 16.0)
                                                            : const TextStyle(
                                                                fontSize: 14.0),
                                                      ),
                                                      subtitle: Text(
                                                        devices[index],
                                                        softWrap: false,
                                                        maxLines: 1,
                                                        style: (Platform
                                                                    .isMacOS ||
                                                                Platform
                                                                    .isWindows ||
                                                                Platform
                                                                    .isLinux)
                                                            ? const TextStyle(
                                                                fontSize: 13.0)
                                                            : const TextStyle(
                                                                fontSize: 11.0),
                                                      ),
                                                      isThreeLine: true,
                                                      trailing: Platform.isMacOS ||
                                                              Platform
                                                                  .isWindows ||
                                                              Platform.isLinux
                                                          ? Row(
                                                              // desktop variant
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: i['time'])}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                                                                  softWrap:
                                                                      true,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .fade,
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'configButtonText'] ??
                                                                        'Config',
                                                                    noBackground:
                                                                        false,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .settings,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return ConfigPage(
                                                                          name:
                                                                              i['name'],
                                                                          ip: devices[
                                                                              index],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'controlButtonText'] ??
                                                                        'Control',
                                                                    noBackground:
                                                                        false,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .control_camera,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return ControlPage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'messageButtonText'] ??
                                                                        'Message',
                                                                    noBackground:
                                                                        false,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .message_outlined,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return MessagePage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                  child:
                                                                      IconButtonElement(
                                                                    label: translations[
                                                                            'liveControlButtonText'] ??
                                                                        'Live Control',
                                                                    noBackground:
                                                                        false,
                                                                    withCircle:
                                                                        true,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .visibility_outlined,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return LiveControlPage(
                                                                          ip: devices[
                                                                              index],
                                                                          name:
                                                                              i['name'],
                                                                          close:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (moreInfo ==
                                                                    true)
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        IconButtonElement(
                                                                      label: translations[
                                                                              'infoButtonText'] ??
                                                                          'Monitoring',
                                                                      noBackground:
                                                                          false,
                                                                      withCircle:
                                                                          true,
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .info_outline,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      moreInfo:
                                                                          true,
                                                                      onPressed:
                                                                          () =>
                                                                              showGeneralDialog(
                                                                        context:
                                                                            context,
                                                                        // barrierColor: Colors
                                                                        //     .black12
                                                                        //     .withOpacity(0.6), // Background color
                                                                        barrierDismissible:
                                                                            false,
                                                                        barrierLabel:
                                                                            'Dialog',
                                                                        transitionDuration:
                                                                            const Duration(milliseconds: 0),
                                                                        pageBuilder: (_,
                                                                            __,
                                                                            ___) {
                                                                          return InfoPage(
                                                                            name:
                                                                                i['name'],
                                                                            ip: devices[index],
                                                                            close:
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (moreInfo ==
                                                                    true)
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8.0),
                                                                    child:
                                                                        IconButtonElement(
                                                                      label: translations[
                                                                              'logButtonText'] ??
                                                                          'Log',
                                                                      noBackground:
                                                                          false,
                                                                      withCircle:
                                                                          true,
                                                                      icon: Icon(
                                                                          Icons
                                                                              .terminal,
                                                                          color:
                                                                              Colors.white),
                                                                      moreInfo:
                                                                          true,
                                                                      onPressed:
                                                                          () =>
                                                                              showGeneralDialog(
                                                                        context:
                                                                            context,
                                                                        // barrierColor: Colors
                                                                        //     .black12
                                                                        //     .withOpacity(0.6), // Background color
                                                                        barrierDismissible:
                                                                            false,
                                                                        barrierLabel:
                                                                            'Dialog',
                                                                        transitionDuration:
                                                                            const Duration(milliseconds: 0),
                                                                        pageBuilder: (_,
                                                                            __,
                                                                            ___) {
                                                                          return LogPage(
                                                                            name:
                                                                                i['name'],
                                                                            ip: devices[index],
                                                                            close:
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            )
                                                          : orientation ==
                                                                      Orientation
                                                                          .portrait &&
                                                                  moreInfo ==
                                                                      true
                                                              ? Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        ...mobileButtons1(
                                                                            orientation,
                                                                            i,
                                                                            zoneName,
                                                                            index)
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8.0),
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        ...mobileButtons2(
                                                                            orientation,
                                                                            i,
                                                                            zoneName,
                                                                            index)
                                                                      ],
                                                                    )
                                                                  ],
                                                                )
                                                              : Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    ...mobileButtons1(
                                                                        orientation,
                                                                        i,
                                                                        zoneName,
                                                                        index),
                                                                    ...mobileButtons2(
                                                                        orientation,
                                                                        i,
                                                                        zoneName,
                                                                        index),
                                                                  ],
                                                                ),
                                                    ),
                                                    Positioned(
                                                        top: 60,
                                                        child: InkWell(
                                                          onTap: () =>
                                                              showGeneralDialog(
                                                            context: context,
                                                            // barrierColor: Colors
                                                            //     .black12
                                                            //     .withOpacity(
                                                            //         0.6), // Background color
                                                            barrierDismissible:
                                                                false,
                                                            barrierLabel:
                                                                'Dialog',
                                                            transitionDuration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        0),
                                                            pageBuilder:
                                                                (_, __, ___) {
                                                              return ScrollMatrixPage(
                                                                index: index,
                                                                name: i['name'],
                                                                translations:
                                                                    translations,
                                                                minDesktopSize:
                                                                    minDesktopSize,
                                                                close: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16.0),
                                                            child: NotificationListener<
                                                                SizeChangedLayoutNotification>(
                                                              onNotification:
                                                                  (notification) {
                                                                updateSizes(
                                                                    'NotificationListener');
                                                                build(context);
                                                                return false;
                                                              },
                                                              child:
                                                                  SizeChangedLayoutNotifier(
                                                                child: SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width -
                                                                      (orientation == Orientation.portrait &&
                                                                              moreInfo == true
                                                                          ? 130
                                                                          : 30),
                                                                  key: ValueKey(
                                                                      'TextScrollWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                  child:
                                                                      TextScroll(
                                                                    '${replaceCodes(i['displaystr'] ?? '')}    ////    ',
                                                                    key: ValueKey(
                                                                        'TextScroll-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                    style:
                                                                        TextStyle(
                                                                      color: SharedWidgets.textColor(
                                                                          context:
                                                                              context),
                                                                    ),
                                                                    fadedBorder:
                                                                        true,
                                                                    fadeBorderSide:
                                                                        FadeBorderSide
                                                                            .right,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ))
                                                  ],
                                                ),
                                              );
                                            }),
                              ),
                              if (devices.isNotEmpty && coverRowActiv == true)
                                getCoverRow(info),
                              if (SharedWidgets.inIosStyle())
                                const SizedBox(height: 14.0),
                              if (height > minDesktopSize.height + 75)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: Platform.isMacOS ||
                                              Platform.isWindows ||
                                              Platform.isLinux
                                          ? 16.0
                                          : 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconTextButtonElement(
                                        onMacAsText: true,
                                        icon: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Icon(
                                            Icons.download,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                        label:
                                            translations['exportButtonText'] ??
                                                'export',
                                        onPressed: saveIdle == true ||
                                                idle == true ||
                                                devices.isEmpty
                                            ? null
                                            : () async {
                                                setState(() {
                                                  saveIdle = true;
                                                });
                                                bool? valid = await mainBloc
                                                    .exportDevicesData();
                                                setState(() {
                                                  saveIdle = false;
                                                });
                                                if (valid == null) {
                                                  return;
                                                }

                                                SharedWidgets.showSnackBar(
                                                    // ignore: use_build_context_synchronously
                                                    context: context,
                                                    doneMessage: translations[
                                                            'exportDoneMessage'] ??
                                                        'export successfully done',
                                                    failMessage: translations[
                                                            'exportFailedMessage'] ??
                                                        'export failed!',
                                                    valid: valid);
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              if (SharedWidgets.inIosStyle())
                                const SizedBox(height: 14.0),
                            ],
                          ),
                        ),
                      );
                    });
                  });
            });
      });

  stack(BuildContext context) => Stack(
        children: <Widget>[
          body(),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
            top: 0.0,
            bottom: 0.0,
            left: _isDrawerOpen
                ? 0.0
                : -(MediaQuery.of(context).size.width / 3 * 2 + 100),
            child: Container(
              width: MediaQuery.of(context).size.width / 3 * 2,
              height: double.infinity,
              decoration: BoxDecoration(
                color: SharedWidgets.windowBackgroundColor(context: context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 5.0,
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: height,
                    color:
                        Colors.transparent, // background color of burger menu
                    child: Stack(
                      children: <Widget>[
                        burgerMenu(),
                        Positioned(
                          top: 14.0,
                          left: 10.0,
                          child: GestureDetector(
                            onTap: () => setState(() => _isDrawerOpen = false),
                            child: Icon(
                              CupertinoIcons.clear,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: SharedWidgets.brightness(),
            middle: Text(title),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child:
                  Icon(Icons.menu, color: _isDrawerOpen ? Colors.grey : null),
              onPressed: () =>
                  _isDrawerOpen ? null : setState(() => _isDrawerOpen = true),
            ),
          ),
          child: SafeArea(
            child: stack(context),
          ),
        ),
      );
    }
    return SharedWidgets.inMacosStyle()
        ? MacosScaffold(
            toolBar: ToolBar(
              title: Center(child: Text(title)),
              titleWidth: 1000.0,
              actions: [
                const ToolBarSpacer(),
                ToolBarIconButton(
                  label: "",
                  icon: Icon(
                    FontAwesomeIcons.arrowsLeftRight,
                    size: 16.0,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
                  ),
                  onPressed: () =>
                      mainBloc.windowResizeToFullWidthAndMinimumHeight(
                          minDesktopSize: minDesktopSize),
                  showLabel: false,
                ),
                ToolBarIconButton(
                  label: "",
                  icon: Icon(
                    FontAwesomeIcons.minimize,
                    size: 16.0,
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
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
                    color: SharedWidgets.toolbarResizeButtonColor(
                        context: context),
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
                      child: body(),
                    ),
                  );
                }),
              ),
            ],
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: IconButton(
                          iconSize: 16.0,
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                                  minDesktopSize: minDesktopSize),
                          icon: Icon(
                            FontAwesomeIcons.arrowsLeftRight,
                            color: SharedWidgets.toolbarResizeButtonColor(
                                context: context),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            right: Platform.isMacOS ? 16.0 : 4.0),
                        child: IconButton(
                          iconSize: 16.0,
                          padding: EdgeInsets.zero,
                          onPressed: () => windowManager
                              .setSize(standardDesktopSize, animate: true),
                          icon: Icon(
                            FontAwesomeIcons.minimize,
                            color: SharedWidgets.toolbarResizeButtonColor(
                                context: context),
                          ),
                        ),
                      ),
                      if (Platform.isMacOS)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: IconButton(
                            iconSize: 16.0,
                            padding: EdgeInsets.zero,
                            onPressed: () => windowManager.maximize(),
                            icon: Icon(
                              FontAwesomeIcons.maximize,
                              color: SharedWidgets.toolbarResizeButtonColor(
                                  context: context),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            drawer: SharedWidgets.inIosStyle() ||
                    Platform.isAndroid ||
                    Platform.isFuchsia
                ? burgerMenu()
                : null,
            body: body());
  }
}

class MenuItem extends StatelessWidget {
  final Icon icon;
  final String label;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon.icon,
            color: Color(0xFFB42827),
          ),
          SizedBox(
            width: 8.0,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CoverModel {
  String coverUrl;
  String zoneName;
  String track;

  CoverModel({
    required this.coverUrl,
    required this.zoneName,
    required this.track,
  });
}
