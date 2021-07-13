//
//  sFLTWKNavigationDelegate.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/06.
//

import FlutterMacOS
import WebKit


public class FLTWKNavigationDelegate: NSObject, WKNavigationDelegate {
    private weak var _methodChannel: FlutterMethodChannel?
    public var hasDartNavigationDelegate = false
    
    init(channel: FlutterMethodChannel) {
        super.init()
        _methodChannel = channel
    }
 
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        _methodChannel?.invokeMethod("onPageStarted", arguments: ["url": webView.url?.absoluteString])
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if(!self.hasDartNavigationDelegate) {
            decisionHandler(.allow)
            return
        }
        
        let arguments: [String : Any] = [
            "url": navigationAction.request.url?.absoluteString ?? "",
            "isForMainFrame": navigationAction.targetFrame?.isMainFrame ?? false
        ]
        
        _methodChannel?.invokeMethod("navigationRequest", arguments: arguments, result: { result in
             
            guard let url =  navigationAction.request.url else { return decisionHandler(.allow) }
            
            if(self.isItunesURL(url.absoluteString)) {
                self.startAppToApp(url)
                decisionHandler(.cancel)
            } else if(!url.absoluteString.starts(with: "http")) {
                self.startAppToApp(url)
                decisionHandler(.cancel)
            } else {
                
                if result is FlutterError {
                    print(
                        """
                        navigationRequest has unexpectedly completed with an error, \
                        allowing navigation.
                        """)
                    decisionHandler(.allow)
                    return
                }
                if result as! NSObject == FlutterMethodNotImplemented {
                    print("navigationRequest was unexepectedly not implemented: \(String(describing: result)) allowing navigation.")
                    decisionHandler(.allow)
                    return
                }
                if !(result is NSNumber) {
                    print("navigationRequest unexpectedly returned a non boolean value:  \(String(describing: result)) allowing navigation.")
                    decisionHandler(.allow)
                    return
                }
                
                let typedResult = result
                decisionHandler(
                    (typedResult != nil && typedResult as! Bool == false)
                        ? .allow
                        : .cancel)
            }
            
        })
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        _methodChannel?.invokeMethod("onPageFinished", arguments: ["url": webView.url?.absoluteString])
    }
     
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.onWebResourceError(error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.onWebResourceError(error)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let error = NSError.init(domain: WKError.errorDomain,
                                 code: WKError.webContentProcessTerminated.rawValue,
                                 userInfo: nil)
        self.onWebResourceError(error)
    }
    
    public static func errorCodeToString(_ code: Int) -> String {
        switch code {
            case Int(WKError.unknown.rawValue):
                return "unknown"
            case Int(WKError.webContentProcessTerminated.rawValue):
                return "webContentProcessTerminated"
        case Int(WKError.webViewInvalidated.rawValue):
                return "webViewInvalidated"
        case Int(WKError.javaScriptExceptionOccurred.rawValue):
                return "javaScriptExceptionOccurred"
        case Int(WKError.javaScriptResultTypeIsUnsupported.rawValue):
                return "javaScriptResultTypeIsUnsupported"
            default:
                break
        }
        
        return ""
    }
    
    func onWebResourceError(_ error: Error?) {
        if let description = error?.localizedDescription {
            guard let error = error else { return }
            _methodChannel?.invokeMethod(
                "onWebResourceError",
                arguments: [
                    "errorCode": (error as NSError).code,
                    "domain": (error as NSError).domain,
                    "description": description,
                    "errorType" : FLTWKNavigationDelegate.errorCodeToString((error as NSError).code)
                ])
        }
    }
}

extension FLTWKNavigationDelegate{
    func getQueryStringParameter(url: String, param: String) -> String? {
      guard let url = URLComponents(string: url) else { return nil }
      return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func startAppToApp(_ url: URL) {
        #if os(iOS)
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
        #endif
    }
    
    func startItunesToInstall(_ url: URL) {
        let sUrl = url.absoluteString
        var itunesUrl = ""
        if(sUrl.starts(with: "kfc-bankpay")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EB%B1%85%ED%81%AC%ED%8E%98%EC%9D%B4-%EA%B8%88%EC%9C%B5%EA%B8%B0%EA%B4%80-%EA%B3%B5%EB%8F%99-%EA%B3%84%EC%A2%8C%EC%9D%B4%EC%B2%B4-%EA%B2%B0%EC%A0%9C-%EC%A0%9C%EB%A1%9C%ED%8E%98%EC%9D%B4/id398456030"
        } else if(sUrl.starts(with: "ispmobile")) {
            itunesUrl = "https://apps.apple.com/kr/app/isp-%ED%8E%98%EC%9D%B4%EB%B6%81/id369125087"
        } else if(sUrl.starts(with: "hdcardappcardansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%ED%98%84%EB%8C%80%EC%B9%B4%EB%93%9C/id702653088"
        } else if(sUrl.starts(with: "shinhan-sr-ansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%8B%A0%ED%95%9C%ED%8E%98%EC%9D%B4%ED%8C%90/id572462317"
        } else if(sUrl.starts(with: "kb-acp")) {
            itunesUrl = "https://apps.apple.com/kr/app/kb-pay/id695436326"
        } else if(sUrl.starts(with: "mpocket.online.ansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%82%BC%EC%84%B1%EC%B9%B4%EB%93%9C/id535125356"
        } else if(sUrl.starts(with: "lottesmartpay")) {
            itunesUrl = "https://apps.apple.com/us/app/%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C-%EC%95%B1%EC%B9%B4%EB%93%9C/id688047200"
        } else if(sUrl.starts(with: "lotteappcard")) {
            itunesUrl = "https://apps.apple.com/us/app/%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C-%EC%95%B1%EC%B9%B4%EB%93%9C/id688047200"
        } else if(sUrl.starts(with: "cloudpay")) {
            itunesUrl = "https://apps.apple.com/kr/app/%ED%95%98%EB%82%98%EC%9B%90%ED%81%90-%EC%B9%B4%EB%93%9C-%ED%95%98%EB%82%98%EC%B9%B4%EB%93%9C/id427543371"
        } else if(sUrl.starts(with: "nhappvardansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176"
        } else if(sUrl.starts(with: "nhallonepayansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176"
        } else if(sUrl.starts(with: "citispay")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%94%A8%ED%8B%B0%EB%AA%A8%EB%B0%94%EC%9D%BC/id1179759666"
        } else if(sUrl.starts(with: "payco")) {
            itunesUrl = "https://apps.apple.com/kr/app/payco-%ED%8E%98%EC%9D%B4%EC%BD%94-%ED%98%9C%ED%83%9D%EA%B9%8C%EC%A7%80-%EB%98%91%EB%98%91%ED%95%9C-%EA%B0%84%ED%8E%B8%EA%B2%B0%EC%A0%9C/id924292102"
        } else if(sUrl.starts(with: "naversearchapp")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EB%84%A4%EC%9D%B4%EB%B2%84-naver/id393499958"
        }
        
        if(itunesUrl.count > 0) {
            if let appstore = URL(string: itunesUrl) {
                startAppToApp(appstore)
            }
        }
    }
    
    func isMatch(_ urlString: String, _ pattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let result = regex.matches(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count))
        return result.count > 0
    }
    
    func isItunesURL(_ urlString: String) -> Bool {
        return isMatch(urlString, "\\/\\/itunes\\.apple\\.com\\/")
    }
}
