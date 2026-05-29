import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';

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

  final double maxFontSize = 18.0;
  final FontWeight fontWeight = FontWeight.w600;

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
  Widget build(BuildContext context) => Center(
    child: AutoSizeText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${translations['coverZoneHeader'] ?? 'Zone'}: ',
            style: TextStyle(fontWeight: fontWeight),
          ),
          TextSpan(
            text:
                '${coverModel.zoneName} ${coverModel.status == 'paused' ? ' (${translations['paused'] ?? 'paused'})' : ''}',
          ),
          TextSpan(text: '\n'),
          TextSpan(
            text: '${translations['coverArtistHeader'] ?? 'Artist'}: ',
            style: TextStyle(fontWeight: fontWeight),
          ),
          TextSpan(text: coverModel.artist),
          TextSpan(text: '\n'),
          TextSpan(
            text: '${translations['coverAlbumHeader'] ?? 'Album'}: ',
            style: TextStyle(fontWeight: fontWeight),
          ),
          TextSpan(text: coverModel.album),
          TextSpan(text: '\n'),
          TextSpan(
            text: '${translations['coverTrackHeader'] ?? 'Track'}: ',
            style: TextStyle(fontWeight: fontWeight),
          ),
          TextSpan(text: coverModel.track),
        ],
      ),
      maxLines: 15,
      minFontSize: 2,
      maxFontSize: maxFontSize,
      stepGranularity: 0.5,
      wrapWords: true,

      //presetFontSizes: [18, 16, 14, 12, 10, 8],
      style: TextStyle(fontSize: maxFontSize, color: color),
    ),
  );
}
