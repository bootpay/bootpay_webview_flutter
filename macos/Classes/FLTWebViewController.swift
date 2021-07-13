//
//  sFLTWebViewController.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/05.
//

import FlutterMacOS
import WebKit

public class FLTWebViewController: NSViewController, WKUIDelegate {
    var _resumeWebView: WKWebView?
    var _webView: WKWebView?
    var _viewId: Int64 = 0
    var _channel: FlutterMethodChannel?
    var _currentUrl: String = ""
//    var _javaScriptChannelNames: NSMutableSet?
    var _javaScriptChannelNames: [String] = []
    var _navigationDelegate: FLTWKNavigationDelegate?
    var _progressionDelegate: FLTWKProgressionDelegate?
    
    
    enum PresentationStyle: Int {
        case modal = 0
        case sheet = 1
    }
    
    static let closeNotification = Notification.Name("WebViewCloseNotification")
    
    
    private let presentationStyle: PresentationStyle
    private let modalTitle: String!
    private let sheetCloseButtonTitle: String
    
    required init(
           channel: FlutterMethodChannel,
           frame: NSRect,
           presentationStyle: PresentationStyle,
           modalTitle: String,
           sheetCloseButtonTitle: String
    ) {
        
    }
    
 
    init(_ frame: CGRect,
           viewId: Int64,
           args: [String:Any]?,
           messenger:FlutterBinaryMessenger) {
        
        super.init()
        let channelName = String(format: "kr.co.bootpay/webview_%lld", viewId)
        _channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        
        let userContentController = WKUserContentController()
        if let args = args {
            if let javaScriptChannelNames = args["javascriptChannelNames"] as? [String] {
                for channelName in javaScriptChannelNames {
                    self._javaScriptChannelNames.append(channelName)
                }
                registerJavaScriptChannels(_javaScriptChannelNames, controller: userContentController)
            }
            
            
            if let settings = args["settings"] as? [String: Any] {
              
                let configuration = WKWebViewConfiguration()
                applyConfigurationSettings(settings, to: configuration)
                configuration.userContentController = userContentController
                
                if let autoMediaPlaybackPolicy = args["autoMediaPlaybackPolicy"] as? NSNumber {
                    updateAutoMediaPlaybackPolicy(autoMediaPlaybackPolicy, in: configuration)
                }
                 
                _webView = WKWebView.init(frame: frame, configuration: configuration)
                _navigationDelegate = FLTWKNavigationDelegate.init(channel: _channel!)
                
                _webView?.uiDelegate = self
                _webView?.navigationDelegate = _navigationDelegate
                
                weak var weakSelf = self
                _channel?.setMethodCallHandler({ call, result in
                    weakSelf?.onMethod(call: call, result: result)
                })

//                if #available(iOS 11.0, *) {
//                    _webView?.scrollView.contentInsetAdjustmentBehavior = .never
//                    if #available(iOS 13.0, *) {
//                        _webView?.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
//                    }
//                }
                
                self.applySettings(settings)
            }
            
            if let initialUrl = args["initialUrl"] as? String {
                self.loadUrl(initialUrl)
            }
        }
        
        _resumeWebView = _webView
         
         NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name("Bootpay_applicationDidBecomeActive"), object: nil)
    }
    
    @objc func applicationDidBecomeActive(_ noti: Notification) {
        guard let resumeWebView = _resumeWebView else { return }
        if resumeWebView.url!.absoluteString.hasPrefix("https://nid.naver.com/nidlogin.login") {
            resumeWebView.evaluateJavaScript("document.getElementById('appschemeLogin_again_btn').click()", completionHandler: nil)
        }
    }
    
    deinit {
        if _progressionDelegate != nil && _webView != nil {
            _progressionDelegate?.stopObservingProgress(_webView!)
        }
        let notiCenter = NotificationCenter.default
        notiCenter.removeObserver(self)
    }
     
    
    func onMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateSettings" {
            self.onUpdateSettings(call, result: result)
        } else if call.method == "loadUrl" {
            self.onLoadUrl(call, result: result)
        } else if call.method == "canGoBack" {
            self.onCanGoBack(call, result: result)
        } else if call.method == "canGoForward" {
            self.onCanGoBack(call, result: result)
        } else if call.method == "goBack" {
            self.onGoBack(call, result: result)
        } else if call.method == "goForward" {
            self.onGoForward(call, result: result)
        } else if call.method == "reload" {
            self.onReload(call, result: result)
        } else if call.method == "currentUrl" {
            self.onCurrentUrl(call, result: result)
        } else if call.method == "evaluateJavascript" {
            self.onEvaluateJavaScript(call, result: result)
        } else if call.method == "removeJavascriptChannels" {
            self.onRemoveJavaScriptChannels(call, result: result)
        } else if call.method == "clearCache" {
            self.clearCache(result)
        } else if call.method == "getTitle" {
            self.onGetTitle(result)
        } else if call.method == "scrollTo" {
            result(FlutterMethodNotImplemented)
//            self.onScroll(to: call, result: result)
        } else if call.method == "scrollBy" {
            result(FlutterMethodNotImplemented)
//            self.onScroll(by: call, result: result)
        } else if call.method == "getScrollX" {
            result(FlutterMethodNotImplemented)
//            self.getScrollX(call, result: result)
        } else if call.method == "getScrollY" {
            result(FlutterMethodNotImplemented)
//            self.getScrollY(call, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

extension FLTWebViewController {
    func onUpdateSettings(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        guard let error = applySettings(call!.arguments as? [String : Any]) else {
            result(nil)
            return
        }
        
        result(FlutterError(code: "updateSettings_failed", message: error, details: nil))
    }
    
    func onLoadUrl(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        if self.loadRequest(call?.arguments as? [String : Any]) == false {
            result(
                FlutterError(
                            code: "loadUrl_failed",
                            message: "Failed parsing the URL",
                    details: "Request was: '\(String(describing: call?.arguments))'"))
        } else {
            result(nil)
        }
    }
    
    func onCanGoBack(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        let canGoBack = _webView?.canGoBack
        result(canGoBack)
    }

    func onCanGoForward(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        let canGoForward = _webView?.canGoForward
        result(canGoForward)
    }
    
    func onGoBack(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        _webView?.goBack()
        result(nil)
    }

    func onGoForward(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        _webView?.goForward()
        result(nil)
    }
    
    func onReload(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        _webView?.reload()
        result(nil)
    }

    func onCurrentUrl(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        let currentUrl = _webView?.url?.absoluteString
        result(currentUrl)
    }
    
    func onEvaluateJavaScript(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        guard let jsString: String = call?.arguments as? String else {
            result(
                FlutterError(
                        code: "evaluateJavaScript_failed",
                        message: "JavaScript String cannot be null",
                        details: nil))
            return
        }
          
        _webView?.evaluateJavaScript(jsString, completionHandler: { evResult, error in
            if error != nil {
                result(FlutterError(
                        code: "evaluateJavaScript_failed",
                        message: "Failed evaluating JavaScript",
                        details: "avaScript string was: '\(jsString)'\n\(String(describing: evResult))"))
            } else {
                result(evResult)
            }
        })
    }
    
    func onAddJavaScriptChannels(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        if let channelNames: [String] = call?.arguments as? [String] {
            let copyNames: [String]  = channelNames.map { $0.copy() as! String }
            
            for channel in copyNames {
                _javaScriptChannelNames.append(channel)
            }
            self.registerJavaScriptChannels(copyNames, controller: _webView?.configuration.userContentController)
        }
        result(nil)
    }
    
    func onRemoveJavaScriptChannels(_ call: FlutterMethodCall?, result: @escaping FlutterResult) {
        
        _webView?.configuration.userContentController.removeAllUserScripts()
        for channelName in _javaScriptChannelNames {
            _webView?.configuration.userContentController.removeScriptMessageHandler(forName: channelName)
        }
        if let channelNamesToRemove = call?.arguments as? [String] {
            for channelName in channelNamesToRemove {
                if let index = _javaScriptChannelNames.firstIndex(where: {$0 == channelName}) {
                    _javaScriptChannelNames.remove(at: index)
                }
            }
        }
        self.registerJavaScriptChannels(_javaScriptChannelNames, controller: _webView?.configuration.userContentController)
        result(nil)
    }
    
    func clearCache(_ result: @escaping FlutterResult) {
        if #available(iOS 9.0, *) {
            let cacheDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let dataStore = WKWebsiteDataStore.default()
            let dateFrom = Date(timeIntervalSince1970: 0)
            dataStore.removeData(
                ofTypes: cacheDataTypes,
                modifiedSince: dateFrom,
                completionHandler: {
                    result(nil)
                })
        } else {
            print("Clearing cache is not supported for Flutter WebViews prior to iOS 9.")
        }
    }
    
    func onGetTitle(_ result: @escaping FlutterResult) {
        let title = _webView?.title
        result(title)
    }
    
    func applySettings(_ settings: [String : Any?]?) -> String? {
        var unknownKeys = [String]()
        
        if let settings = settings {
            for (key, value) in settings {
                if key == "jsMode" {
                    self.updateJsMode(value as? NSNumber)
                } else if key == "hasNavigationDelegate" {
                    _navigationDelegate?.hasDartNavigationDelegate = value as! Bool
                } else if key == "hasProgressTracking" {
                    let hasProgressTracking = (value as! NSNumber).boolValue
                    if hasProgressTracking {
                        if let webView = _webView, let channel = _channel {
                            _progressionDelegate = FLTWKProgressionDelegate.init(webView: webView, channel: channel)
                        }
                    }
                } else if key == "debuggingEnabled" {
                    // no-op debugging is always enabled on iOS.
                } else if key == "gestureNavigationEnabled" {
                    _webView?.allowsBackForwardNavigationGestures = value as! Bool
                } else if key == "userAgent" {
                    self.updateUserAgent(value as? String ?? nil)
                } else {
                    unknownKeys.append(key)
                }
            }
        }
        
        if unknownKeys.count == 0 { return nil }
        return "webview_flutter: unknown setting keys: {\(unknownKeys.joined(separator: ", "))}"
    }
    
    func applyConfigurationSettings(_ settings: [String : Any?]?, to configuration: WKWebViewConfiguration?) {
        assert(configuration != _webView?.configuration, "configuration needs to be updated before webView.configuration.")
        
        if let settings = settings {
            for (key, value) in settings {
                if key == "allowsInlineMediaPlayback" {
//                    configuration?.allowsInlineMediaPlayback = false
                    configuration?.allowsAirPlayForMediaPlayback = value as! Bool
                }
            }
        }
    }
    
    func updateJsMode(_ mode: NSNumber?) {
        if let preferences = _webView?.configuration.preferences {
            switch mode?.intValue ?? 0 {
                case 0 /* disabled */:
                    preferences.javaScriptEnabled = false
                case 1 /* unrestricted */:
                    preferences.javaScriptEnabled = true
                default:
                    print("webview_flutter: unknown JavaScript mode: \(mode ?? 0)")
            }
        }
    }
    
    func updateAutoMediaPlaybackPolicy(_ policy: NSNumber, in configuration: WKWebViewConfiguration) {
        
        switch policy.intValue {
        case 0:
            if #available(macOS 10.12, *) {
                configuration.mediaTypesRequiringUserActionForPlayback = .all
            } else {
//                configuration.mediaPlaybackRequiresUserAction = true
            }
            break
        case 1:
            if #available(macOS 10.12, *) {
                configuration.mediaTypesRequiringUserActionForPlayback = []
            } else {
//                configuration.mediaPlaybackRequiresUserAction = false
            }
            break
        default:
            print("webview_flutter: unknown auto media playback policy: \(policy)")
        }
        
    }
    
    func loadRequest(_ request: [String: Any]?) -> Bool {
        guard let request = request else { return false }

        if let url = request["url"] as? String {
            if let headers = request["headers"] as? [String : String] {
                return loadUrl(url, withHeaders: headers)
            } else {
                return loadUrl(url)
            }
        }

        return false
    }
    
    func loadUrl(_ url: String?) -> Bool {
        return loadUrl(url, withHeaders: [:])
    }

    func loadUrl(_ url: String?, withHeaders headers: [String : String]?) -> Bool {
        if let nsUrl = URL(string: url ?? "") {
            var request = URLRequest(url: nsUrl)
            request.allHTTPHeaderFields = headers
            _webView?.load(request)
            return true
        }
        return false
    }
    
    func registerJavaScriptChannels(_ channelNames: [String]?, controller userContentController: WKUserContentController?) {
        guard let channelNames = channelNames else { return }
        guard let channel = self._channel else { return }
        guard let userContentController = userContentController else { return }
        
        
        for channelName in channelNames {
            let channel = FLTJavaScriptChannel(methodChannel: channel, javaScriptChannelName: channelName)
            
            userContentController.add(channel, name: channelName)
            
            let wrapperSource = "window.\(channelName) = webkit.messageHandlers.\(channelName);"
            let wrapperScript = WKUserScript(
                source: wrapperSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false)
               
            userContentController.addUserScript(wrapperScript)
        }
    }
    
    func updateUserAgent(_ userAgent: String?) {
        if #available(iOS 9.0, *) {
            _webView?.customUserAgent = userAgent
        } else {
            print("Updating UserAgent is not supported for Flutter WebViews prior to iOS 9.")
        }
    }
}


