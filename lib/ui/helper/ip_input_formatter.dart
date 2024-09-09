import 'package:flutter/services.dart';

class IpInputFormatter {
  static TextInputFormatter ipAddressInputFilter() {
    return FilteringTextInputFormatter.allow(RegExp("[0-9.]"));
  }
}
