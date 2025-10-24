import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/web_page_event.dart';
import 'package:roonmatrix/ui/details/web_page_state.dart';

class WebPageBloc extends Bloc<WebPageEvent, WebPageState> {
  WebPageBloc() : super(const WebPageStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<WebPageEvent>((event, emit) async {
      if (event is SetWebPageStateLoadDefaults) {
        emit(WebPageStateLoaded(url: event.url, progress: 0.0));
      }

      if (event is SetUrl) {
        emit(WebPageStateLoaded(url: event.url, progress: state.progress));
      }

      if (event is SetProgress) {
        emit(WebPageStateLoaded(url: state.url, progress: event.progress));
      }
    });
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults({required String url}) {
    add(SetWebPageStateLoadDefaults(url: url));
  }

  void setUrl({required String url}) {
    add(SetUrl(url: url));
  }

  void setProgress({required double progress}) {
    add(SetProgress(progress: progress));
  }
}
