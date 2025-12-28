import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';

class CoverTextOverlayExtended extends StatefulWidget {
  final CoverModel coverModel;
  final double fontSize;
  final Map<String, dynamic> translations;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;

  const CoverTextOverlayExtended({
    super.key,
    required this.coverModel,
    this.fontSize = 12.0,
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
        columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        children: [
          TableRow(children: [
            TableCell(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  '${widget.translations['coverZoneHeader'] ?? 'Zone'}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Text(
                coverModel.zoneName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
          if (widget.coverRowArtist == true)
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${widget.translations['coverArtistHeader'] ?? 'Artist'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  coverModel.artist,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          if (widget.coverRowAlbum == true)
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${widget.translations['coverAlbumHeader'] ?? 'Album'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  coverModel.album,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          if (widget.coverRowTrack == true && coverModel.track.isNotEmpty)
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${widget.translations['coverTrackHeader'] ?? 'Track'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  coverModel.track,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
        ],
      );
}
