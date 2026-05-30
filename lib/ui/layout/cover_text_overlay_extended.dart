import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';

class CoverTextOverlayExtended extends StatefulWidget {
  final CoverModel coverModel;
  final double maxFontSize;
  final Color color;
  final Map<String, dynamic> translations;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;

  const CoverTextOverlayExtended({
    super.key,
    required this.maxFontSize,
    required this.coverModel,
    this.color = Colors.white,
    required this.translations,
    required this.coverRowArtist,
    required this.coverRowAlbum,
    required this.coverRowTrack,
  });

  @override
  State<CoverTextOverlayExtended> createState() =>
      _CoverTextOverlayExtendedState();
}

class _CoverTextOverlayExtendedState extends State<CoverTextOverlayExtended> {
  Color get color => widget.color;
  Map<String, dynamic> get translations => widget.translations;
  bool get coverRowArtist => widget.coverRowArtist;
  bool get coverRowAlbum => widget.coverRowAlbum;
  bool get coverRowTrack => widget.coverRowTrack;

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
  Widget build(BuildContext context) => AutoSizeText.rich(
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
    maxFontSize: widget.maxFontSize,
    stepGranularity: 0.5,
    wrapWords: true,
    //presetFontSizes: [18, 16, 14, 12, 10, 8],
    style: TextStyle(fontSize: widget.maxFontSize, color: color),
  );
}
