import 'package:equatable/equatable.dart';

abstract class WebPageEvent extends Equatable {
  const WebPageEvent([List props = const []]);
  @override
  List<Object> get props => [];
}

class SetWebPageStateLoadDefaults extends WebPageEvent {
  final String url;

  const SetWebPageStateLoadDefaults({
    required this.url,
  });

  @override
  List<Object> get props => [url];
}

class SetUrl extends WebPageEvent {
  final String url;

  const SetUrl({
    required this.url,
  });

  @override
  List<Object> get props => [url];
}

class SetProgress extends WebPageEvent {
  final double progress;

  const SetProgress({
    required this.progress,
  });

  @override
  List<Object> get props => [progress];
}
