// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package kr.co.bootpay.bootpay_webview_flutter;

import android.Manifest;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.display.DisplayManager;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.GeolocationPermissions;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebStorage;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FlutterView implements PlatformView, MethodCallHandler {
  private static final String JS_CHANNEL_NAMES_FIELD = "javascriptChannelNames";
  private final WebView webView;
  private final MethodChannel methodChannel;
  private final FlutterWebViewClient flutterWebViewClient;
  private final Handler platformThreadHandler;

  // Verifies that a url opened by `Window.open` has a secure url.
  private class FlutterWebChromeClient extends WebChromeClient {
    WebView mainView;
    @Override
    public void onCloseWindow(WebView window) {
      super.onCloseWindow(window);
      if(mainView != null) mainView.removeView(window);
      window.setVisibility(View.GONE);
    }

    @Override
    public boolean onCreateWindow(
        final WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
      mainView = view;

      final WebViewClient webViewClient =
          new WebViewClient() {
            @TargetApi(Build.VERSION_CODES.LOLLIPOP)
            @Override
            public boolean shouldOverrideUrlLoading(
                @NonNull WebView view, @NonNull WebResourceRequest request) {
              return BootpayUrlHelper.shouldOverrideUrlLoadingMethodChannel(view, request.getUrl().toString(), request.getRequestHeaders(), request.isForMainFrame(), methodChannel);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
              return BootpayUrlHelper.shouldOverrideUrlLoadingMethodChannel(view, url, null, true, methodChannel);
            }

            public void onPageStarted(WebView view, String url) {
              Map<String, Object> args = new HashMap<>();
              args.put("url", url);
              methodChannel.invokeMethod("onPageStarted", args);
            }

            @Override
            public void onPageFinished(WebView view, String url) {

              if(url.startsWith("https://nid.naver.com/nidlogin.login")) {
                view.evaluateJavascript("document.getElementById('back').style.display='none';", null);
              }

              Map<String, Object> args = new HashMap<>();
              args.put("url", url);
              methodChannel.invokeMethod("onPageFinished", args);
            }

            private void onWebResourceError(
                    final int errorCode, final String description, final String failingUrl) {
              final Map<String, Object> args = new HashMap<>();
              args.put("errorCode", errorCode);
              args.put("description", description);
              args.put("errorType", FlutterWebViewClient.errorCodeToString(errorCode));
              args.put("failingUrl", failingUrl);
              methodChannel.invokeMethod("onWebResourceError", args);
            }
          };

      final WebView newWebView = new WebView(view.getContext());
      newWebView.setWebViewClient(webViewClient);

//      newWebView.getSettings().setSupportZoom(view.getSettings().getsu );
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
        newWebView.getSettings().setMediaPlaybackRequiresUserGesture( view.getSettings().getMediaPlaybackRequiresUserGesture() );
      }
//      newWebView.setFocusable(true);
//      newWebView.setFocusableInTouchMode(true);

      newWebView.getSettings().setBuiltInZoomControls(view.getSettings().getBuiltInZoomControls());
      newWebView.getSettings().setDisplayZoomControls(view.getSettings().getDisplayZoomControls());
      newWebView.getSettings().setAllowFileAccess(view.getSettings().getAllowFileAccess());
      newWebView.getSettings().setAllowContentAccess(view.getSettings().getAllowContentAccess());
      newWebView.getSettings().setLoadWithOverviewMode(view.getSettings().getLoadWithOverviewMode());
//      newWebView.getSettings().setEnableSmoothTransition(view.getSettings().);
      newWebView.getSettings().setSaveFormData(view.getSettings().getSaveFormData());
      newWebView.getSettings().setSavePassword(view.getSettings().getSavePassword());
      newWebView.getSettings().setTextZoom(view.getSettings().getTextZoom());


      newWebView.getSettings().setUseWideViewPort(view.getSettings().getUseWideViewPort());
      newWebView.getSettings().setSupportMultipleWindows(true);
      newWebView.getSettings().setLayoutAlgorithm(view.getSettings().getLayoutAlgorithm());
      newWebView.getSettings().setStandardFontFamily(view.getSettings().getStandardFontFamily());
      newWebView.getSettings().setFixedFontFamily(view.getSettings().getFixedFontFamily());
      newWebView.getSettings().setSansSerifFontFamily(view.getSettings().getSansSerifFontFamily());
      newWebView.getSettings().setSerifFontFamily(view.getSettings().getSerifFontFamily());
      newWebView.getSettings().setCursiveFontFamily(view.getSettings().getCursiveFontFamily());
      newWebView.getSettings().setFantasyFontFamily(view.getSettings().getFantasyFontFamily());
      newWebView.getSettings().setMinimumFontSize(view.getSettings().getMinimumFontSize());
      newWebView.getSettings().setMinimumLogicalFontSize(view.getSettings().getMinimumLogicalFontSize());
      newWebView.getSettings().setDefaultFontSize(view.getSettings().getDefaultFontSize());
      newWebView.getSettings().setDefaultFixedFontSize(view.getSettings().getDefaultFixedFontSize());
      newWebView.getSettings().setLoadsImagesAutomatically(view.getSettings().getLoadsImagesAutomatically());
      newWebView.getSettings().setBlockNetworkImage(view.getSettings().getBlockNetworkImage());
      newWebView.getSettings().setJavaScriptEnabled(view.getSettings().getJavaScriptEnabled());
      newWebView.getSettings().setDatabaseEnabled(view.getSettings().getDatabaseEnabled());
      newWebView.getSettings().setDomStorageEnabled(view.getSettings().getDomStorageEnabled());

      newWebView.getSettings().setJavaScriptCanOpenWindowsAutomatically(view.getSettings().getJavaScriptCanOpenWindowsAutomatically());
      newWebView.getSettings().setDefaultTextEncodingName(view.getSettings().getDefaultTextEncodingName());
      newWebView.getSettings().setUserAgentString(view.getSettings().getUserAgentString());
      newWebView.getSettings().setCacheMode(view.getSettings().getCacheMode());

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        newWebView.getSettings().setMixedContentMode(view.getSettings().getMixedContentMode());
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        newWebView.getSettings().setSafeBrowsingEnabled(view.getSettings().getSafeBrowsingEnabled());
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        newWebView.getSettings().setForceDark(view.getSettings().getForceDark());
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        newWebView.getSettings().setDisabledActionModeMenuItems(view.getSettings().getDisabledActionModeMenuItems());
      }
      newWebView.requestFocus(View.FOCUS_DOWN);
      newWebView.setOnTouchListener(new View.OnTouchListener() {
        @Override
        public boolean onTouch(View v, MotionEvent event) {
          switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_UP:
              if (!v.hasFocus()) {
                v.requestFocus();
              }
              break;
          }
          return false;
        }
      });

      newWebView.setWebChromeClient(new FlutterWebChromeClient());
      view.addView(newWebView,
              new FrameLayout.LayoutParams(
                      ViewGroup.LayoutParams.MATCH_PARENT,
                      ViewGroup.LayoutParams.MATCH_PARENT,
                      Gravity.NO_GRAVITY)
      );

      final WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
      transport.setWebView(newWebView);
      resultMsg.sendToTarget();

      return true;
    }

    @Override
    public void onProgressChanged(WebView view, int progress) {
      flutterWebViewClient.onLoadingProgress(progress);
    }

  }

  @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
  @SuppressWarnings("unchecked")
  FlutterView(
      final Context context,
      BinaryMessenger messenger,
      int id,
      Map<String, Object> params,
      View containerView) {

    DisplayListenerProxy displayListenerProxy = new DisplayListenerProxy();
    DisplayManager displayManager =
        (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
    displayListenerProxy.onPreWebViewInitialization(displayManager);

    Boolean usesHybridComposition = (Boolean) params.get("usesHybridComposition");
    webView =
        (usesHybridComposition)
            ? new WebView(context)
            : new InputAwareWebView(context, containerView);

    displayListenerProxy.onPostWebViewInitialization(displayManager);

    platformThreadHandler = new Handler(context.getMainLooper());

//    webView.setFocusable(true);
//    webView.setFocusableInTouchMode(true);
    // Allow local storage.
    webView.getSettings().setDomStorageEnabled(true);
    webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);

    // Multi windows is set with FlutterWebChromeClient by default to handle internal bug: b/159892679.
    webView.getSettings().setSupportMultipleWindows(true);

    webView.setWebChromeClient(new FlutterWebChromeClient());

    methodChannel = new MethodChannel(messenger, "kr.co.bootpay/webview_" + id);
    methodChannel.setMethodCallHandler(this);


    flutterWebViewClient = new FlutterWebViewClient(methodChannel);
    Map<String, Object> settings = (Map<String, Object>) params.get("settings");
    if (settings != null) applySettings(settings);

    if (params.containsKey(JS_CHANNEL_NAMES_FIELD)) {
      List<String> names = (List<String>) params.get(JS_CHANNEL_NAMES_FIELD);
      if (names != null) registerJavaScriptChannelNames(names);
    }

    Integer autoMediaPlaybackPolicy = (Integer) params.get("autoMediaPlaybackPolicy");
    if (autoMediaPlaybackPolicy != null) updateAutoMediaPlaybackPolicy(autoMediaPlaybackPolicy);
    if (params.containsKey("userAgent")) {
      String userAgent = (String) params.get("userAgent");
      updateUserAgent(userAgent);
    }
    if (params.containsKey("initialUrl")) {
      String url = (String) params.get("initialUrl");
      webView.loadUrl(url);
    }
    webView.requestFocus(View.FOCUS_DOWN);
    webView.setOnTouchListener(new View.OnTouchListener() {
      @Override
      public boolean onTouch(View v, MotionEvent event) {
        switch (event.getAction()) {
          case MotionEvent.ACTION_DOWN:
          case MotionEvent.ACTION_UP:
            if (!v.hasFocus()) {
              v.requestFocus();
            }
            break;
        }
        return false;
      }
    });
  }

  @Override
  public View getView() {
    return webView;
  }

  // @Override
  // This is overriding a method that hasn't rolled into stable Flutter yet. Including the
  // annotation would cause compile time failures in versions of Flutter too old to include the new
  // method. However leaving it raw like this means that the method will be ignored in old versions
  // of Flutter but used as an override anyway wherever it's actually defined.
  // TODO(mklim): Add the @Override annotation once flutter/engine#9727 rolls to stable.
  public void onInputConnectionUnlocked() {
    if (webView instanceof InputAwareWebView) {
      ((InputAwareWebView) webView).unlockInputConnection();
    }
  }

  // @Override
  // This is overriding a method that hasn't rolled into stable Flutter yet. Including the
  // annotation would cause compile time failures in versions of Flutter too old to include the new
  // method. However leaving it raw like this means that the method will be ignored in old versions
  // of Flutter but used as an override anyway wherever it's actually defined.
  // TODO(mklim): Add the @Override annotation once flutter/engine#9727 rolls to stable.
  public void onInputConnectionLocked() {
    if (webView instanceof InputAwareWebView) {
      ((InputAwareWebView) webView).lockInputConnection();
    }
  }

  // @Override
  // This is overriding a method that hasn't rolled into stable Flutter yet. Including the
  // annotation would cause compile time failures in versions of Flutter too old to include the new
  // method. However leaving it raw like this means that the method will be ignored in old versions
  // of Flutter but used as an override anyway wherever it's actually defined.
  // TODO(mklim): Add the @Override annotation once stable passes v1.10.9.
  public void onFlutterViewAttached(View flutterView) {
    if (webView instanceof InputAwareWebView) {
      ((InputAwareWebView) webView).setContainerView(flutterView);
    }
  }

  // @Override
  // This is overriding a method that hasn't rolled into stable Flutter yet. Including the
  // annotation would cause compile time failures in versions of Flutter too old to include the new
  // method. However leaving it raw like this means that the method will be ignored in old versions
  // of Flutter but used as an override anyway wherever it's actually defined.
  // TODO(mklim): Add the @Override annotation once stable passes v1.10.9.
  public void onFlutterViewDetached() {
    if (webView instanceof InputAwareWebView) {
      ((InputAwareWebView) webView).setContainerView(null);
    }
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case "loadUrl":
        loadUrl(methodCall, result);
        break;
      case "updateSettings":
        updateSettings(methodCall, result);
        break;
      case "canGoBack":
        canGoBack(result);
        break;
      case "canGoForward":
        canGoForward(result);
        break;
      case "goBack":
        goBack(result);
        break;
      case "goForward":
        goForward(result);
        break;
      case "reload":
        reload(result);
        break;
      case "currentUrl":
        currentUrl(result);
        break;
      case "evaluateJavascript":
        evaluateJavaScript(methodCall, result);
        break;
      case "addJavascriptChannels":
        addJavaScriptChannels(methodCall, result);
        break;
      case "removeJavascriptChannels":
        removeJavaScriptChannels(methodCall, result);
        break;
      case "clearCache":
        clearCache(result);
        break;
      case "getTitle":
        getTitle(result);
        break;
      case "scrollTo":
        scrollTo(methodCall, result);
        break;
      case "scrollBy":
        scrollBy(methodCall, result);
        break;
      case "getScrollX":
        getScrollX(result);
        break;
      case "getScrollY":
        getScrollY(result);
        break;
      default:
        result.notImplemented();
    }
  }

  @SuppressWarnings("unchecked")
  private void loadUrl(MethodCall methodCall, Result result) {
    Map<String, Object> request = (Map<String, Object>) methodCall.arguments;
    String url = (String) request.get("url");
    Map<String, String> headers = (Map<String, String>) request.get("headers");
    if (headers == null) {
      headers = Collections.emptyMap();
    }
    webView.loadUrl(url, headers);
    result.success(null);
  }

  private void canGoBack(Result result) {
    result.success(webView.canGoBack());
  }

  private void canGoForward(Result result) {
    result.success(webView.canGoForward());
  }

  private void goBack(Result result) {
    if (webView.canGoBack()) {
      webView.goBack();
    }
    result.success(null);
  }

  private void goForward(Result result) {
    if (webView.canGoForward()) {
      webView.goForward();
    }
    result.success(null);
  }

  private void reload(Result result) {
    webView.reload();
    result.success(null);
  }

  private void currentUrl(Result result) {
    result.success(webView.getUrl());
  }

  @SuppressWarnings("unchecked")
  private void updateSettings(MethodCall methodCall, Result result) {
    applySettings((Map<String, Object>) methodCall.arguments);
    result.success(null);
  }

  @TargetApi(Build.VERSION_CODES.KITKAT)
  private void evaluateJavaScript(MethodCall methodCall, final Result result) {
    String jsString = (String) methodCall.arguments;
    if (jsString == null) {
      throw new UnsupportedOperationException("JavaScript string cannot be null");
    }
//    mainView
    webView.evaluateJavascript(
        jsString,
        new android.webkit.ValueCallback<String>() {
          @Override
          public void onReceiveValue(String value) {
            result.success(value);
          }
        });
  }

  @SuppressWarnings("unchecked")
  private void addJavaScriptChannels(MethodCall methodCall, Result result) {
    List<String> channelNames = (List<String>) methodCall.arguments;
    registerJavaScriptChannelNames(channelNames);
    result.success(null);
  }

  @SuppressWarnings("unchecked")
  private void removeJavaScriptChannels(MethodCall methodCall, Result result) {
    List<String> channelNames = (List<String>) methodCall.arguments;
    for (String channelName : channelNames) {
      webView.removeJavascriptInterface(channelName);
    }
    result.success(null);
  }

  private void clearCache(Result result) {
    webView.clearCache(true);
    WebStorage.getInstance().deleteAllData();
    result.success(null);
  }

  private void getTitle(Result result) {
    result.success(webView.getTitle());
  }

  private void scrollTo(MethodCall methodCall, Result result) {
    Map<String, Object> request = methodCall.arguments();
    int x = (int) request.get("x");
    int y = (int) request.get("y");

    webView.scrollTo(x, y);

    result.success(null);
  }

  private void scrollBy(MethodCall methodCall, Result result) {
    Map<String, Object> request = methodCall.arguments();
    int x = (int) request.get("x");
    int y = (int) request.get("y");

    webView.scrollBy(x, y);
    result.success(null);
  }

  private void getScrollX(Result result) {
    result.success(webView.getScrollX());
  }

  private void getScrollY(Result result) {
    result.success(webView.getScrollY());
  }

  private void applySettings(Map<String, Object> settings) {
    for (String key : settings.keySet()) {
      switch (key) {
        case "jsMode":
          Integer mode = (Integer) settings.get(key);
          if (mode != null) updateJsMode(mode);
          break;
        case "hasNavigationDelegate":
          final boolean hasNavigationDelegate = (boolean) settings.get(key);

          final WebViewClient webViewClient =
              flutterWebViewClient.createWebViewClient(hasNavigationDelegate);

          webView.setWebViewClient(webViewClient);
          break;
        case "debuggingEnabled":
          final boolean debuggingEnabled = (boolean) settings.get(key);

          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webView.setWebContentsDebuggingEnabled(debuggingEnabled);
          }
          break;
        case "hasProgressTracking":
          flutterWebViewClient.hasProgressTracking = (boolean) settings.get(key);
          break;
        case "gestureNavigationEnabled":
          break;
        case "userAgent":
          updateUserAgent((String) settings.get(key));
          break;
        case "allowsInlineMediaPlayback":
          // no-op inline media playback is always allowed on Android.
          break;
        default:
          throw new IllegalArgumentException("Unknown WebView setting: " + key);
      }
    }
  }

  private void updateJsMode(int mode) {
    switch (mode) {
      case 0: // disabled
        webView.getSettings().setJavaScriptEnabled(false);
        break;
      case 1: // unrestricted
        webView.getSettings().setJavaScriptEnabled(true);
        break;
      default:
        throw new IllegalArgumentException("Trying to set unknown JavaScript mode: " + mode);
    }
  }

  private void updateAutoMediaPlaybackPolicy(int mode) {
    // This is the index of the AutoMediaPlaybackPolicy enum, index 1 is always_allow, for all
    // other values we require a user gesture.
    boolean requireUserGesture = mode != 1;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
      webView.getSettings().setMediaPlaybackRequiresUserGesture(requireUserGesture);
    }
  }

  private void registerJavaScriptChannelNames(List<String> channelNames) {
    for (String channelName : channelNames) {
      webView.addJavascriptInterface(
          new JavaScriptChannel(methodChannel, channelName, platformThreadHandler), channelName);
    }
  }

  private void updateUserAgent(String userAgent) {
    webView.getSettings().setUserAgentString(userAgent);
  }

  @Override
  public void dispose() {
    methodChannel.setMethodCallHandler(null);
    if (webView instanceof InputAwareWebView) {
      ((InputAwareWebView) webView).dispose();
    }
    webView.destroy();
  }
}
