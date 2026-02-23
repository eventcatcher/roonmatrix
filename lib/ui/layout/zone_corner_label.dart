import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';

class ZoneCornerLabel extends StatefulWidget {
  final String zoneName;
  final double coverWidth;
  final bool asRoundVariant;

  const ZoneCornerLabel({
    super.key,
    required this.zoneName,
    required this.coverWidth,
    this.asRoundVariant = false,
  });

  @override
  State<ZoneCornerLabel> createState() => _ZoneCornerLabelState();
}

class _ZoneCornerLabelState extends State<ZoneCornerLabel> {
  String get zoneName => widget.zoneName;
  double get coverWidth => widget.coverWidth;
  bool get asRoundVariant => widget.asRoundVariant;

  late MainRepository mainRepository;

  @override
  void initState() {
    super.initState();

    mainRepository = RepositoryProvider.of<MainRepository>(context);
  }

  mask({required Widget child}) => asRoundVariant
      ? CircleAvatar(
          radius: 20,
          backgroundColor: mainRepository.getZoneColor(zoneName),
          child: child)
      : SizedBox(child: child);

  @override
  Widget build(BuildContext context) {
    return mask(
      child: Stack(
        children: [
          SizedBox(
            child: Align(
              alignment: asRoundVariant ? Alignment.center : Alignment.topRight,
              child: asRoundVariant
                  ? Container(
                      width: coverWidth,
                      //height: 100,
                    )
                  : mainRepository.statusCorner(
                      size: coverWidth,
                      color: mainRepository.getZoneColor(zoneName)),
            ),
          ),
          Positioned(
            right: asRoundVariant
                ? null
                : mainRepository
                    .getZoneIconPositionBySize(
                        size: coverWidth, zoneName: zoneName)
                    .dx,
            top: asRoundVariant
                ? null
                : mainRepository
                    .getZoneIconPositionBySize(
                        size: coverWidth, zoneName: zoneName)
                    .dy,
            child: Center(
              child: Image(
                image: AssetImage(
                  Globals.getZoneIcon(zoneName: zoneName),
                ),
                width: mainRepository.getZoneIconDynamicSize(
                    size: coverWidth, zoneName: zoneName),
                height: mainRepository.getZoneIconDynamicSize(
                    size: coverWidth, zoneName: zoneName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
