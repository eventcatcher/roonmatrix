import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class ZoneCornerLabel extends StatefulWidget {
  final String zoneName;
  final double coverWidth;

  const ZoneCornerLabel({
    super.key,
    required this.zoneName,
    required this.coverWidth,
  });

  @override
  State<ZoneCornerLabel> createState() => _ZoneCornerLabelState();
}

class _ZoneCornerLabelState extends State<ZoneCornerLabel> {
  String get zoneName => widget.zoneName;
  double get coverWidth => widget.coverWidth;

  late MainRepository mainRepository;

  @override
  void initState() {
    super.initState();

    mainRepository = RepositoryProvider.of<MainRepository>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          child: Align(
            alignment: Alignment.topRight,
            child: mainRepository.statusCorner(
                size: coverWidth, color: mainRepository.getZoneColor(zoneName)),
          ),
        ),
        Positioned(
          right: mainRepository
              .getZoneIconPositionBySize(size: coverWidth, zoneName: zoneName)
              .dx,
          top: mainRepository
              .getZoneIconPositionBySize(size: coverWidth, zoneName: zoneName)
              .dy,
          child: Center(
            child: Image(
              image: AssetImage(
                SharedWidgets.getZoneIcon(zoneName: zoneName),
              ),
              width: mainRepository.getZoneIconDynamicSize(
                  size: coverWidth, zoneName: zoneName),
              height: mainRepository.getZoneIconDynamicSize(
                  size: coverWidth, zoneName: zoneName),
            ),
          ),
        ),
      ],
    );
  }
}
