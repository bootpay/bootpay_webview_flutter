import Cocoa
import FlutterMacOS

public class BootpayWebviewFlutterPlugin: NSObject, FlutterPlugin {
    
    private let channel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    
    private lazy var parentViewController: NSViewController? = {
        return NSApp.windows.first { (w) -> Bool in
            return w.contentViewController?.view == registrar.view
        }?.contentViewController
    }()
    private var webViewController: BTWebViewController?
    
    
    required init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self.channel = channel
        self.registrar = registrar
        super.init()
        initWebViewController()
    }
    
    func initWebViewController() {
        guard let parentCtrl = parentViewController else { print("NO_PARENT_WINDOW"); return }
        let parentFrame = parentCtrl.view.frame
                    
//        var width = parentFrame.size.width
//        var height = parentFrame.size.height
        
        webViewController = BTWebViewController(
            CGRect(
                x: parentFrame.origin.x,
                y: parentFrame.origin.y,
                width: parentFrame.size.width,
                height: parentFrame.size.height
            ),
            viewId: 0,
            args: nil,
            messenger: self.registrar.messenger
        )
         
    }
    
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    
    let channel = FlutterMethodChannel(
        name: "kr.co.bootpay/webview",
        binaryMessenger: registrar.messenger
    )
    let instance = BootpayWebviewFlutterPlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
    BTCookieManager.register(with: registrar)
  }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if call.method == "open" {
            
        } else if call.method == "close" {
            
        } else {
            guard let webViewController = self.webViewController else { return result(FlutterMethodNotImplemented) }
            
            return webViewController.onMethod(call: call, result: result)
        }
    }
    
    private func open(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        guard let url = URL(string: args["url"] as! String) else {
            result(FlutterError(
                code: "URL_NOT_PROVIDED",
                message: "No URL to launch found in call arguments",
                details: call.arguments
            ))
            return
        }
        
        guard let parentCtrl = parentViewController else {
            result(FlutterError(
                code: "NO_PARENT_WINDOW",
                message: "No parent window",
                details: nil
            ))
            return
        }
        
        let presentationStyle = BTWebViewController.PresentationStyle(
            rawValue: args["presentationStyle"] as! Int
        )!
                
        if webViewController == nil {
            let parentFrame = parentCtrl.view.frame
            
            var width = parentFrame.size.width
            var height = parentFrame.size.height

            if args["customSize"] as! Bool {
                if let cw = args["width"] as? Double {
                    width = CGFloat(cw)
                }
                if let ch = args["height"] as? Double {
                    height = CGFloat(ch)
                }
            }
            
//            TODO
//            if args["customOrigin"] as! Bool {
//                if let cx = args["x"] as? Double {
//                    x = CGFloat(cx)
//                }
//                if let cy = args["y"] as? Double {
//                    y = CGFloat(cy)
//                }
//            }
            
            webViewController = BTWebViewController(
                channel: channel,
                frame: CGRect(
                    x: parentFrame.origin.x,
                    y: parentFrame.origin.y,
                    width: width,
                    height: height
                ),
                presentationStyle: presentationStyle,
                modalTitle: args["modalTitle"] as! String,
                sheetCloseButtonTitle: args["sheetCloseButtonTitle"] as! String
            )
        }
        guard let webViewCtrl = webViewController else {
            result(FlutterError(
                code: "WEB_VIEW_CONTROLLER_NOT_INITIALIZED",
                message: "WebViewController not initialized, nothing to present",
                details: nil
            ))
            return
        }
        
        webViewCtrl.javascriptEnabled = args["javascriptEnabled"] as! Bool
        webViewCtrl.userAgent = args["userAgent"] as? String
        
        webViewCtrl.loadUrl(url: url)
                
        if (!parentCtrl.presentedViewControllers!.contains(webViewCtrl)) {
            if (presentationStyle == .modal) {
                parentCtrl.presentAsModalWindow(webViewCtrl)
            } else {
                parentCtrl.presentAsSheet(webViewCtrl)
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(close(_:)),
                name: WebViewController.closeNotification,
                object: nil
            )
            
            channel.invokeMethod("onOpen", arguments: nil)
            // TODO: window
        }
        result(nil)
    }
    
    private func close(_ sender: Any?, result: @escaping FlutterResult) {
        close(sender)
        result(nil)
    }
    
    @objc private func close(_ sender: Any?) {
        guard let webViewCtrl = webViewController, let parentCtrl = parentViewController else { return }
        
        if (parentCtrl.presentedViewControllers!.contains(webViewCtrl)) {
            parentCtrl.dismiss(webViewCtrl)
        }
        
        webViewController = nil
        NotificationCenter.default.removeObserver(
            self,
            name: BTWebViewController.closeNotification,
            object: nil
        )
               
        channel.invokeMethod("onClose", arguments: nil)
        
    }
}
