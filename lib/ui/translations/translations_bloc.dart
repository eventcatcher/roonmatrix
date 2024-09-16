import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:language_code/language_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roonmatrix/ui/translations/translations_event.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class TranslationsBloc extends Bloc<TranslationsEvent, TranslationsState> {
  TranslationsBloc() : super(const TranslationsStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<TranslationsEvent>((event, emit) async {
      if (event is SetTranslations) {
        String languageCode = await getLanguageCode();
        Map<String, dynamic> translations =
            await getTranslations(languageCode: languageCode);
        Map<String, dynamic> logHoursOptions =
            await generateLogHours(translations);
        String aboutAppMessage = await getAboutMessage(translations);

        //await Future.delayed(const Duration(seconds: 5));

        emit(TranslationsStateLoaded(
          languageCode: languageCode,
          translations: translations,
          logHoursOptions: logHoursOptions,
          aboutAppMessage: aboutAppMessage,
          translationsLoaded: true,
        ));
      }
    });

    setTranslations();
  }

  // ============== //
  // public methods //
  // ============== //

  Future<String> getAboutMessage(Map<String, dynamic> translations) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersionAndBuildNumber =
        '${packageInfo.version}+${packageInfo.buildNumber}';

    return 'Version $appVersionAndBuildNumber\n\nCopyright © 2024 de.eventcatcher. All rights reserved.';
  }

  Future<Map<String, dynamic>> generateLogHours(
      Map<String, dynamic> translations) async {
    Map<String, dynamic> logHoursOptions = {};

    for (int i = 1; i <= 24; i++) {
      String optionTextSingle =
          translations['logHoursAgoSelectionHourMaskSingle'] ?? '# hour ago';
      String optionTextMultiple =
          translations['logHoursAgoSelectionHourMaskMultiple'] ?? '# hours ago';
      String optionText = '';

      optionText = i > 1
          ? optionTextMultiple.replaceFirst('#', i.toString())
          : optionTextSingle.replaceFirst('#', i.toString());

      logHoursOptions[i.toString()] = {
        "name": optionText,
        "fontWeight": FontWeight.normal,
        "icon": null
      };
    }

    return logHoursOptions;
  }

  Future<String> getLanguageCode() async {
    Locale locale = LanguageCode.code.locale;
    String languageCode = locale.languageCode;

    return languageCode;
  }

  Future<Map<String, dynamic>> getTranslations(
      {required String languageCode}) async {
    Map<String, dynamic> translations = {};

    try {
      String translationsJsonString = await rootBundle
          .loadString('assets/json/translations_$languageCode.json');
      translations = jsonDecode(translationsJsonString);
    } catch (e) {
      if (kDebugMode) {
        print('translations file for languageCode $languageCode not found!');
      }
    }

    return translations;
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void setTranslations() {
    add(SetTranslations());
  }
}
