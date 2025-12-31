import 'package:equatable/equatable.dart';

abstract class TranslationsState extends Equatable {
  final String languageCode;
  final Map<String, dynamic> translations;
  final Map<String, dynamic> logHoursOptions;
  final String aboutAppMessage;
  final bool translationsLoaded;

  const TranslationsState({
    this.languageCode = 'en',
    this.translations = const {},
    this.logHoursOptions = const {},
    this.aboutAppMessage = '',
    this.translationsLoaded = false,
  });

  @override
  List<Object> get props => [
        languageCode,
        translations,
        logHoursOptions,
        aboutAppMessage,
        translationsLoaded,
      ];

  @override
  String toString() => 'TranslationsState';
}

class TranslationsStateInitial extends TranslationsState {
  const TranslationsStateInitial();

  @override
  String toString() => 'TranslationsStateInitial';
}

class TranslationsStateLoaded extends TranslationsState {
  const TranslationsStateLoaded({
    required super.languageCode,
    required super.translations,
    required super.logHoursOptions,
    required super.aboutAppMessage,
    required super.translationsLoaded,
  });

  @override
  String toString() => 'TranslationsStateLoaded';
}
