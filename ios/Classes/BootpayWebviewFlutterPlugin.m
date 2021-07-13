#import "BootpayWebviewFlutterPlugin.h"
#if __has_include(<bootpay_webview_flutter/bootpay_webview_flutter-Swift.h>)
#import <bootpay_webview_flutter/bootpay_webview_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "bootpay_webview_flutter-Swift.h"
#endif

@implementation BootpayWebviewFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBootpayWebviewFlutterPlugin registerWithRegistrar:registrar];
}
@end
