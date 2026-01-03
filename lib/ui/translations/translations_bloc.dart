import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:language_code/language_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/ui/translations/translations_event.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class TranslationsBloc extends Bloc<TranslationsEvent, TranslationsState> {
  final FileRepository fileRepository;
  final String translationsServerUrl =
      'https://www.wilhelm-devblog.de/translations_app/';

  TranslationsBloc({required this.fileRepository})
      : super(const TranslationsStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<TranslationsEvent>((event, emit) async {
      if (event is SetTranslations) {
        String languageCode = await getLanguageCode();
        debugPrint('languageCode: $languageCode');
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

  Future<String> getTranslationFromServer(
      {required String languageCode}) async {
    Directory? appDir = await fileRepository.fetchAppDataPath();
    if (appDir != null) {
      String fileName = 'translations_$languageCode.json';
      String filePath = '${appDir.path}/translations/$fileName';
      if (kDebugMode) {
        debugPrint('local filePath: $filePath');
      }
      File localFile = File(filePath);
      bool exist = localFile.existsSync();
      if (exist == true) {
        DateTime lastModifiedLocal = localFile.lastModifiedSync();
        DateTime beforeDays = DateTime.now().subtract(const Duration(days: 7));
        int older = lastModifiedLocal.compareTo(beforeDays);
        if (older < 0) {
          debugPrint('too old local saved translation => reload from server');
        } else {
          debugPrint('get local saved translation');
          return localFile.readAsString();
        }
      }

      File? file = await fileRepository.saveFileFromUrl(
          url: '$translationsServerUrl$fileName',
          subFolder: '/translations',
          fileName: fileName);
      if (file != null) {
        debugPrint('downloaded translation file: ${file.path}');
        return file.readAsString();
      } else {
        debugPrint('translation file not found on server');
      }
    }

    return '';
  }

  Future<Map<String, dynamic>> getTranslations(
      {required String languageCode}) async {
    Map<String, dynamic> translations = {};
    String? translationsJsonString;

    try {
      translationsJsonString = await rootBundle
          .loadString('assets/json/translations_$languageCode.json');
      translations = jsonDecode(translationsJsonString);
      debugPrint('local translation file for languageCode $languageCode found');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'local translations file for languageCode $languageCode not found!');
      }
    }

    if (translationsJsonString == null) {
      try {
        translationsJsonString =
            await getTranslationFromServer(languageCode: languageCode);
        if (translationsJsonString.isNotEmpty) {
          debugPrint(
              'translationsJsonString for languageCode $languageCode from server found: $translationsJsonString');
          translations = jsonDecode(translationsJsonString);
        } else {
          debugPrint(
              'translations file for languageCode $languageCode not found => use embedded language file for english.');

          translationsJsonString =
              await rootBundle.loadString('assets/json/translations_en.json');
          translations = jsonDecode(translationsJsonString);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              'error on translations jsonDecode for languageCode $languageCode => use embedded language file for english.');

          translationsJsonString =
              await rootBundle.loadString('assets/json/translations_en.json');
          translations = jsonDecode(translationsJsonString);
        }
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
