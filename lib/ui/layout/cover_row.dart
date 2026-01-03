import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/cover_widget.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverRow extends StatefulWidget {
  final GlobalKey<AnimatedListState> coverListKey;
  final MediaQueryData mediaQueryData;
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
    required this.coverListKey,
    required this.mediaQueryData,
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
  GlobalKey<AnimatedListState> get coverListKey => widget.coverListKey;
  MediaQueryData get mediaQueryData => widget.mediaQueryData;
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

  final int flexCoverRow = 1;
  final Color coverRowBackgroundColor = Colors.grey.shade200;

  late MainBloc mainBloc;
  late List<CoverModel> coverList;

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

  Widget getCoverRow({required Map<String, dynamic> info}) {
    if (kDebugMode) {
      debugPrint(
          'CoverRow/getCoverRow => covers to display: ${coverList.length}');
    }

    double coverSize = mainBloc.getCoverSize(
      viewData: View.of(context),
      mediaQueryData: mediaQueryData,
      coverRowDynamicSize: coverRowDynamicSize,
      showExportButton: showExportButton,
      appBarHeight: appBarHeight,
      itemListHeight: itemListHeight,
    );

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
  Widget build(BuildContext context) =>
      devices.isNotEmpty ? getCoverRow(info: info) : SizedBox();
}
