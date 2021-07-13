////
////  sFLTWebViewFactory.swift
////  bootpay_webview_flutter
////
////  Created by Taesup Yoon on 2021/07/05.
////
//
//import FlutterMacOS
//
//public class FLTWebViewFactory: NSObject, FlutterPlatformViewFactory {
//    private weak var _messenger: FlutterBinaryMessenger?
//    
//    public init(withMessenger messenger: FlutterBinaryMessenger) {
//        super.init()
//        _messenger = messenger
//    }
//    
//    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
//        return FlutterStandardMessageCodec.sharedInstance()
//    }
//    
//    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
//        
//     
//        let webviewController = FLTWebViewController.init(frame,
//                                                          viewId: viewId,
//                                                          args: args as? [String : Any],
//                                                          messenger: _messenger!)
//         
//        return webviewController
//    }
//}
//
