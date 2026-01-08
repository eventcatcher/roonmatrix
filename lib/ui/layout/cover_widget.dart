import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_small.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class CoverWidget extends StatefulWidget {
  final Map<String, dynamic> translations;
  final List<String> devices;
  final CoverModel coverModel;
  final double coverSize;
  final bool coverRowDynamicSize;
  final bool showExportButton;
  final double? appBarHeight;
  final double itemListHeight;
  final Orientation orientation;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const CoverWidget({
    super.key,
    required this.translations,
    required this.devices,
    required this.coverModel,
    required this.coverSize,
    required this.coverRowDynamicSize,
    required this.showExportButton,
    required this.appBarHeight,
    required this.itemListHeight,
    required this.orientation,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<CoverWidget> createState() => _CoverWidgetState();
}

class _CoverWidgetState extends State<CoverWidget> {
  List<String> get devices => widget.devices;
  Map<String, dynamic> get translations => widget.translations;
  bool get coverRowDynamicSize => widget.coverRowDynamicSize;
  bool get showExportButton => widget.showExportButton;
  double? get appBarHeight => widget.appBarHeight;
  double get itemListHeight => widget.itemListHeight;
  Orientation get orientation => widget.orientation;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  late MainBloc mainBloc;
  late double coverSize;
  late CoverModel coverModel;

  @override
  void initState() {
    super.initState();

    mainBloc = BlocProvider.of<MainBloc>(context);

    coverSize = widget.coverSize;
    coverModel = widget.coverModel;
  }

  @override
  void didUpdateWidget(CoverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    coverSize = widget.coverSize;
    coverModel = widget.coverModel;
  }

  @override
  Widget build(BuildContext context) => Align(
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
                            name: coverModel.zoneName,
                            ip: devices[0],
                            controlId: coverModel.controlId,
                            translations: translations,
                            minDesktopSize: minDesktopSize,
                            standardDesktopSize: standardDesktopSize,
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
                                          'CoverRow-${coverModel.zoneName}-${orientation.name}-${coverModel.coverUrl}'),
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
                                          colorFilter: coverModel.status !=
                                                  'playing'
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
                  Opacity(
                    opacity: 0.7,
                    child: SizedBox(
                      width: coverWidth,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Stack(
                          children: [
                            mainBloc.statusCorner(
                                size: coverWidth,
                                color: mainBloc.getZoneColor(coverModel)),
                            Positioned(
                              right: mainBloc
                                  .getZoneIconPosition(
                                      size: coverWidth, coverModel: coverModel)
                                  .dx,
                              top: mainBloc
                                  .getZoneIconPosition(
                                      size: coverWidth, coverModel: coverModel)
                                  .dy,
                              child: Center(
                                child: Image(
                                  image: AssetImage(
                                    SharedWidgets.getZoneIcon(
                                        zoneName: coverModel.zoneName),
                                  ),
                                  width: mainBloc.getZoneIconSize(
                                      size: coverWidth, coverModel: coverModel),
                                  height: mainBloc.getZoneIconSize(
                                      size: coverWidth, coverModel: coverModel),
                                ),
                              ),
                            ),
                          ],
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
                              ? CoverTextOverlayExtended(
                                  coverModel: coverModel,
                                  translations: translations,
                                  coverRowArtist: coverRowArtist,
                                  coverRowAlbum: coverRowAlbum,
                                  coverRowTrack: coverRowTrack,
                                )
                              : CoverTextOverlaySmall(
                                  coverModel: coverModel,
                                  coverRowTrack: coverRowTrack,
                                  constraints: constraints,
                                  translations: translations,
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
