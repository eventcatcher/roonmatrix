import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/cover_text_overlay_extended.dart';

class CoverTextArea extends StatelessWidget {
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

  final double minTextAreaHeightDesktop = 128.0;
  final double minTextAreaHeightMobile = 100.0;

  // Wraps the content into the rounded box. The key decides whether the
  // AnimatedSwitcher treats the content as new (animated) or unchanged.
  Widget textBox({required Key key, required Widget child}) {
    return Container(
      key: key,
      constraints: threeCols
          ? null
          : BoxConstraints(
              minHeight: Globals.isMobileDevice()
                  ? minTextAreaHeightMobile
                  : minTextAreaHeightDesktop,
            ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Container(
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
            child: child,
          ),
        ),
      ),
    );
  }

  Widget buildInner() {
    String server = selectedZone?['server'] ?? '';
    String zone = selectedZone?['zone'] ?? '';
    String artist = selectedZone?['artist'] ?? '';
    String album = selectedZone?['album'] ?? '';
    String track = selectedZone?['track'] ?? '';
    String status = selectedZone?['status'] ?? '';

    String zoneName = (server == 'roon' ? zone : server)
        .toString()
        .toFirstUpper;

    // Only include what is actually displayed: the status is shown just as
    // "paused" or nothing, so transitions like loading -> playing must not
    // change the key (otherwise the same text gets animated again).
    bool paused = status == 'paused';
    String hash = md5
        .convert(utf8.encode('$zoneName-$artist-$album-$track-$paused'))
        .toString();

    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      // zone is inactive, only the zone name is displayed
      return textBox(
        key: ValueKey('Text-inactive-$zoneName'),
        child: AutoSizeText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${translations['coverZoneHeader'] ?? 'Zone'}: $zoneName',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: ' (${translations['inactive'] ?? 'inactive zone'})',
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
          maxFontSize: Globals.adaptiveMaxFontSizeForCoverText(width: width),
          stepGranularity: 0.5,
          wrapWords: true,
          style: TextStyle(
            fontSize: Globals.adaptiveMaxFontSizeForCoverText(width: width),
            color: Globals.brightness() == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      );
    }

    if (selectedZone!['artist'] == null) {
      return SizedBox(key: ValueKey('Text-empty'));
    }

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

    return textBox(
      key: ValueKey('Text-$hash'),
      child: CoverTextOverlayExtended(
        coverModel: coverModel,
        maxFontSize: Globals.adaptiveMaxFontSizeForCoverText(width: width),
        color: Globals.brightness() == Brightness.dark
            ? Colors.white
            : Colors.black,
        translations: translations,
        coverRowArtist: true,
        coverRowAlbum: true,
        coverRowTrack: true,
      ),
    );
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
        child: buildInner(),
      ),
    );
  }
}
