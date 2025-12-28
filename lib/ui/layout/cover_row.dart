import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/cover_widget.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverRow extends StatefulWidget {
  final Map<String, dynamic> translations;
  final Map<String, dynamic> info;
  final List<String> devices;
  final List<CoverModel> coverList;
  final bool coverRowDynamicSize;
  final bool showExportButton;
  final double? appBarHeight;
  final double itemListHeight;
  final Orientation orientation;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;

  const CoverRow({
    super.key,
    required this.translations,
    required this.info,
    required this.devices,
    required this.coverList,
    required this.coverRowDynamicSize,
    required this.showExportButton,
    required this.appBarHeight,
    required this.itemListHeight,
    required this.orientation,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
  });

  @override
  State<CoverRow> createState() => _CoverRowState();
}

class _CoverRowState extends State<CoverRow> {
  List<String> get devices => widget.devices;
  Map<String, dynamic> get translations => widget.translations;
  Map<String, dynamic> get info => widget.info;
  bool get coverRowDynamicSize => widget.coverRowDynamicSize;
  bool get showExportButton => widget.showExportButton;
  double? get appBarHeight => widget.appBarHeight;
  double get itemListHeight => widget.itemListHeight;
  Orientation get orientation => widget.orientation;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;

  final double minimumCoverSize = 100;
  final double smallCoverSize = 150;
  final double midCoverSize = 200;
  final double bigCoverSize = 250;
  final double exportButtonPaddingIos = 14.0;

  final int flexCoverRow = 1;
  final Color coverRowBackgroundColor = Colors.grey.shade200;
  final GlobalKey<AnimatedListState> coverListKey =
      GlobalKey<AnimatedListState>();

  late List<CoverModel> coverList;
  late MainBloc mainBloc;

  @override
  void initState() {
    super.initState();

    mainBloc = BlocProvider.of<MainBloc>(context);

    coverList = widget.coverList;
  }

  @override
  void didUpdateWidget(CoverRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    coverList = widget.coverList;
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
            child: CoverWidget(
              translations: translations,
              devices: devices,
              coverModel: coverList[index],
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

  @override
  Widget build(BuildContext context) => getCoverRow(info: info);
}
