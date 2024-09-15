import 'package:equatable/equatable.dart';

abstract class TranslationsEvent extends Equatable {
  const TranslationsEvent([List props = const []]);
}

class SetTranslations extends TranslationsEvent {
  @override
  List<Object> get props => [];
}
