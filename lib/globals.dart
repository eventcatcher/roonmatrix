import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/helper/cover_transition.dart';
import 'package:roonmatrix/ui/helper/cover_transition_preset.dart';

class Globals {
  static final bool showMacStyle =
      true; // show app in macos ui style (running on macos)
  static final bool showIosStyle =
      true; // show app in iOS ui style (running on macos or iOS)
  static final bool showSelectBoxInMacStyle = true;

  static final double minDesktopWidth = 398;
  static final double defaultDesktopWidth = 1280;

  static final double minDesktopHeight = Globals.getWindowMinHeight();
  static final double defaultDesktopHeight = 768;

  static final Size minDesktopSize = Size(minDesktopWidth, minDesktopHeight);
  static final Size standardDesktopSize = Size(
    defaultDesktopWidth,
    defaultDesktopHeight,
  );

  static final double maxFontSizeForCoverText = 48.0;
  static final double midFontSizeForCoverText = 24.0;
  static final double stdFontSizeForCoverText = 16.0;

  static double adaptiveMaxFontSizeForCoverText({required double width}) {
    double size = width > 700
        ? maxFontSizeForCoverText
        : width > 500
        ? midFontSizeForCoverText
        : stdFontSizeForCoverText;

    print('adaptiveMaxFontSizeForCoverText for width: $width, size: $size');
    return size;
  }

  static final String mainWindowTitle = 'Roonmatrix';

  static bool isMobileDevice() =>
      Platform.isIOS || Platform.isAndroid || Platform.isFuchsia;

  static bool isDesktopDevice() =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static bool isLinux() => Platform.isLinux;

  static bool inIosStyle() =>
      (showIosStyle == true && Platform.isIOS) ||
      (!showMacStyle && showIosStyle == true && Platform.isMacOS);

  static bool inMacosStyle() => showMacStyle == true && Platform.isMacOS;

  static bool selectBoxInMacStyle() =>
      showSelectBoxInMacStyle == true && inMacosStyle();

  static Future<String> getMacosVersion() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final MacOsDeviceInfo macosInfo = await deviceInfo.macOsInfo;
    final String version = macosInfo.osRelease
        .replaceFirst('Version', '')
        .trim();

    return version;
  }

  static Future<String> getIosVersion() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    final String version = iosInfo.systemVersion.trim();

    return version;
  }

  static Future<String> getIosModel() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    final String model = iosInfo.model;

    return model;
  }

  static Future<int> getIosMajorVersion() async {
    String version = await getIosVersion();
    return int.tryParse(version.split('.').first) ?? 0;
  }

  static Future<bool> isIPad() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    return iosInfo.model.toLowerCase().contains('ipad') ||
        iosInfo.utsname.machine.toLowerCase().contains('ipad');
  }

  static final String placeholderSvgAssetPath =
      'assets/svg/8-8-led-matrix-display-unit.svg';

  static final String appIconAssetPath = 'assets/svg/roonmatrix-app-icon.svg';

  static final String placeholderPngAssetPath = 'assets/icon/icon.png';

  static final String tickerFontFamily = 'Arial';
  static final List<String> fontFamilyFallback = ['NotoSans', 'Symbola'];

  static final String tickerSeparator = '    ////    ';

  static final double verticalTickerWidthFactor = 0.65;

  static final double mobileButtonSize = 40.0;
  static final double mobileExpandableButtonSize = 38.0;
  static final double mobileFontSizeSmall = 32.0;
  static final double mobileFontSizeMedium = 64.0;
  static final double mobileFontSizeBig = 128.0;

  static final double sliderMinValue = 0.0;
  static final double sliderMaxValue = 5.0;

  static final double heightSwitchBoundaryVerySmall = 400;
  static final double heightSwitchBoundarySmall = 480;

  static final double mobilePageButtonsMaxWidth = 960;

  static final double widthSwitchBoundaryMid = 768;

  static final double sliderOverlayMaxWidth = 216.0;

  static final double deviceListItemSwitchBoundaryFullInfo = 650;

  static final double extendedTitleWidth = 500.0;

  static final double zoneCornerFullSize = 200.0;

  static final double overlyPlayoutButtonSizeFactor = 0.22;

  static final Duration coverSwitchDefaultFadeAnimationDuration = Duration(
    milliseconds: 700,
  );

  static final Duration coverSwitchAnimatedPresetDuration = const Duration(
    milliseconds: 1000,
  );

  static final Duration tooltipWaitDuration = const Duration(seconds: 2);

  static final Duration controlButtonTooltipWaitDuration = const Duration(
    seconds: 3,
  );

  static final AnimatedSwitcherTransitionBuilder coverSwitchAnimatedPreset =
      CoverTransition.presets(CoverTransitionPreset.fadeScale);

  static BorderRadius borderRadius() =>
      BorderRadius.all(Radius.circular(Globals.inIosStyle() ? 8.0 : 5.0));

  static String getZoneIcon({required String zoneName}) {
    if (zoneName.endsWith('-SpotifyConnect')) {
      return 'assets/icon/spotifyconnect.png';
    }
    if (zoneName.endsWith('-Spotify')) {
      return 'assets/icon/spotify.png';
    }
    if (zoneName.endsWith('-Apple Music')) {
      return 'assets/icon/applemusic.png';
    }

    return 'assets/icon/roon.png';
  }

  static String getZoneNameWithoutType({required String zoneName}) => zoneName
      .replaceFirst('-SpotifyConnect', '')
      .replaceFirst('-Spotify', '')
      .replaceFirst('-Apple Music', '');

  static double getWindowMinHeight() {
    double minHeight = Platform.isWindows ? 392 : 320;
    if (Platform.isLinux) {
      minHeight = 456;
    }
    if (Platform.isMacOS &&
        Globals.inMacosStyle() == false &&
        Globals.inIosStyle() == false) {
      minHeight = 380;
    }

    return minHeight;
  }

  static Brightness brightness() =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
}
