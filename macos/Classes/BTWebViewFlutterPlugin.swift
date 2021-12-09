//
//  BTWebViewFlutterPlugin.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/06.
//

import Flutter

public class BTWebViewFlutterPlugin: NSObject, FlutterPlugin {
   public static func register(with registrar: FlutterPluginRegistrar) {
       let webviewFactory = BTWebViewFactory(messenger: registrar.messenger())
       registrar.register(webviewFactory, withId: "kr.co.bootpay/webview")
       BTCookieManager.register(with: registrar)
   } 
}
