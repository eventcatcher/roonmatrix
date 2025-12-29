import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final Map<String, dynamic> info;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final bool coverRowDynamicSize;
  final bool showExportButton;

  const CoverRowAnimation({
    super.key,
    required this.viewData,
    required this.mediaQueryData,
    required this.orientation,
    required this.translations,
    required this.devices,
    required this.info,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
    required this.coverRowDynamicSize,
    required this.showExportButton,
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
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;
  bool get coverRowDynamicSize => widget.coverRowDynamicSize;
  bool get showExportButton => widget.showExportButton;

  final GlobalKey<AnimatedListState> coverListKey =
      GlobalKey<AnimatedListState>();
  final double minimumCoverSize = 100;
  final double smallCoverSize = 150;
  final double midCoverSize = 200;
  final double bigCoverSize = 250;
  final double exportButtonPaddingIos = 14.0;
  final bool showWebCoverNotRunning = false;
  final int flexCoverRow = 1;
  final Color coverRowBackgroundColor = Colors.grey.shade200;

  AnimationController? animationController;
  Map<String, dynamic> info = {};
  List<String> devices = [];

  double? appBarHeight;
  double itemListHeight = 84;

  List<CoverModel> coverList = [];

  bool showExpandableSpeedSlider = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    info = widget.info;
    devices = widget.devices;
    refreshCovers();

    super.initState();
  }

  @override
  void didUpdateWidget(CoverRowAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    info = widget.info;
    devices = widget.devices;
    refreshCovers();
  }

  @override
  void dispose() {
    super.dispose();
    animationController?.dispose();
  }

  void refreshCovers() {
    List<CoverModel> coverListNew = mainBloc.getCoversModel(
        info: info, showWebCoverNotRunning: showWebCoverNotRunning);
    if (kDebugMode) {
      debugPrint(
          'CoverRowAnimation/body => coverListNew (${coverListNew.length}): ${coverListNew.map((el) => el.artist).join(',')}');
    }
    if (coverListNew.length != coverList.length) {
      itemsToRemove(newList: coverListNew);
      itemsToAdd(newList: coverListNew);
    } else {
      updateInCoverlist(newList: coverListNew);
    }
  }

  void itemsToRemove({required List<CoverModel> newList}) {
    if (kDebugMode) {
      debugPrint(
          'yyyy CoverRowAnimation/itemsToRemove => newList itemsToRemove: ${newList.map((el) => el.artist)}');
      debugPrint(
          'yyyy CoverRowAnimation/itemsToRemove => coverList itemsToRemove: ${coverList.map((el) => el.artist)}');
    }
    List<int> indexesToRemove = [];
    coverList.asMap().forEach((index, item) {
      CoverModel? obj = newList.firstWhereOrNull((CoverModel el) =>
          el.coverUrl == item.coverUrl && el.zoneName == item.zoneName);
      if (obj == null) {
        indexesToRemove.add(index);
        if (kDebugMode) {
          debugPrint(
              'yyyy CoverRowAnimation/itemsToRemove => itemsToRemove: ${item.artist}');
        }
      }
    });

    double coverSize = mainBloc.getCoverSize(
      viewData: viewData,
      mediaQueryData: mediaQueryData,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
    );

    if (indexesToRemove.isNotEmpty) {
      AnimatedListHelper.removeMultipleAnimatedItems(
        listKey: coverListKey,
        itemList: coverList,
        indexesToRemove: indexesToRemove,
        buildItem: (item, animation) => SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: animation,
          child: CoverWidget(
            translations: translations,
            devices: devices,
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
          ),
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
          debugPrint('yyyy CoverRowAnimation/itemsToAdd => ${item.artist}');
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

    double coverSize = mainBloc.getCoverSize(
      viewData: viewData,
      mediaQueryData: mediaQueryData,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
    );

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
              child: CoverWidget(
                translations: translations,
                devices: devices,
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
              ),
            ),
            duration: const Duration(seconds: 2),
          );
        }
      }
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
      coverList: coverList,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
      itemListHeight: itemListHeight,
      orientation: orientation,
      coverRowArtist: coverRowArtist,
      coverRowAlbum: coverRowAlbum,
      coverRowTrack: coverRowTrack,
    );
  }
}
