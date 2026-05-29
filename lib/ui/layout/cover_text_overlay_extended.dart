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

  final double maxFontSize = 40.0;
  String text = '';

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

    text =
        '${translations['coverZoneHeader'] ?? 'Zone'}: ${coverModel.zoneName} ${coverModel.status == 'paused' ? ' (${translations['paused'] ?? 'paused'})' : ''}';
    text += '\n';
    text +=
        '${translations['coverArtistHeader'] ?? 'Artist'}: ${coverModel.artist}';
    text += '\n';
    text +=
        '${translations['coverAlbumHeader'] ?? 'Album'}: ${coverModel.album}';
    text += '\n';
    text +=
        '${translations['coverTrackHeader'] ?? 'Track'}: ${coverModel.track}';
  }

  @override
  Widget build(BuildContext context) => Center(
    child: AutoSizeText(
      text,
      maxLines: 15,
      minFontSize: 2,
      maxFontSize: maxFontSize,
      stepGranularity: 0.5,
      wrapWords: true,
      //presetFontSizes: [18, 16, 14, 12, 10, 8],
      overflowReplacement: Text(
        text,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: maxFontSize,
        color: color,
      ),
    ),
  );
}
