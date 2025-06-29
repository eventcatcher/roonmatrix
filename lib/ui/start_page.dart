import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hovering/hovering.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/helper/animated_list_helper.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/updatable_ticker.dart';
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
  bool showExportButton = true;

  final double minimumCoverSize = 100;
  final double smallCoverSize = 150;
  final double midCoverSize = 200;
  final double bigCoverSize = 250;
  final double zoneTitleAreaMinHeight = 17;
  final double zoneTitleAreaHeight = 34;
  final double treeFontSize = 12;
  final double noDevicesFoundRectSize = 184;
  final double exportButtonPaddingIos = 14.0;
  final double deviceListCoverSize = 40.0;
  final int flexDevice = 1;
  final int flexCoverRow = 1;
  final Color coverRowBackgroundColor = Colors.grey.shade200;
  final bool showWebCoverNotRunning = false;

  GlobalKey windowKey = GlobalKey();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  AnimationController? animationController;
  GlobalKey<AnimatedListState> coverListKey = GlobalKey<AnimatedListState>();
  GlobalKey itemListKey = GlobalKey();
  Map<String, dynamic> info = {};
  Map<String, dynamic> translations = {};
  List<String> devices = [];

  ObstructingPreferredSizeWidget? iosNavigationBar;
  double? appBarHeight;
  double? navigationTop;
  Display? primaryDisplay;
  double itemListHeight = 84;
  Orientation orientation = Orientation.portrait;
  List<CoverModel> coverList = [];
  String aboutAppMessage = '';
  double width = 1280;
  double height = 768;
  double infoOpacityLevel = 1.0;
  double scrollSpeedDevice = 1.0;
  double scrollSpeedScrollMatrix = 1.0;

  bool translationsLoaded = false;
  bool idle = false;
  bool saveIdle = false;
  bool settingsPageLoaded = false;
  bool isDrawerOpen = false;
  bool moreInfo = false;
  bool coverRowActiv = false;
  bool coverRowArtist = false;
  bool coverRowAlbum = false;
  bool coverRowTrack = false;
  bool coverRowDynamicSize = false;
  bool showExpandableSpeedSlider = false;

  late SettingsBloc settingsBloc;
  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late String appVersionAndBuildNumber;

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    animationController?.dispose();
  }

  ObstructingPreferredSizeWidget navigationBar() => CupertinoNavigationBar(
        key: ValueKey('navigationBar-$isDrawerOpen'),
        brightness: SharedWidgets.brightness(),
        middle: Text(title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: AnimatedIcon(
              icon: AnimatedIcons.menu_close, progress: animationController!),
          onPressed: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
              isDrawerOpen
                  ? animationController!.forward()
                  : animationController!.reverse();
            });
          },
        ),
        trailing: SharedWidgets.inIosStyle()
            ? SizedBox(
                width: 150,
                child: showExpandableSpeedSlider
                    ? expandableSpeedSlider()
                    : speedSlider(),
              )
            : null,
      );

  Widget speedSlider() => Container(
        padding: EdgeInsets.only(top: 2.0),
        height: 38.0,
        child: Slider(
          value: scrollSpeedDevice,
          min: 0.75,
          max: 5,
          divisions: 100,
          thumbColor: Colors.red.shade700,
          activeColor: Colors.green.shade200,
          inactiveColor: Colors.grey.shade700,
          onChanged: (double value) {
            setState(() {
              scrollSpeedDevice = value;
              settingsBloc.setScrollSpeedDevice(speed: value);
            });
          },
        ),
      );

  Widget expandableSpeedSlider() => Stack(
        children: [
          Positioned(
            top: 4.0,
            right: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                    width: 236.0,
                    height: 38.0,
                    child: ExpandableMenu(
                      key: ValueKey('ExpandableMenuSpeed'),
                      width: 38.0,
                      height: 38.0,
                      animationSpeed: 400,
                      backgroundColor: SharedWidgets.buttonRowBackgroundColor(
                          context: context),
                      items: [
                        SizedBox(
                          width: 152.0,
                          child: Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Slider(
                              value: scrollSpeedDevice,
                              min: 0.75,
                              max: 5,
                              divisions: 100,
                              thumbColor: Colors.red.shade700,
                              activeColor: Colors.green.shade200,
                              inactiveColor: Colors.grey.shade700,
                              onChanged: (double value) {
                                setState(() {
                                  scrollSpeedDevice = value;
                                  settingsBloc.setScrollSpeedDevice(
                                      speed: value);
                                });
                              },
                            ),
                          ),
                        )
                      ],
                    )),
              ],
            ),
          ),
        ],
      );

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
    showExportButton = (SharedWidgets.isMobileDevice() &&
            orientation == Orientation.portrait) ||
        (SharedWidgets.isDesktopDevice() &&
            height > (minDesktopSize.height + 75));
    // if (kDebugMode) {
    //   debugPrint(
    //       'yyyy StartPage/updateSizes => caller: $caller, width: $width, height: $height');
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

  CoverModel? getRoonCoverModel({
    required Map<String, dynamic> channels,
    required String zoneName,
    required dynamic zone,
    required bool idle,
  }) {
    String? coverUrl = zone['cover'];
    if (channels.values.contains(zoneName) &&
        ((!idle && zone['status'] == 'playing') ||
            (idle == true && zone['status'] != 'playing'))) {
      String controlId =
          channels.keys.firstWhere((el) => channels[el] == zoneName);
      CoverModel coverModel = CoverModel(
        controlId: controlId,
        zoneName: zoneName,
        coverUrl: coverUrl ?? '',
        artist: zone['artist'] ?? '',
        album: zone['album'] ?? '',
        track: zone['track'] ?? '',
        status: zone['status'],
      );

      return coverModel;
    }

    return null;
  }

  CoverModel? getWebCoverModel({
    required Map<String, dynamic> channels,
    required String zoneName,
    required dynamic zone,
    required bool idle,
  }) {
    String? coverUrl = zone['cover'];
    if (channels.keys.contains(zoneName) &&
        ((!idle && zone['status'] == 'playing') ||
            (idle == true && zone['status'] == 'paused') ||
            (idle == true &&
                showWebCoverNotRunning == true &&
                zone['status'] == 'not running'))) {
      CoverModel coverModel = CoverModel(
        controlId: zoneName,
        zoneName: zoneName,
        coverUrl: coverUrl ?? '',
        artist: zone['artist'] ?? '',
        album: zone['album'] ?? '',
        track: zone['track'] ?? '',
        status: zone['status'] ?? '',
      );

      return coverModel;
    }

    return null;
  }

  List<CoverModel> getCoversModel(Map<String, dynamic>? info) {
    List<CoverModel> covers = [];

    if (info != null && info != {}) {
      if (info.keys.isNotEmpty) {
        Map<String, dynamic> roonPlayouts =
            info[info.keys.first]['roon_playouts'];
        Map<String, dynamic> channels = info[info.keys.first]['channels'];

        for (String zoneName in roonPlayouts.keys) {
          CoverModel? coverModel = getRoonCoverModel(
            channels: channels,
            zoneName: zoneName,
            zone: roonPlayouts[zoneName],
            idle: false,
          );
          if (coverModel != null) {
            covers.add(coverModel);
          }
        }

        Map<String, dynamic> webPlayouts =
            info[info.keys.first]['web_playouts'];
        for (String serverName in webPlayouts.keys) {
          List<dynamic> zones = webPlayouts[serverName];
          for (dynamic zone in zones) {
            String zoneName = '$serverName-${zone['zone']}';

            CoverModel? coverModel = getWebCoverModel(
              channels: channels,
              zoneName: zoneName,
              zone: zone,
              idle: false,
            );
            if (coverModel != null) {
              covers.add(coverModel);
            }
          }
        }

        for (String zoneName in roonPlayouts.keys) {
          CoverModel? coverModel = getRoonCoverModel(
            channels: channels,
            zoneName: zoneName,
            zone: roonPlayouts[zoneName],
            idle: true,
          );
          if (coverModel != null) {
            covers.add(coverModel);
          }
        }

        for (String serverName in webPlayouts.keys) {
          List<dynamic> zones = webPlayouts[serverName];
          for (dynamic zone in zones) {
            String zoneName = '$serverName-${zone['zone']}';

            CoverModel? coverModel = getWebCoverModel(
              channels: channels,
              zoneName: zoneName,
              zone: zone,
              idle: true,
            );
            if (coverModel != null) {
              covers.add(coverModel);
            }
          }
        }
      }
    }

    return covers;
  }

  Widget speedSliderOverlay() => HoverWidget(
      hoverChild: InkWell(
        onDoubleTap: () {
          setState(() {
            scrollSpeedDevice = 1.0;
            settingsBloc.setScrollSpeedDevice(speed: 1.0);
          });
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.ease,
          duration: const Duration(seconds: 1),
          builder: (BuildContext context, double opacity, Widget? child) {
            return Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Color.fromARGB(200, 33, 33, 33),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 9.0),
                        child: Text(
                          '${translations['speed'] ?? 'speed:'}:',
                          style: TextStyle(
                            color: SharedWidgets.borderColor(context: context),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 36.0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 9.0),
                          child: Slider(
                            value: scrollSpeedDevice,
                            min: 0.75,
                            max: 5,
                            divisions: 100,
                            thumbColor: Colors.red.shade700,
                            activeColor: Colors.green.shade200,
                            inactiveColor: Colors.grey.shade700,
                            onChanged: (double value) {
                              setState(() {
                                scrollSpeedDevice = value;
                                settingsBloc.setScrollSpeedDevice(speed: value);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          },
        ),
      ),
      onHover: (PointerEnterEvent event) {
        //
      },
      child: Container(
        width: 240,
        height: 54,
        color: Colors.transparent,
      ));

  Widget getTextArea(CoverModel coverModel) {
    final double fontSize = 12.0;

    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        TableRow(children: [
          TableCell(
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                '${translations['coverZoneHeader'] ?? 'Zone'}: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          TableCell(
            child: Text(
              coverModel.zoneName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
          ),
        ]),
        if (coverRowArtist == true)
          TableRow(children: [
            TableCell(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  '${translations['coverArtistHeader'] ?? 'Artist'}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Text(
                coverModel.artist,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        if (coverRowAlbum == true)
          TableRow(children: [
            TableCell(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  '${translations['coverAlbumHeader'] ?? 'Album'}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Text(
                coverModel.album,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        if (coverRowTrack == true && coverModel.track.isNotEmpty)
          TableRow(children: [
            TableCell(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  '${translations['coverTrackHeader'] ?? 'Track'}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Text(
                coverModel.track,
                softWrap: true,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
      ],
    );
  }

  Widget getCoverWidget({
    required CoverModel coverModel,
  }) {
    double coverSize = getCoverSize();

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: coverRowDynamicSize
            ? null
            : BoxConstraints(
                maxWidth: coverSize,
                maxHeight: coverSize,
              ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // constraints.maxHeight gets the height of the AnimatedList
            double coverHeight = constraints.maxHeight;
            double coverWidth = coverHeight;

            return Stack(
              children: [
                InkWell(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierLabel: 'Dialog',
                      transitionDuration: const Duration(milliseconds: 0),
                      pageBuilder: (_, __, ___) {
                        return CoverPage(
                          index: 0,
                          name: coverModel.zoneName,
                          ip: devices[0],
                          controlId: coverModel.controlId,
                          translations: translations,
                        );
                      },
                    );
                  },
                  child: Container(
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
                        child: coverModel.coverUrl.isNotEmpty
                            ? Stack(
                                children: [
                                  Container(
                                    key: ValueKey(
                                        'CoverRow-${orientation.name}-${coverModel.coverUrl}'),
                                    width: coverRowDynamicSize
                                        ? double.infinity
                                        : null,
                                    height: coverRowDynamicSize
                                        ? double.infinity
                                        : null,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff7c94b6),
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        colorFilter:
                                            coverModel.status != 'playing'
                                                ? ColorFilter.mode(
                                                    Colors.black
                                                        .withValues(alpha: 0.2),
                                                    BlendMode.dstATop)
                                                : null,
                                        image: NetworkImage(
                                          coverModel.coverUrl,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (coverModel.status != 'playing')
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Colors.black,
                                          size: 80.0,
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Stack(
                                children: [
                                  SvgPicture.asset(
                                    'assets/svg/8-8-led-matrix-display-unit.svg',
                                    colorFilter: ColorFilter.mode(
                                        Colors.black.withValues(alpha: 0.2),
                                        BlendMode.dstATop),
                                    allowDrawingOutsideViewBox: false,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 60.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                        child: coverHeight > 400 &&
                                (coverRowArtist == true ||
                                    coverRowAlbum == true)
                            ? getTextArea(coverModel)
                            : Text(
                                '${translations['zoneSelectionLabel'] ?? 'Zone'}: ${coverModel.zoneName}${coverRowTrack == true && coverModel.track.isNotEmpty && constraints.maxHeight > 169 ? ', ${translations['coverTrackHeader'] ?? 'Track'}: ${coverModel.track}' : ''}',
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxHeight > 250 ? 12.0 : 9.0,
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

  double getSafeHeight() {
    //Safe area paddings in logical pixels
    double paddingTop =
        View.of(context).padding.top / View.of(context).devicePixelRatio;
    double paddingBottom =
        View.of(context).padding.bottom / View.of(context).devicePixelRatio;

    //Safe area in logical pixels
    double pixelRatio = View.of(context).devicePixelRatio;
    Size logicalScreenSize = View.of(context).physicalSize / pixelRatio;
    double logicalHeight = logicalScreenSize.height;
    double safeHeight = logicalHeight - paddingTop - paddingBottom;

    return safeHeight;
  }

  double getCoverSize() {
    double coverSize = smallCoverSize;
    int minNumberOfListItems = 1;
    int minNumberOfCoversInRow = 2;

    if (!coverRowDynamicSize) {
      double boxSizeWidth = MediaQuery.of(context).size.width;
      double boxSizeHeight = MediaQuery.of(context).size.height;
      double preferredCoverSize =
          boxSizeWidth > minNumberOfCoversInRow * bigCoverSize &&
                  boxSizeHeight > minNumberOfCoversInRow * bigCoverSize
              ? bigCoverSize
              : boxSizeWidth > minNumberOfCoversInRow * midCoverSize &&
                      boxSizeHeight > minNumberOfCoversInRow * midCoverSize
                  ? midCoverSize
                  : smallCoverSize;
      if (SharedWidgets.isDesktopDevice()) {
        coverSize = preferredCoverSize;
      }

      if (SharedWidgets.isMobileDevice()) {
        double safeHeight = getSafeHeight();
        boxSizeHeight = safeHeight;

        double searchFieldAreaHeight = 44;
        double paddingTop = MediaQuery.of(context).padding.top;
        double paddingBottom = MediaQuery.of(context).padding.bottom;
        double exportButtonHeight =
            40; // height of export button (ios: CupertinoButton.filled)
        double exportButtonAreaHeight = showExportButton == true
            ? Platform.isIOS
                ? exportButtonHeight + 2 * exportButtonPaddingIos
                : 48 // height of export button (Android: ElevatedButton.icon)
            : 0;

        double partsToSubtract = (appBarHeight ?? 56) +
            searchFieldAreaHeight +
            exportButtonAreaHeight;
        double coverSizeMaxPossibleOnMobile = boxSizeHeight -
            partsToSubtract -
            minNumberOfListItems * itemListHeight;
        double listHeightArea = boxSizeHeight - partsToSubtract;
        int maxListCount = (listHeightArea / itemListHeight).floor();

        double listHeightMax = listHeightArea - preferredCoverSize;
        int listItemCount = (listHeightMax / itemListHeight).floor();
        coverSize = listHeightArea - (listItemCount * itemListHeight);
        if (listItemCount < minNumberOfListItems ||
            boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          preferredCoverSize = smallCoverSize;
          listHeightMax = listHeightArea - preferredCoverSize;
          listItemCount = (listHeightMax / itemListHeight).floor();
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }
        if (listItemCount < minNumberOfListItems ||
            boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          preferredCoverSize = smallCoverSize;
          listHeightMax = listHeightArea - preferredCoverSize;
          listItemCount = (listHeightMax / itemListHeight).ceil();
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }

        if (boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          if (listItemCount < maxListCount) {
            listItemCount += 1;
            double testCoverSize =
                listHeightArea - (listItemCount * itemListHeight);
            if (testCoverSize >= minimumCoverSize) {
              coverSize = testCoverSize;
            }
          }
        }
        if (coverSize < minimumCoverSize &&
            listItemCount > minNumberOfListItems) {
          listItemCount -= 1;
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }

        if (kDebugMode) {
          debugPrint(
              'yyyy StartPage/getCoverSize => boxSizeHeight: $boxSizeHeight, paddingTop: $paddingTop, paddingBottom: $paddingBottom, exportButtonAreaHeight: $exportButtonAreaHeight, partsToSubtract: $partsToSubtract, listHeightArea: $listHeightArea, listHeightMax: $listHeightMax, preferredCoverSize: $preferredCoverSize, minNumberOfListItems: $minNumberOfListItems, listItemCount: $listItemCount, itemListHeight: $itemListHeight, coverSizeMaxPossibleOnMobile: $coverSizeMaxPossibleOnMobile');
        }
      }
    }

    return coverSize;
  }

  Widget getCoverRow({required Map<String, dynamic> info}) {
    if (kDebugMode) {
      debugPrint(
          'yyyy StartPage/getCoverRow => covers to display: ${coverList.length}');
    }

    double coverSize = getCoverSize();

    Widget coverRowList = AnimatedList(
      key: coverListKey,
      scrollDirection: Axis.horizontal,
      physics:
          const BouncingScrollPhysics(), // PageScrollPhysics <-- pagewide scrolling
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

    return coverRowDynamicSize == true
        ? Expanded(
            flex: flexCoverRow,
            child: Container(
              color: coverRowBackgroundColor,
              child: coverRowList,
            ))
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: coverSize,
            ),
            child: Align(
              // flexible child
              alignment: Alignment.center,
              child: Column(
                children: [
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
    if (kDebugMode) {
      debugPrint(
          'yyyy StartPage/itemsToRemove => newList itemsToRemove: ${newList.map((el) => el.artist)}');
      debugPrint(
          'yyyy StartPage/itemsToRemove => coverList itemsToRemove: ${coverList.map((el) => el.artist)}');
    }
    List<int> indexesToRemove = [];
    coverList.asMap().forEach((index, item) {
      CoverModel? obj = newList.firstWhereOrNull((CoverModel el) =>
          el.coverUrl == item.coverUrl && el.zoneName == item.zoneName);
      if (obj == null) {
        indexesToRemove.add(index);
        if (kDebugMode) {
          debugPrint(
              'yyyy StartPage/itemsToRemove => itemsToRemove: ${item.artist}');
        }
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
        if (kDebugMode) {
          debugPrint('yyyy StartPage/itemsToAdd => ${item.artist}');
        }
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
        navigationTop: navigationTop,
        onClose: (String? key) {
          setState(() {
            isDrawerOpen = false;
            animationController!.reverse();
          });
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
                child: Stack(
                  children: [
                    burgerMenuRaw(false),
                    Positioned(
                      top: (navigationTop ?? 84.0) - 40,
                      left: 16.0,
                      child: InkWell(
                        onTap: () => setState(() {
                          isDrawerOpen = false;
                          scaffoldKey.currentState?.openEndDrawer();
                        }),
                        child: Icon(
                          CupertinoIcons.clear,
                          color: Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ],
                ),
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

  List<Widget> mobileButtons({
    required String zoneName,
    required String ip,
    required Map<String, dynamic> zoneData,
    required Function getExpandableMenuController,
  }) =>
      [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: CupertinoColors.activeBlue.color,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ExpandableMenuController? expandableMenuController =
                    getExpandableMenuController();

                if (expandableMenuController != null) {
                  expandableMenuController.close();
                }
                Future<void>.delayed(Duration(milliseconds: 500))
                    .then((value) => mounted
                        ? showGeneralDialog(
                            context: context,
                            // barrierColor: Colors
                            //     .black12
                            //     .withOpacity(0.6), // Background color
                            barrierDismissible: false,
                            barrierLabel: 'Dialog',
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder: (_, __, ___) {
                              return ConfigPage(
                                name: zoneData['name'],
                                ip: ip,
                                close: () {
                                  Navigator.pop(context);
                                },
                              );
                            },
                          )
                        : null);
              },
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
              onPressed: () {
                ExpandableMenuController? expandableMenuController =
                    getExpandableMenuController();

                if (expandableMenuController != null) {
                  expandableMenuController.close();
                }
                Future<void>.delayed(Duration(milliseconds: 500))
                    .then((value) => mounted
                        ? showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: 'Dialog',
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder: (_, __, ___) {
                              return CoverPage(
                                index: 0,
                                name: zoneData['name'],
                                ip: ip,
                                translations: translations,
                              );
                            },
                          )
                        : null);
              },
              icon: const Icon(
                Icons.control_camera,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!zoneData.containsKey('display_cover') ||
            zoneData['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeBlue.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  ExpandableMenuController? expandableMenuController =
                      getExpandableMenuController();

                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return MessagePage(
                                  ip: ip,
                                  name: zoneData['name'],
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.message_outlined,
                  color: Colors.white,
                  size: 19.0,
                ),
              ),
            ),
          ),
        if (!zoneData.containsKey('display_cover') ||
            zoneData['display_cover'] == false)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeBlue.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  ExpandableMenuController? expandableMenuController =
                      getExpandableMenuController();

                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return LiveControlPage(
                                  ip: ip,
                                  name: zoneData['name'],
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ];

  List<Widget> mobileButtonsForDebugging({
    required String zoneName,
    required String ip,
    required Map<String, dynamic> zoneData,
    required Function getExpandableMenuController,
  }) =>
      [
        if (moreInfo == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: CupertinoColors.activeOrange.color,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  ExpandableMenuController? expandableMenuController =
                      getExpandableMenuController();

                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return InfoPage(
                                  name: zoneData['name'],
                                  ip: ip,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
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
                onPressed: () {
                  ExpandableMenuController? expandableMenuController =
                      getExpandableMenuController();

                  if (expandableMenuController != null) {
                    expandableMenuController.close();
                  }
                  Future<void>.delayed(Duration(milliseconds: 500))
                      .then((value) => mounted
                          ? showGeneralDialog(
                              context: context,
                              // barrierColor: Colors
                              //     .black12
                              //     .withOpacity(0.6), // Background color
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return LogPage(
                                  name: zoneData['name'],
                                  ip: ip,
                                  close: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            )
                          : null);
                },
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
              coverRowArtist = settingsState.coverRowArtist;
              coverRowAlbum = settingsState.coverRowAlbum;
              coverRowTrack = settingsState.coverRowTrack;
              coverRowDynamicSize = settingsState.coverRowDynamicSize;
              scrollSpeedDevice = settingsState.scrollSpeedDevice;
              scrollSpeedScrollMatrix = settingsState.scrollSpeedScrollMatrix;

              return BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    if (kDebugMode) {
                      debugPrint(
                          'yyyy StartPage => mainState event $mainState @ ${DateTime.now().toLocal()}');
                    }
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

                    if (devices.isNotEmpty) {
                      devices = devices
                          .where((String el) =>
                              info.containsKey(el) &&
                              (info[el]['name'] as String)
                                  .toLowerCase()
                                  .contains(
                                      (mainState.searchFilter['main'] as String)
                                          .toLowerCase()))
                          .toList()
                        ..sort((String a, String b) => info.containsKey(a) &&
                                (info[a] as Map).containsKey('name')
                            ? (info[a]['name'] as String)
                                .toLowerCase()
                                .compareTo(
                                    (info[b]['name'] as String).toLowerCase())
                            : a.compareTo(b));
                    }

                    List<CoverModel> coverListNew = getCoversModel(info);
                    if (kDebugMode) {
                      debugPrint(
                          'yyyy StartPage/body => coverListNew (${coverListNew.length}): ${coverListNew.map((el) => el.artist).join(',')}');
                    }
                    if (coverListNew.length != coverList.length) {
                      itemsToRemove(newList: coverListNew);
                      itemsToAdd(newList: coverListNew);
                    } else {
                      updateInCoverlist(newList: coverListNew);
                    }

                    if (kDebugMode) {
                      debugPrint(
                          'yyyy StartPage/body => state changed => rebuild, devices: ${devices.length}, idle: $idle');
                    }
                    return OrientationBuilder(
                        builder: (BuildContext context, Orientation o) {
                      if (o != orientation) {
                        orientation = o;
                        SchedulerBinding.instance
                            .addPostFrameCallback((_) async {
                          if (mounted) {
                            setState(() {
                              orientation = o;
                            });
                          }
                        });
                      }

                      bool isSmallDeviceWidth =
                          MediaQuery.of(context).size.width < 700;

                      return Container(
                        key: windowKey,
                        color: SharedWidgets.windowBackgroundColor(
                            context: context),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              // searchfield area
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, right: 8.0),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  direction: Axis.horizontal,
                                  children: [
                                    SearchField(
                                      type: 'main',
                                      controller: mainBloc.getSearchController(
                                          type: 'main'),
                                    ),
                                  ],
                                ),
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
                                              Map<String, dynamic> i =
                                                  info[devices[index]];

                                              String scrollText = replaceCodes(
                                                  i['app_displaystr'] ?? '');
                                              String hash = md5
                                                  .convert(
                                                      utf8.encode(scrollText))
                                                  .toString();
                                              if (kDebugMode) {
                                                debugPrint(
                                                    'yyyy StartPage => new info received on index $index @ ${DateTime.now().toLocal()}), hash: $hash, scrollText: $scrollText');
                                              }

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

                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (!mounted) return;

                                                RenderBox? box;
                                                BuildContext? itemContext =
                                                    itemListKey.currentContext;
                                                if (mounted &&
                                                    itemContext != null) {
                                                  RenderObject? renderObject =
                                                      itemContext
                                                          .findRenderObject();
                                                  if (renderObject
                                                          is RenderBox &&
                                                      renderObject.attached) {
                                                    box = renderObject;
                                                  }
                                                }
                                                if (box != null) {
                                                  itemListHeight =
                                                      1 + box.size.height;
                                                }
                                              });

                                              ExpandableMenuController?
                                                  expandableMenuController;

                                              ExpandableMenuController?
                                                  getExpandableMenuController() =>
                                                      expandableMenuController;

                                              List<Widget> mobileButtonsList =
                                                  [];
                                              if (SharedWidgets
                                                  .isMobileDevice()) {
                                                mobileButtonsList = [
                                                  ...mobileButtonsForDebugging(
                                                    zoneName: zoneName,
                                                    ip: devices[index],
                                                    zoneData: i,
                                                    getExpandableMenuController:
                                                        getExpandableMenuController,
                                                  ).reversed,
                                                  ...mobileButtons(
                                                    zoneName: zoneName,
                                                    ip: devices[index],
                                                    zoneData: i,
                                                    getExpandableMenuController:
                                                        getExpandableMenuController,
                                                  ).reversed,
                                                ];
                                              }

                                              return Container(
                                                key: index == 0
                                                    ? itemListKey
                                                    : null,
                                                color: SharedWidgets
                                                    .tileBackgroundColor(
                                                        context: context),
                                                height: itemListHeight - 1,
                                                padding: EdgeInsets.only(
                                                  left: 8.0,
                                                  right: 8.0,
                                                ),
                                                child: Stack(
                                                  children: [
                                                    ListTile(
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                      tileColor: Colors
                                                          .lightBlueAccent,
                                                      iconColor: Colors.black,
                                                      textColor: SharedWidgets
                                                          .textColor(
                                                              context: context),
                                                      title: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            width:
                                                                deviceListCoverSize,
                                                            height:
                                                                deviceListCoverSize,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () =>
                                                                  showGeneralDialog(
                                                                context:
                                                                    context,
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
                                                                pageBuilder: (_,
                                                                    __, ___) {
                                                                  return CoverPage(
                                                                    index:
                                                                        index,
                                                                    name: i[
                                                                        'name'],
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
                                                                    Curves
                                                                        .easeIn,
                                                                switchOutCurve:
                                                                    Curves
                                                                        .easeOut,
                                                                child: coverUrl !=
                                                                        null
                                                                    ? Image
                                                                        .network(
                                                                        coverUrl,
                                                                        width:
                                                                            deviceListCoverSize,
                                                                        height:
                                                                            deviceListCoverSize,
                                                                        key: ValueKey(
                                                                            'DeviceCover$index$coverUrl'),
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
                                                          SizedBox(width: 8.0),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      i['name'],
                                                                      softWrap:
                                                                          false,
                                                                      maxLines:
                                                                          1,
                                                                      style: (Platform.isMacOS ||
                                                                              Platform.isWindows ||
                                                                              Platform.isLinux)
                                                                          ? const TextStyle(fontSize: 16.0)
                                                                          : const TextStyle(fontSize: 14.0),
                                                                    ),
                                                                    Text(
                                                                      devices[
                                                                          index],
                                                                      softWrap:
                                                                          false,
                                                                      maxLines:
                                                                          1,
                                                                      style: (Platform.isMacOS ||
                                                                              Platform.isWindows ||
                                                                              Platform.isLinux)
                                                                          ? const TextStyle(fontSize: 13.0)
                                                                          : const TextStyle(fontSize: 11.0),
                                                                    )
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Platform.isMacOS ||
                                                                  Platform
                                                                      .isWindows ||
                                                                  Platform
                                                                      .isLinux
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
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .fade,
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                      child:
                                                                          IconButtonElement(
                                                                        label: translations['configButtonText'] ??
                                                                            'Config',
                                                                        noBackground:
                                                                            false,
                                                                        withCircle:
                                                                            true,
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .settings,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
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
                                                                            return ConfigPage(
                                                                              name: i['name'],
                                                                              ip: devices[index],
                                                                              close: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0),
                                                                      child:
                                                                          IconButtonElement(
                                                                        label: translations['controlButtonText'] ??
                                                                            'Control',
                                                                        noBackground:
                                                                            false,
                                                                        withCircle:
                                                                            true,
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .control_camera,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                        onPressed:
                                                                            () =>
                                                                                showGeneralDialog(
                                                                          context:
                                                                              context,
                                                                          barrierDismissible:
                                                                              false,
                                                                          barrierLabel:
                                                                              'Dialog',
                                                                          transitionDuration:
                                                                              const Duration(milliseconds: 0),
                                                                          pageBuilder: (_,
                                                                              __,
                                                                              ___) {
                                                                            return CoverPage(
                                                                              index: 0,
                                                                              name: i['name'],
                                                                              ip: devices[index],
                                                                              translations: translations,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (!i.containsKey(
                                                                            'display_cover') ||
                                                                        i['display_cover'] ==
                                                                            false)
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0),
                                                                        child:
                                                                            IconButtonElement(
                                                                          label:
                                                                              translations['messageButtonText'] ?? 'Message',
                                                                          noBackground:
                                                                              false,
                                                                          withCircle:
                                                                              true,
                                                                          icon:
                                                                              Icon(
                                                                            Icons.message_outlined,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                Colors.white,
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
                                                                                const Duration(milliseconds: 0),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return MessagePage(
                                                                                ip: devices[index],
                                                                                name: i['name'],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    if (!i.containsKey(
                                                                            'display_cover') ||
                                                                        i['display_cover'] ==
                                                                            false)
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0),
                                                                        child:
                                                                            IconButtonElement(
                                                                          label:
                                                                              translations['liveControlButtonText'] ?? 'Live Control',
                                                                          noBackground:
                                                                              false,
                                                                          withCircle:
                                                                              true,
                                                                          icon:
                                                                              Icon(
                                                                            Icons.visibility_outlined,
                                                                            color:
                                                                                Colors.white,
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
                                                                                const Duration(milliseconds: 0),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return LiveControlPage(
                                                                                ip: devices[index],
                                                                                name: i['name'],
                                                                                close: () {
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
                                                                          label:
                                                                              translations['infoButtonText'] ?? 'Monitoring',
                                                                          noBackground:
                                                                              false,
                                                                          withCircle:
                                                                              true,
                                                                          icon:
                                                                              Icon(
                                                                            Icons.info_outline,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                          moreInfo:
                                                                              true,
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
                                                                                const Duration(milliseconds: 0),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return InfoPage(
                                                                                name: i['name'],
                                                                                ip: devices[index],
                                                                                close: () {
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
                                                                          label:
                                                                              translations['logButtonText'] ?? 'Log',
                                                                          noBackground:
                                                                              false,
                                                                          withCircle:
                                                                              true,
                                                                          icon: Icon(
                                                                              Icons.terminal,
                                                                              color: Colors.white),
                                                                          moreInfo:
                                                                              true,
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
                                                                                const Duration(milliseconds: 0),
                                                                            pageBuilder: (_,
                                                                                __,
                                                                                ___) {
                                                                              return LogPage(
                                                                                name: i['name'],
                                                                                ip: devices[index],
                                                                                close: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    if (isSmallDeviceWidth ==
                                                                        true)
                                                                      Padding(
                                                                        padding: EdgeInsets.only(
                                                                            top: Platform.isAndroid
                                                                                ? 14.0
                                                                                : 11.0,
                                                                            right:
                                                                                8.0),
                                                                        child: Text(
                                                                            '${i['playcount']}',
                                                                            softWrap:
                                                                                true,
                                                                            overflow:
                                                                                TextOverflow.fade,
                                                                            style: const TextStyle(fontSize: 9)),
                                                                      ),
                                                                    if (!isSmallDeviceWidth)
                                                                      AnimatedOpacity(
                                                                        opacity:
                                                                            infoOpacityLevel,
                                                                        duration:
                                                                            const Duration(milliseconds: 400),
                                                                        child:
                                                                            Text(
                                                                          '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: i['time'])}\n${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'zone'}: ${i['playcount']}  ',
                                                                          softWrap:
                                                                              true,
                                                                          maxLines:
                                                                              2,
                                                                          overflow:
                                                                              TextOverflow.fade,
                                                                          style:
                                                                              const TextStyle(fontSize: 11),
                                                                        ),
                                                                      ),
                                                                    SizedBox(
                                                                        width:
                                                                            40.0)
                                                                  ],
                                                                ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (SharedWidgets
                                                        .isMobileDevice())
                                                      Positioned(
                                                        top: Platform.isAndroid
                                                            ? 4.0
                                                            : 7.0,
                                                        right: 0.0,
                                                        child: SizedBox(
                                                          width: 100.0 +
                                                              38.0 *
                                                                  mobileButtonsList
                                                                      .length,
                                                          height: 38.0,
                                                          child: Stack(
                                                            children: [
                                                              Positioned(
                                                                top: 0.0,
                                                                left: 0.0,
                                                                right: 0.0,
                                                                child:
                                                                    ExpandableMenu(
                                                                  key: ValueKey(
                                                                      'ExpandableMenu$index-$moreInfo'),
                                                                  width: 38.0,
                                                                  height: 38.0,
                                                                  animationSpeed:
                                                                      400,
                                                                  backgroundColor:
                                                                      SharedWidgets.buttonRowBackgroundColor(
                                                                          context:
                                                                              context),
                                                                  items:
                                                                      mobileButtonsList,
                                                                  getController:
                                                                      (ExpandableMenuController
                                                                          controller) {
                                                                    expandableMenuController =
                                                                        controller;
                                                                  },
                                                                  isExpanded:
                                                                      (bool
                                                                          mode) {
                                                                    setState(
                                                                        () {
                                                                      infoOpacityLevel = mode ==
                                                                              true
                                                                          ? 0.0
                                                                          : 1.0;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
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
                                                                device: devices[
                                                                    index],
                                                                scrollSpeed:
                                                                    scrollSpeedScrollMatrix,
                                                                name: i['name'],
                                                                translations:
                                                                    translations,
                                                                minDesktopSize:
                                                                    minDesktopSize,
                                                                speedChanged:
                                                                    (double
                                                                        speed) {
                                                                  scrollSpeedScrollMatrix =
                                                                      speed;
                                                                  settingsBloc
                                                                      .setScrollSpeedScrollMatrix(
                                                                          speed:
                                                                              speed);
                                                                },
                                                                close: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              );
                                                            },
                                                          ),
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
                                                                key: ValueKey(
                                                                    'UpdatableTickerWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    16,
                                                                height: 20.0,
                                                                child:
                                                                    UpdatableTicker(
                                                                  key: ValueKey(
                                                                      'UpdatableTickerStartPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                  updatableText:
                                                                      scrollText,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'whiteCupertino subtitle',
                                                                    fontSize:
                                                                        14.0,
                                                                    color: SharedWidgets
                                                                        .textColor(
                                                                      context:
                                                                          context,
                                                                    ),
                                                                  ),
                                                                  pixelsPerSecond:
                                                                      50 *
                                                                          scrollSpeedDevice,
                                                                  forceUpdate:
                                                                      false,
                                                                  separator:
                                                                      '    ////    ',
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )),
                                                    if (SharedWidgets
                                                        .isDesktopDevice())
                                                      Positioned(
                                                        bottom: -10,
                                                        right: 0,
                                                        child:
                                                            speedSliderOverlay(),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }),
                              ),
                              if (devices.isNotEmpty && coverRowActiv == true)
                                getCoverRow(info: info),
                              if (SharedWidgets.inIosStyle() &&
                                  orientation == Orientation.portrait)
                                SizedBox(height: exportButtonPaddingIos),
                              if (showExportButton == true)
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
                              if (SharedWidgets.inIosStyle() &&
                                  orientation == Orientation.portrait)
                                SizedBox(height: exportButtonPaddingIos),
                            ],
                          ),
                        ),
                      );
                    });
                  });
            });
      });

  stack(BuildContext context) => Stack(
        children: [
          SafeArea(
            child: body(),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
            top: navigationTop,
            bottom: 0.0,
            left: isDrawerOpen ? 0 : -240,
            child: Container(
              width: 230,
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
              child: Container(
                width: double.infinity,
                height: height,
                color: Colors.transparent, // background color of burger menu
                child: TapRegion(
                  onTapOutside: (tap) {
                    setState(() {
                      isDrawerOpen = false;
                      animationController!.reverse();
                    });
                  },
                  child: burgerMenu(),
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      iosNavigationBar = navigationBar();

      appBarHeight = iosNavigationBar!.preferredSize.height;
      navigationTop = appBarHeight! + MediaQuery.of(context).padding.top;

      return Material(
        child: CupertinoPageScaffold(
          navigationBar: iosNavigationBar,
          child: stack(context),
        ),
      );
    }

    if (SharedWidgets.inMacosStyle()) {
      return MacosScaffold(
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
                color: SharedWidgets.toolbarResizeButtonColor(context: context),
              ),
              onPressed: () => mainBloc.windowResizeToFullWidthAndMinimumHeight(
                  minDesktopSize: minDesktopSize),
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
                  child: body(),
                ),
              );
            }),
          ),
        ],
      );
    }

    PreferredSizeWidget appBar = AppBar(
      title: Text(title),
      actions: [
        if (SharedWidgets.isDesktopDevice())
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
                padding: EdgeInsets.only(right: Platform.isMacOS ? 16.0 : 4.0),
                child: IconButton(
                  iconSize: 16.0,
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      windowManager.setSize(standardDesktopSize, animate: true),
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
        if (SharedWidgets.isMobileDevice())
          SizedBox(
            width: 150,
            child: showExpandableSpeedSlider
                ? expandableSpeedSlider()
                : speedSlider(),
          ),
      ],
    );

    if (Platform.isAndroid || Platform.isFuchsia) {
      appBarHeight = appBar.preferredSize.height;
      navigationTop = appBarHeight! + MediaQuery.of(context).padding.top;
    }

    return Scaffold(
        key: scaffoldKey,
        appBar: appBar,
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
  String controlId;
  String coverUrl;
  String zoneName;
  String artist;
  String album;
  String track;
  String status;

  CoverModel({
    required this.controlId,
    required this.coverUrl,
    required this.zoneName,
    required this.artist,
    required this.album,
    required this.track,
    required this.status,
  });
}
