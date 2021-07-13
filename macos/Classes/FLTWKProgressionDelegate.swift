//
//  sFLTWKProgressionDelegate.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/05.
//

import FlutterMacOS
import WebKit

public class FLTWKProgressionDelegate: NSObject {
    let FLTWKEstimatedProgressKeyPath = "estimatedProgress"
    var _methodChannel: FlutterMethodChannel?
    
    init(webView: WKWebView?, channel: FlutterMethodChannel?) {
        super.init()
        _methodChannel = channel
        webView?.addObserver(
            self,
            forKeyPath: FLTWKEstimatedProgressKeyPath,
            options: .new,
            context: nil)
    }
    
    func stopObservingProgress(_ webView: WKWebView?) {
        webView?.removeObserver(self, forKeyPath: FLTWKEstimatedProgressKeyPath)
    }

    func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [String : CGFloat]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let keyPath = keyPath else { return }
        
        if keyPath == FLTWKEstimatedProgressKeyPath {
            let newValue = change?[NSKeyValueChangeKey.newKey.rawValue] ?? 0.0
            let newValueAsInt = Int(newValue  * 100)
            
            _methodChannel?.invokeMethod("onProgress", arguments: ["progress": newValueAsInt])
        }
    }
}
