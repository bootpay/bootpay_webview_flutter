//
//  sJavaScriptChannelHandler.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/05.
//

import FlutterMacOS
import WebKit

class BTJavaScriptChannel: NSObject, WKScriptMessageHandler {
   
    var _methodChannel: FlutterMethodChannel!
    var _javaScriptChannelName: String!
   
    init(methodChannel: FlutterMethodChannel?, javaScriptChannelName: String?) {
        super.init()
        assert(methodChannel != nil, "methodChannel must not be null.")
        assert(javaScriptChannelName != nil, "javaScriptChannelName must not be null.")
        _methodChannel = methodChannel
        _javaScriptChannelName = javaScriptChannelName
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        assert(_methodChannel != nil, "Can't send a message to an unitialized JavaScript channel.")
        assert(_javaScriptChannelName != nil, "Can't send a message to an unitialized JavaScript channel.")
        let arguments = [
            "channel": _javaScriptChannelName,
            "message": "\(message.body)"
        ]
        _methodChannel.invokeMethod("javascriptChannelMessage", arguments: arguments)
    }
}
