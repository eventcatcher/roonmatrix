import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';

class CoverTextArea extends StatefulWidget {
  const CoverTextArea({
    super.key,
    required this.mainKey,
    required this.translations,
    required this.portraitMode,
    required this.threeCols,
    required this.idle,
    required this.width,
    required this.height,
    required this.selectedZone,
  });

  final GlobalKey mainKey;
  final Map<String, dynamic> translations;
  final bool portraitMode;
  final bool threeCols;
  final bool idle;
  final double width;
  final double height;

  final Map<String, dynamic>? selectedZone;

  @override
  State<CoverTextArea> createState() => _CoverTextAreaState();
}

class _CoverTextAreaState extends State<CoverTextArea> {
  GlobalKey get mainKey => widget.mainKey;
  Map<String, dynamic> get translations => widget.translations;
  bool get portraitMode => widget.portraitMode;
  bool get threeCols => widget.threeCols;
  bool get idle => widget.idle;
  double get width => widget.width;
  double get height => widget.height;
  Map<String, dynamic>? get selectedZone => widget.selectedZone;

  final double minTextAreaHeightDesktop = 128.0;
  final double minTextAreaHeightMobile = 100.0;

  Widget inner = SizedBox();
  String lastHash = '';
  String server = '';
  String? zone;
  String artist = '';
  String album = '';
  String track = '';
  String status = '';

  @override
  void initState() {
    super.initState();
    updateInner();
  }

  @override
  void didUpdateWidget(CoverTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateInner();
  }

  void updateInner() {
    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      // zone is inactive

      server = selectedZone?['server'] ?? '';
      zone = selectedZone?['zone'] ?? '';
      artist = selectedZone?['artist'] ?? '';
      album = selectedZone?['album'] ?? '';
      track = selectedZone?['track'] ?? '';
      status = selectedZone?['status'] ?? '';

      String hash = md5
          .convert(utf8.encode('$server-$zone-$artist-$album-$track-$status'))
          .toString();

      if (lastHash != hash) {
        lastHash = hash;

        inner = Container(
          key: ValueKey('Text-inactive-$hash'),
          // width: width,
          // height: height - 5,
          constraints: threeCols
              ? null
              : BoxConstraints(
                  minHeight: Globals.isMobileDevice()
                      ? minTextAreaHeightMobile
                      : minTextAreaHeightDesktop,
                  //maxHeight: height - 32,
                ),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                //margin: EdgeInsets.symmetric(horizontal: 16.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: Globals.borderRadius(),
                  color: Globals.brightness() == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  boxShadow: [
                    BoxShadow(
                      color: Globals.brightness() == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                child: AutoSizeText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${translations['coverZoneHeader'] ?? 'Zone'}: ${(server == 'roon' ? zone : server).toString().toFirstUpper}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text:
                            ' (${translations['inactive'] ?? 'inactive zone'})',
                        style: TextStyle(
                          color: Globals.brightness() == Brightness.dark
                              ? Colors.red.shade400
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  minFontSize: 2,
                  maxFontSize: Globals.adaptiveMaxFontSizeForCoverText(
                    width: width,
                  ),
                  stepGranularity: 0.5,
                  wrapWords: true,
                  style: TextStyle(
                    fontSize: Globals.adaptiveMaxFontSizeForCoverText(
                      width: width,
                    ),
                    color: Globals.brightness() == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      if (selectedZone != null &&
          selectedZone!.isNotEmpty &&
          selectedZone?['artist'] != null) {
        server = selectedZone?['server'] ?? '';
        zone = selectedZone?['zone'] ?? '';
        artist = selectedZone?['artist'] ?? '';
        album = selectedZone?['album'] ?? '';
        track = selectedZone?['track'] ?? '';
        status = selectedZone?['status'] ?? '';

        String zoneName = (server == 'roon' ? zone : server)
            .toString()
            .toFirstUpper;

        String hash = md5
            .convert(utf8.encode('$zoneName-$artist-$album-$track-$status'))
            .toString();

        if (lastHash != hash) {
          lastHash = hash;

          CoverModel coverModel = CoverModel(
            hash: hash,
            controlId: zoneName,
            zoneName: zoneName,
            isRadio: false,
            coverUrl: '',
            artist: artist,
            album: album,
            track: track,
            status: status,
          );

          inner = Container(
            key: ValueKey('Text-$hash'),
            //width: width,
            //height: height - 5,
            constraints: threeCols
                ? null
                : BoxConstraints(
                    minHeight: Globals.isMobileDevice()
                        ? minTextAreaHeightMobile
                        : minTextAreaHeightDesktop,
                    //maxHeight: height - 32,
                  ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  //margin: EdgeInsets.symmetric(horizontal: 16.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: Globals.borderRadius(),
                    color: Globals.brightness() == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Globals.brightness() == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                  child: CoverTextOverlayExtended(
                    coverModel: coverModel,
                    maxFontSize: Globals.adaptiveMaxFontSizeForCoverText(
                      width: width,
                    ),
                    color: Globals.brightness() == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    translations: translations,
                    coverRowArtist: true,
                    coverRowAlbum: true,
                    coverRowTrack: true,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: mainKey,
      child: AnimatedSwitcher(
        duration: Globals.coverSwitchDefaultFadeAnimationDuration * 0.6,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 1),
              end: Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
        child: inner,
      ),
    );
  }
}
