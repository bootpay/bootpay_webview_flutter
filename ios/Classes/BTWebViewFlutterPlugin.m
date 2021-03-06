// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BTWebViewFlutterPlugin.h"
#import "BTCookieManager.h"
#import "FlutterWebView.h"

@implementation BTWebViewFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  BTWebViewFactory* webviewFactory =
      [[BTWebViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:webviewFactory withId:@"kr.co.bootpay/webview"];
  [BTCookieManager registerWithRegistrar:registrar];
}

@end
