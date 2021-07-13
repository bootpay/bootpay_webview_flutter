
import 'dart:async';

import 'package:flutter/services.dart';

class BootpayWebviewFlutter {
  static const MethodChannel _channel =
      const MethodChannel('bootpay_webview_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
