import 'package:flutter/material.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class CoverTextOverlaySmall extends StatefulWidget {
  final CoverModel coverModel;
  final double fontSizeBig;
  final double fontSizeSmall;
  final bool coverRowTrack;
  final BoxConstraints constraints;
  final Map<String, dynamic> translations;

  const CoverTextOverlaySmall({
    super.key,
    required this.coverModel,
    this.fontSizeBig = 12.0,
    this.fontSizeSmall = 9.0,
    required this.coverRowTrack,
    required this.constraints,
    required this.translations,
  });

  @override
  State<CoverTextOverlaySmall> createState() => _CoverTextOverlaySmallState();
}

class _CoverTextOverlaySmallState extends State<CoverTextOverlaySmall> {
  late CoverModel coverModel;

  @override
  void initState() {
    coverModel = widget.coverModel;

    super.initState();
  }

  @override
  void didUpdateWidget(CoverTextOverlaySmall oldWidget) {
    super.didUpdateWidget(oldWidget);

    coverModel = widget.coverModel;
  }

  @override
  Widget build(BuildContext context) => Text(
        '${widget.translations['zoneSelectionLabel'] ?? 'Zone'}: ${SharedWidgets.getZoneNameWithoutType(zoneName: coverModel.zoneName)}${widget.coverRowTrack == true && coverModel.track.isNotEmpty && widget.constraints.maxHeight > 169 ? ', ${widget.translations['coverTrackHeader'] ?? 'Track'}: ${coverModel.track}' : ''}',
        style: TextStyle(
          fontSize: widget.constraints.maxHeight > 250
              ? widget.fontSizeBig
              : widget.fontSizeSmall,
          color: Colors.white,
        ),
      );
}
