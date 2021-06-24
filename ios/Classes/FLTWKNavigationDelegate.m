// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTWKNavigationDelegate.h"

@implementation FLTWKNavigationDelegate {
  FlutterMethodChannel *_methodChannel;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _methodChannel = channel;
  }
  return self;
}

#pragma mark - WKNavigationDelegate conformance

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  [_methodChannel invokeMethod:@"onPageStarted" arguments:@{@"url" : webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  if (!self.hasDartNavigationDelegate) {
    decisionHandler(WKNavigationActionPolicyAllow);
    return;
  }
  NSDictionary *arguments = @{
    @"url" : navigationAction.request.URL.absoluteString,
    @"isForMainFrame" : @(navigationAction.targetFrame.isMainFrame)
  };
  [_methodChannel invokeMethod:@"navigationRequest"
                     arguments:arguments
                        result:^(id _Nullable result) {
      
      if([self isItunesURL:navigationAction.request.URL.absoluteString]) {
          [self startAppToApp:navigationAction.request.URL];
          decisionHandler(WKNavigationActionPolicyCancel);
      } else if(![navigationAction.request.URL.absoluteString hasPrefix:@"http"]) {
          [self startAppToApp:navigationAction.request.URL]; 
      }
      
      if ([result isKindOfClass:[FlutterError class]]) {
        NSLog(@"navigationRequest has unexpectedly completed with an error, "
              @"allowing navigation.");
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
      }
      if (result == FlutterMethodNotImplemented) {
        NSLog(@"navigationRequest was unexepectedly not implemented: %@, "
              @"allowing navigation.",
              result);
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
      }
      if (![result isKindOfClass:[NSNumber class]]) {
        NSLog(@"navigationRequest unexpectedly returned a non boolean value: "
              @"%@, allowing navigation.",
              result);
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
      }
      NSNumber *typedResult = result;
      decisionHandler([typedResult boolValue] ? WKNavigationActionPolicyAllow
                                              : WKNavigationActionPolicyCancel);
  }];
}

- (BOOL) isMatch:(NSString*)urlString :(NSString*)pattern {
    NSError  *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:urlString options:0 range: NSMakeRange(0, [urlString length])];
    return [match numberOfRanges] > 0;
}

- (BOOL) isItunesURL:(NSString*) url {
    return [self isMatch:url :@"\\/\\/itunes\\.apple\\.com\\/"];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  [_methodChannel invokeMethod:@"onPageFinished" arguments:@{@"url" : webView.URL.absoluteString}];
}

- (void) startAppToApp:(NSURL*)url {
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [application openURL:url options:@{} completionHandler:nil];
    } else {
        [application openURL:url];
    }
}

- (NSString *)getQueryStringParameter:(NSURL *)url :(NSString *)param {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
                                                resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    if ([queryItems count] == 0) return @"";
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", param];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    
    return queryItem.value;
}

+ (id)errorCodeToString:(NSUInteger)code {
  switch (code) {
    case WKErrorUnknown:
      return @"unknown";
    case WKErrorWebContentProcessTerminated:
      return @"webContentProcessTerminated";
    case WKErrorWebViewInvalidated:
      return @"webViewInvalidated";
    case WKErrorJavaScriptExceptionOccurred:
      return @"javaScriptExceptionOccurred";
    case WKErrorJavaScriptResultTypeIsUnsupported:
      return @"javaScriptResultTypeIsUnsupported";
  }

  return [NSNull null];
}

- (void)onWebResourceError:(NSError *)error {
  [_methodChannel invokeMethod:@"onWebResourceError"
                     arguments:@{
                       @"errorCode" : @(error.code),
                       @"domain" : error.domain,
                       @"description" : error.description,
                       @"errorType" : [FLTWKNavigationDelegate errorCodeToString:error.code],
                     }];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
  [self onWebResourceError:error];
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
  [self onWebResourceError:error];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
  NSError *contentProcessTerminatedError =
      [[NSError alloc] initWithDomain:WKErrorDomain
                                 code:WKErrorWebContentProcessTerminated
                             userInfo:nil];
  [self onWebResourceError:contentProcessTerminatedError];
}

@end
