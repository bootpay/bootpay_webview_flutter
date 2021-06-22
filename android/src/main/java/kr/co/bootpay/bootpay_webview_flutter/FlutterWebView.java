package kr.co.bootpay.bootpay_webview_flutter;

import android.content.Context;
import android.util.AttributeSet;
import android.webkit.WebView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.MethodChannel;

public class FlutterWebView extends WebView {

    FlutterWebViewClient mWebViewClient;

    public FlutterWebView(@NonNull Context context) {
        super(context);
//        setWebSettings();
    }

    public FlutterWebView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
//        setWebSettings();
    }

    public FlutterWebView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
//        setWebSettings();
    }


//    void setWebViewClient(MethodChannel methodChannel) {
//        mWebViewClient = new FlutterWebViewClient(methodChannel);
//        setWebViewClient(mWebViewClient);
////        setWebChromeClient(new FlutterWebChromeClient(getContext()));
//
//    }
//
//    public void setWebSettings() {
//        getSettings().setDomStorageEnabled(true);
//        getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
//        getSettings().setSupportMultipleWindows(true);
//
//    }

}
