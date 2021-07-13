//
//  sFLTCookieManager.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/05.
//

import FlutterMacOS
import WebKit

public class FLTCookieManager: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FLTCookieManager()
        let channel = FlutterMethodChannel(name: "kr.co.bootpay/cookie_manager", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "clearCookies") {
            clearCookie(result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func clearCookie(_ result: @escaping FlutterResult) {
        if #available(iOS 9.0, *) {
            let websiteDataTypes: Set<String> = [WKWebsiteDataTypeCookies]
            let dataStore: WKWebsiteDataStore = WKWebsiteDataStore.default()
            
            let deleteAndNotify: (([WKWebsiteDataRecord]?) -> Void)? = { cookies in
                let hasCookies = (cookies?.count ?? 0) > 0
                
                dataStore.removeData(ofTypes: websiteDataTypes,
                                     for: cookies ?? [],
                                     completionHandler: {
                                        result(hasCookies)
                                     })
            }
            if let deleteAndNotify = deleteAndNotify {
                dataStore.fetchDataRecords(ofTypes: websiteDataTypes, completionHandler: deleteAndNotify)
            }
        } else {
            print("Clearing cookies is not supported for Flutter WebViews prior to iOS 9.")
        }
    }
}
