import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/helper/animated_list_helper.dart';
import 'package:roonmatrix/ui/layout/cover_row.dart';
import 'package:roonmatrix/ui/layout/cover_widget.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverRowAnimation extends StatefulWidget {
  final FlutterView viewData;
  final MediaQueryData mediaQueryData;
  final Orientation orientation;
  final Map<String, dynamic> translations;
  final List<String> devices;
  final String? activeDeviceIp;
  final Map<String, dynamic> info;
  final double? appBarHeight;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final bool coverRowDynamicSize;
  final bool showExportButton;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const CoverRowAnimation({
    super.key,
    required this.viewData,
    required this.mediaQueryData,
    required this.orientation,
    required this.translations,
    required this.devices,
    required this.activeDeviceIp,
    required this.info,
    required this.appBarHeight,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
    required this.coverRowDynamicSize,
    required this.showExportButton,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<CoverRowAnimation> createState() => CoverRowAnimationState();
}

class CoverRowAnimationState extends State<CoverRowAnimation>
    with TickerProviderStateMixin {
  FlutterView get viewData => widget.viewData;
  MediaQueryData get mediaQueryData => widget.mediaQueryData;
  Orientation get orientation => widget.orientation;
  Map<String, dynamic> get translations => widget.translations;
  double? get appBarHeight => widget.appBarHeight;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;
  bool get coverRowDynamicSize => widget.coverRowDynamicSize;
  bool get showExportButton => widget.showExportButton;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<AnimatedListState> coverListKey =
      GlobalKey<AnimatedListState>();
  final bool showWebCoverNotRunning =
      false; // true: show covers for inactive zones too
  final Duration coverInserDuration = const Duration(milliseconds: 1000);
  final Duration coverRemoveDuration = const Duration(milliseconds: 2000);

  Map<String, dynamic> info = {};
  List<String> devices = [];
  String? activeDeviceIp;
  List<CoverModel> coverList = [];
  double itemListHeight = 84;

  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);

    info = widget.info;
    devices = widget.devices;
    activeDeviceIp = widget.activeDeviceIp;
    refreshCovers();

    super.initState();
  }

  @override
  void didUpdateWidget(CoverRowAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    info = widget.info;
    devices = widget.devices;
    activeDeviceIp = widget.activeDeviceIp;
    refreshCovers();
  }

  void refreshCovers() {
    List<CoverModel> coverListNew =
        mainBloc.getCoversModel(showWebCoverNotRunning: showWebCoverNotRunning);
    if (kDebugMode) {
      debugPrint(
          'CoverRowAnimation/refreshCovers => coverListNew (${coverListNew.length}): ${coverListNew.map((el) => el.artist).join(',')}');
    }

    updateInCoverlist(newList: coverListNew);
  }

  void updateInCoverlist({
    required List<CoverModel> newList,
  }) {
    double coverSize = mainRepository.getCoverSize(
      viewData: viewData,
      mediaQueryData: mediaQueryData,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
      itemListHeight: itemListHeight,
    );

    List<int> indexesToRemove = [];
    List<int> indexesToAdd = [];
    newList.asMap().forEach((index, item) {
      int coverlistIndex =
          coverList.indexWhere((CoverModel el) => el.zoneName == item.zoneName);
      if (coverlistIndex == -1) {
        indexesToAdd.add(index); // add new item
      } else {
        coverList[coverlistIndex] = item; // replace existing item
      }
    });

    if (indexesToAdd.isNotEmpty) {
      AnimatedListHelper.insertMultipleAnimatedItems(
        listKey: coverListKey,
        itemList: coverList,
        startIndex: coverList.length,
        newItems: indexesToAdd.map((int idx) => newList[idx]).toList(),
        duration: coverInserDuration,
      );
    }

    coverList.asMap().forEach((index, item) {
      int newlistIndex =
          newList.indexWhere((CoverModel el) => el.zoneName == item.zoneName);
      if (newlistIndex == -1) {
        indexesToRemove.add(index); // remove old item (not found in new list)
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
          child: AnimatedSwitcher(
            duration: Globals.coverSwitchAnimatedPresetDuration,
            transitionBuilder: Globals.coverSwitchAnimatedPreset,
            child: CoverWidget(
              key: ValueKey('CoverWidget${item.hash}'),
              translations: translations,
              devices: devices,
              activeDeviceIp: activeDeviceIp,
              coverModel: item,
              coverSize: coverSize,
              coverRowDynamicSize: coverRowDynamicSize,
              showExportButton: showExportButton,
              appBarHeight: appBarHeight,
              itemListHeight: itemListHeight,
              orientation: orientation,
              coverRowArtist: coverRowArtist,
              coverRowAlbum: coverRowAlbum,
              coverRowTrack: coverRowTrack,
              minDesktopSize: minDesktopSize,
              standardDesktopSize: standardDesktopSize,
            ),
          ),
        ),
        duration: coverRemoveDuration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoverRow(
      coverListKey: coverListKey,
      mediaQueryData: mediaQueryData,
      translations: translations,
      info: info,
      devices: devices,
      activeDeviceIp: activeDeviceIp,
      coverList: coverList,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
      itemListHeight: itemListHeight,
      orientation: orientation,
      coverRowArtist: coverRowArtist,
      coverRowAlbum: coverRowAlbum,
      coverRowTrack: coverRowTrack,
      minDesktopSize: minDesktopSize,
      standardDesktopSize: standardDesktopSize,
    );
  }
}
