import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/info_row.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class CoverTextOverlayExtended extends StatefulWidget {
  final CoverModel coverModel;
  final double fontSize;
  final AutoSizeGroup? group;
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
    this.group,
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [
      InfoRow(
        label: '${translations['coverZoneHeader'] ?? 'Zone'}: ',
        text:
            '${coverModel.zoneName} ${coverModel.status == 'paused' ? ' (${translations['paused'] ?? 'paused'})' : ''}',
        fontSize: fontSize,
        group: widget.group,
        color: color,
        maxLines: longText ? 1 : 2,
      ),

      InfoRow(
        label: '${translations['coverArtistHeader'] ?? 'Artist'}: ',
        text: coverModel.artist,
        fontSize: fontSize,
        group: widget.group,
        color: color,
        maxLines: longText ? 2 : 5,
      ),

      InfoRow(
        label: '${translations['coverAlbumHeader'] ?? 'Album'}: ',
        text: coverModel.album,
        fontSize: fontSize,
        group: widget.group,
        color: color,
        maxLines: longText ? 3 : 5,
      ),
      InfoRow(
        label: '${translations['coverTrackHeader'] ?? 'Track'}: ',
        text: coverModel.track,
        fontSize: fontSize,
        group: widget.group,
        color: color,
        maxLines: longText ? 3 : 5,
      ),
    ],
  );
}
