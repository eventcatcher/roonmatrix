import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/helper/animated_list_helper.dart';
import 'package:roonmatrix/ui/layout/cover_row.dart';
import 'package:roonmatrix/ui/layout/cover_widget.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverRowAnimation extends StatefulWidget {
  final MediaQueryData mediaQueryData;
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
    required this.mediaQueryData,
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
  MediaQueryData get mediaQueryData => widget.mediaQueryData;
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

  AnimationController? animationController;
  Map<String, dynamic> info = {};
  List<String> devices = [];

  double? appBarHeight;
  double itemListHeight = 84;
  Orientation orientation = Orientation.portrait;
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
      double boxSizeWidth = mediaQueryData.size.width;
      double boxSizeHeight = mediaQueryData.size.height;
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
        double paddingTop = mediaQueryData.padding.top;
        double paddingBottom = mediaQueryData.padding.bottom;
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
              'yyyy CoverRowAnimation/getCoverSize => boxSizeHeight: $boxSizeHeight, paddingTop: $paddingTop, paddingBottom: $paddingBottom, exportButtonAreaHeight: $exportButtonAreaHeight, partsToSubtract: $partsToSubtract, listHeightArea: $listHeightArea, listHeightMax: $listHeightMax, preferredCoverSize: $preferredCoverSize, minNumberOfListItems: $minNumberOfListItems, listItemCount: $listItemCount, itemListHeight: $itemListHeight, coverSizeMaxPossibleOnMobile: $coverSizeMaxPossibleOnMobile');
        }
      }
    }

    return coverSize;
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

    double coverSize = getCoverSize();

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

    double coverSize = getCoverSize();

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
    return OrientationBuilder(builder: (BuildContext context, Orientation o) {
      if (o != orientation) {
        orientation = o;
        // SchedulerBinding.instance.addPostFrameCallback((_) async {
        //   if (mounted) {
        //     setState(() {
        //       orientation = o;
        //     });
        //   }
        // });
      }

      return devices.isNotEmpty
          ? SizedBox(
              child: CoverRow(
                coverListKey: coverListKey,
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
              ),
            )
          : SizedBox();
    });
  }
}
