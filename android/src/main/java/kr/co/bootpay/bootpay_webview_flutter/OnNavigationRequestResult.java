package kr.co.bootpay.bootpay_webview_flutter;

import android.os.Build;
import android.webkit.WebView;

import java.util.Map;
import io.flutter.plugin.common.MethodChannel;


public class OnNavigationRequestResult implements MethodChannel.Result {
    private final String url;
    private final Map<String, String> headers;
    private final WebView webView;

    public OnNavigationRequestResult(String url, Map<String, String> headers, WebView webView) {
        this.url = url;
        this.headers = headers;
        this.webView = webView;
    }

    @Override
    public void success(Object shouldLoad) {
        Boolean typedShouldLoad = (Boolean) shouldLoad;
        if (typedShouldLoad) {
            loadUrl();
        }
    }

    @Override
    public void error(String errorCode, String s1, Object o) {
        throw new IllegalStateException("navigationRequest calls must succeed");
    }

    @Override
    public void notImplemented() {
        throw new IllegalStateException(
                "navigationRequest must be implemented by the webview method channel");
    }

    private void loadUrl() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webView.loadUrl(url, headers);
        } else {
            webView.loadUrl(url);
        }
    }
}