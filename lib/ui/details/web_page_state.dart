import 'package:equatable/equatable.dart';

abstract class WebPageState extends Equatable {
  final String url;
  final double progress;

  const WebPageState({
    this.url = '',
    this.progress = 0.0,
  });

  @override
  List<Object> get props => [url, progress];

  @override
  String toString() => 'WebPageState';
}

class WebPageStateInitial extends WebPageState {
  const WebPageStateInitial();

  @override
  String toString() => 'WebPageStateInitial';
}

class WebPageStateLoaded extends WebPageState {
  const WebPageStateLoaded({
    required super.url,
    required super.progress,
  });

  @override
  String toString() => 'WebPageStateLoaded';
}
