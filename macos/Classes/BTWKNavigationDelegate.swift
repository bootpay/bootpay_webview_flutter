//
//  BTWKNavigationDelegate.swift
//  bootpay_webview_flutter
//
//  Created by Taesup Yoon on 2021/07/06.
//

import FlutterMacOS
import WebKit


public class BTWKNavigationDelegate: NSObject, WKNavigationDelegate {
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
            } else if(url.absoluteString.starts(with: "about:blank")) {
                decisionHandler(.allow)
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
                    "errorType" : BTWKNavigationDelegate.errorCodeToString((error as NSError).code)
                ])
        }
    }
}

extension BTWKNavigationDelegate{
    func getQueryStringParameter(url: String, param: String) -> String? {
      guard let url = URLComponents(string: url) else { return nil }
      return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func startAppToApp(_ url: URL) {
        #if os(iOS)
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: { result in
                if(result == false) {
                    self.startItunesToInstall(url)
                }
            })
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
            itunesUrl = "https://apps.apple.com/kr/app/isp/id369125087"
        } else if(sUrl.starts(with: "hdcardappcardansimclick") || sUrl.starts(with: "smhyundaiansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%ED%98%84%EB%8C%80%EC%B9%B4%EB%93%9C/id702653088"
        } else if(sUrl.starts(with: "shinhan-sr-ansimclick") || sUrl.starts(with: "smshinhanansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%8B%A0%ED%95%9C%ED%8E%98%EC%9D%B4%ED%8C%90/id572462317"
        } else if(sUrl.starts(with: "kb-acp")) {
            itunesUrl = "https://apps.apple.com/kr/app/kb-pay/id695436326"
        } else if(sUrl.starts(with: "liivbank")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EB%A6%AC%EB%B8%8C/id1126232922"
        } else if(sUrl.starts(with: "mpocket.online.ansimclick") || sUrl.starts(with: "ansimclickscard") || sUrl.starts(with: "ansimclickipcollect") || sUrl.starts(with: "samsungpay") || sUrl.starts(with: "scardcertiapp")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%82%BC%EC%84%B1%EC%B9%B4%EB%93%9C/id535125356"
        } else if(sUrl.starts(with: "lottesmartpay")) {
            itunesUrl = "https://apps.apple.com/us/app/%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C-%EC%95%B1%EC%B9%B4%EB%93%9C/id688047200"
        } else if(sUrl.starts(with: "lotteappcard")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EB%94%94%EC%A7%80%EB%A1%9C%EC%B9%B4-%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C/id688047200"
        } else if(sUrl.starts(with: "newsmartpib")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%9A%B0%EB%A6%AC-won-%EB%B1%85%ED%82%B9/id1470181651"
        } else if(sUrl.starts(with: "com.wooricard.wcard")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%9A%B0%EB%A6%ACwon%EC%B9%B4%EB%93%9C/id1499598869"
        } else if(sUrl.starts(with: "citispay") || sUrl.starts(with: "citicardappkr") || sUrl.starts(with: "citimobileapp")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%94%A8%ED%8B%B0%EB%AA%A8%EB%B0%94%EC%9D%BC/id1179759666"
        } else if(sUrl.starts(with: "shinsegaeeasypayment")) {
            itunesUrl = "https://apps.apple.com/kr/app/ssgpay/id666237916"
        } else if(sUrl.starts(with: "cloudpay")) {

            itunesUrl = "https://apps.apple.com/kr/app/%ED%95%98%EB%82%98%EC%B9%B4%EB%93%9C-%EC%9B%90%ED%81%90%ED%8E%98%EC%9D%B4/id847268987"
        } else if(sUrl.starts(with: "hanawalletmembers")) {
            itunesUrl = "https://apps.apple.com/kr/app/n-wallet/id492190784"
        } else if(sUrl.starts(with: "nhappvardansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176"
        } else if(sUrl.starts(with: "nhallonepayansimclick") || sUrl.starts(with: "nhappcardansimclick") || sUrl.starts(with: "nhallonepayansimclick") || sUrl.starts(with: "nonghyupcardansimclick")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176"
        } else if(sUrl.starts(with: "payco")) {
            itunesUrl = "https://apps.apple.com/kr/app/payco/id924292102"
        } else if(sUrl.starts(with: "lpayapp") || sUrl.starts(with: "lmslpay")) {
            itunesUrl = "https://apps.apple.com/kr/app/l-point-with-l-pay/id473250588"
        } else if(sUrl.starts(with: "naversearchapp")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EB%84%A4%EC%9D%B4%EB%B2%84-naver/id393499958"
        } else if(sUrl.starts(with: "tauthlink")) {
            itunesUrl = "https://apps.apple.com/kr/app/pass-by-skt/id1141258007"
        } else if(sUrl.starts(with: "uplusauth") || sUrl.starts(with: "upluscorporation")) {
            itunesUrl = "https://apps.apple.com/kr/app/pass-by-u/id1147394645"
        } else if(sUrl.starts(with: "ktauthexternalcall")) {
            itunesUrl = "https://apps.apple.com/kr/app/pass-by-kt/id1134371550"
        } else if(sUrl.starts(with: "supertoss")) {
            itunesUrl = "https://apps.apple.com/kr/app/%ED%86%A0%EC%8A%A4/id839333328"
        } else if(sUrl.starts(with: "kakaotalk")) {
            itunesUrl = "https://apps.apple.com/kr/app/kakaotalk/id362057947"
        } else if(sUrl.starts(with: "chaipayment")) {
            itunesUrl = "https://apps.apple.com/kr/app/%EC%B0%A8%EC%9D%B4/id1459979272"
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
