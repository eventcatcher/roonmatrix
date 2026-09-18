import 'package:roonmatrix/ui/layout/device_list_item_event.dart';
import 'package:roonmatrix/ui/layout/device_list_item_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceListItemBloc
    extends Bloc<DeviceListItemEvent, DeviceListItemState> {
  DeviceListItemBloc() : super(const DeviceListItemStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<DeviceListItemEvent>((event, emit) async {
      if (event is DeviceListItemStateLoadDefaults) {
        emit(DeviceListItemStateLoaded(expandableMenuOpened: false));
      }

      if (event is SetExpandableMenuOpened) {
        bool enabled = event.enabled;

        emit(state.copyWith(expandableMenuOpened: enabled));
      }
    });

    loadDefaults();
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults() {
    add(DeviceListItemStateLoadDefaults());
  }

  void setExpandableMenuOpened({required bool enabled}) {
    add(SetExpandableMenuOpened(enabled: enabled));
  }
}
