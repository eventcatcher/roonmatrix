import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class CoverTextOverlayExtended extends StatefulWidget {
  final CoverModel coverModel;
  final double fontSize;
  final Color color;
  final Map<String, dynamic> translations;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final bool longText;

  const CoverTextOverlayExtended({
    super.key,
    required this.coverModel,
    this.fontSize = 12.0,
    this.color = Colors.white,
    required this.translations,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
    this.longText = false,
  });

  @override
  State<CoverTextOverlayExtended> createState() =>
      _CoverTextOverlayExtendedState();
}

class _CoverTextOverlayExtendedState extends State<CoverTextOverlayExtended> {
  double get fontSize => widget.fontSize;
  Color get color => widget.color;
  Map<String, dynamic> get translations => widget.translations;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;
  bool get longText => widget.longText;

  late CoverModel coverModel;

  @override
  void initState() {
    coverModel = widget.coverModel;

    super.initState();
  }

  @override
  void didUpdateWidget(CoverTextOverlayExtended oldWidget) {
    super.didUpdateWidget(oldWidget);

    coverModel = widget.coverModel;
  }

  @override
  Widget build(BuildContext context) => Table(
        columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
        children: [
          SharedWidgets.getTableRowFormatted(
            label: '${translations['coverZoneHeader'] ?? 'Zone'}: ',
            text: coverModel.zoneName,
            fontSize: fontSize,
            color: color,
            maxLines: longText ? 1 : 2,
          ),
          if (coverRowArtist == true)
            SharedWidgets.getTableRowFormatted(
              label: '${translations['coverArtistHeader'] ?? 'Artist'}: ',
              text: coverModel.artist,
              fontSize: fontSize,
              color: color,
              maxLines: longText ? 2 : 5,
            ),
          if (coverRowAlbum == true)
            SharedWidgets.getTableRowFormatted(
              label: '${translations['coverAlbumHeader'] ?? 'Album'}: ',
              text: coverModel.album,
              fontSize: fontSize,
              color: color,
              maxLines: longText ? 3 : 5,
            ),
          if (coverRowTrack == true && coverModel.track.isNotEmpty)
            SharedWidgets.getTableRowFormatted(
              label: '${translations['coverTrackHeader'] ?? 'Track'}: ',
              text: coverModel.track,
              fontSize: fontSize,
              color: color,
              maxLines: longText ? 3 : 5,
            ),
        ],
      );
}