extension FLTWebViewController {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let popupView = WKWebView(frame: webView.bounds, configuration: configuration)
                
        
        popupView.navigationDelegate = _navigationDelegate
        popupView.uiDelegate = self

//        self.addSubview(popupView)
        _resumeWebView = popupView
        
        return popupView
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")
        let modalResult = alert.runModal()
        switch modalResult {
        case .alertFirstButtonReturn: // NSApplication.ModalResponse.alertFirstButtonReturn
            completionHandler()
        case .alertSecondButtonReturn:
            completionHandler()
//            Bootpay.shared.close?()
//            self.parent.isPresented = false
        default:
            completionHandler()
        }
        
//        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
//        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
//            completionHandler()
//        }
//        let cancelAction = UIAlertAction(title: "닫기", style: .default) { _ in
//            completionHandler()
//        }
//        alertController.addAction(confirmAction)
//        alertController.addAction(cancelAction)
//        DispatchQueue.main.async {
//            if var topController = UIApplication.shared.keyWindow?.rootViewController {
//                while let presentedViewController = topController.presentedViewController {
//                    topController = presentedViewController
//                }
//                topController.present(alertController, animated: true, completion: nil)
//            }
//        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")
        let modalResult = alert.runModal()
        switch modalResult {
        case .alertFirstButtonReturn: // NSApplication.ModalResponse.alertFirstButtonReturn
            completionHandler(true)
        case .alertSecondButtonReturn:
            completionHandler(false)
//            Bootpay.shared.close?()
//            self.parent.isPresented = false
        default:
            completionHandler(true)
        }
        
        
//        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
//            completionHandler(true)
//        }))
//        alertController.addAction(UIAlertAction(title: "닫기", style: .default, handler: { (action) in
//            completionHandler(false)
//        }))
//
//        DispatchQueue.main.async {
//            if var topController = UIApplication.shared.keyWindow?.rootViewController {
//                while let presentedViewController = topController.presentedViewController {
//                    topController = presentedViewController
//                }
//                topController.present(alertController, animated: true, completion: nil)
//            }
//        }
    }
    
//    func topMostController() -> UIViewController? {
//       var from = UIApplication.shared.keyWindow?.rootViewController
//       while (from != nil) {
//           if let to = (from as? UITabBarController)?.selectedViewController {
//               from = to
//           } else if let to = (from as? UINavigationController)?.visibleViewController {
//               from = to
//           } else if let to = from?.presentedViewController {
//               from = to
//           } else {
//               break
//           }
//       }
//       return from
//   }
}
