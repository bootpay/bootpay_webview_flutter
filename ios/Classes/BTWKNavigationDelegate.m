// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BTWKNavigationDelegate.h"

@implementation BTWKNavigationDelegate {
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
      
      if(![navigationAction.request.URL.absoluteString hasPrefix:@"https://nid.naver.com/nidlogin.login"]) {
          [webView evaluateJavaScript:@"document.getElementById('back').style.display='none';" completionHandler:nil];
      }
      
      if([self isItunesURL:navigationAction.request.URL.absoluteString]) {
          [self startAppToApp:navigationAction.request.URL];
          decisionHandler(WKNavigationActionPolicyCancel);
      } else if([navigationAction.request.URL.absoluteString hasPrefix:@"about:blank"]) {
          decisionHandler(WKNavigationActionPolicyAllow);
      } else if(![navigationAction.request.URL.absoluteString hasPrefix:@"http"]) {
          [self startAppToApp:navigationAction.request.URL];
          decisionHandler(WKNavigationActionPolicyCancel);
      } else {
          
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
      }
  }];
}


- (BOOL) isItunesURL:(NSString*) urlString {
    NSRange match = [urlString rangeOfString: @"itunes.apple.com"];
    return match.location != NSNotFound;
}

//- (BOOL) isMatch:(NSString*)urlString :(NSString*)pattern {
//    NSError  *error = nil;
//    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
//    NSTextCheckingResult *match = [regex firstMatchInString:urlString options:0 range: NSMakeRange(0, [urlString length])];
//    return [match numberOfRanges] > 0;
//}
//
//- (BOOL) isItunesURL:(NSString*) url {
//    return [self isMatch:url :@"\\/\\/itunes\\.apple\\.com\\/"];
//}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  [_methodChannel invokeMethod:@"onPageFinished" arguments:@{@"url" : webView.URL.absoluteString}];
}

- (void) startAppToApp:(NSURL*)url {
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [application openURL:url options:@{} completionHandler: ^(BOOL success) {
            if(success == false) {
                [self startItunesToInstall:url];
            }
        }];
    } else {
        [application openURL:url];
    }
    
//    if (@available(iOS 10.0, *)) {
//        [application openURL:url options:@{} completionHandler:nil];
//    } else {
//        [application openURL:url];
//    }
}


- (void) startItunesToInstall:(NSURL*) url {
    NSString *sUrl = url.absoluteString;
    NSString *itunesUrl = @"";
    
    if([sUrl hasPrefix: @"kfc-bankpay"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EB%B1%85%ED%81%AC%ED%8E%98%EC%9D%B4-%EA%B8%88%EC%9C%B5%EA%B8%B0%EA%B4%80-%EA%B3%B5%EB%8F%99-%EA%B3%84%EC%A2%8C%EC%9D%B4%EC%B2%B4-%EA%B2%B0%EC%A0%9C-%EC%A0%9C%EB%A1%9C%ED%8E%98%EC%9D%B4/id398456030";
    } else if([sUrl hasPrefix: @"ispmobile"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/isp/id369125087";
    } else if([sUrl hasPrefix: @"hdcardappcardansimclick"] || [sUrl hasPrefix: @"smhyundaiansimclick"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%ED%98%84%EB%8C%80%EC%B9%B4%EB%93%9C/id702653088";
    } else if([sUrl hasPrefix: @"shinhan-sr-ansimclick"] || [sUrl hasPrefix: @"smshinhanansimclick"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%8B%A0%ED%95%9C%ED%8E%98%EC%9D%B4%ED%8C%90/id572462317";
    } else if([sUrl hasPrefix: @"kb-acp"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/kb-pay/id695436326";
    } else if([sUrl hasPrefix: @"liivbank"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EB%A6%AC%EB%B8%8C/id1126232922";
    } else if([sUrl hasPrefix: @"mpocket.online.ansimclick"] || [sUrl hasPrefix: @"ansimclickscard"] || [sUrl hasPrefix: @"ansimclickipcollect"] || [sUrl hasPrefix: @"samsungpay"] || [sUrl hasPrefix: @"scardcertiapp"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%82%BC%EC%84%B1%EC%B9%B4%EB%93%9C/id535125356";
    } else if([sUrl hasPrefix: @"lottesmartpay"]) {
        itunesUrl = @"https://apps.apple.com/us/app/%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C-%EC%95%B1%EC%B9%B4%EB%93%9C/id688047200";
    } else if([sUrl hasPrefix: @"lotteappcard"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EB%94%94%EC%A7%80%EB%A1%9C%EC%B9%B4-%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C/id688047200";
    } else if([sUrl hasPrefix: @"newsmartpib"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%9A%B0%EB%A6%AC-won-%EB%B1%85%ED%82%B9/id1470181651";
    } else if([sUrl hasPrefix: @"com.wooricard.wcard"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%9A%B0%EB%A6%ACwon%EC%B9%B4%EB%93%9C/id1499598869";
    } else if([sUrl hasPrefix: @"citispay"] || [sUrl hasPrefix: @"citicardappkr"] || [sUrl hasPrefix: @"citimobileapp"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%94%A8%ED%8B%B0%EB%AA%A8%EB%B0%94%EC%9D%BC/id1179759666";
    } else if([sUrl hasPrefix: @"shinsegaeeasypayment"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/ssgpay/id666237916";
    } else if([sUrl hasPrefix: @"cloudpay"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%ED%95%98%EB%82%98%EC%B9%B4%EB%93%9C-%EC%9B%90%ED%81%90%ED%8E%98%EC%9D%B4/id847268987";
    } else if([sUrl hasPrefix: @"hanawalletmembers"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/n-wallet/id492190784";
    } else if([sUrl hasPrefix: @"nhappvardansimclick"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176";
    } else if([sUrl hasPrefix: @"nhallonepayansimclick"] || [sUrl hasPrefix: @"nhappcardansimclick"] || [sUrl hasPrefix: @"nhallonepayansimclick"] || [sUrl hasPrefix: @"nonghyupcardansimclick"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%98%AC%EC%9B%90%ED%8E%98%EC%9D%B4-nh%EC%95%B1%EC%B9%B4%EB%93%9C/id1177889176";
    } else if([sUrl hasPrefix: @"payco"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/payco/id924292102";
    } else if([sUrl hasPrefix: @"lpayapp"] || [sUrl hasPrefix: @"lmslpay"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/l-point-with-l-pay/id473250588";
    } else if([sUrl hasPrefix: @"naversearchapp"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EB%84%A4%EC%9D%B4%EB%B2%84-naver/id393499958";
    } else if([sUrl hasPrefix: @"tauthlink"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/pass-by-skt/id1141258007";
    } else if([sUrl hasPrefix: @"uplusauth"] || [sUrl hasPrefix: @"upluscorporation"] ) {
        itunesUrl = @"https://apps.apple.com/kr/app/pass-by-u/id1147394645";
    } else if([sUrl hasPrefix: @"ktauthexternalcall"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/pass-by-kt/id1134371550";
    } else if([sUrl hasPrefix: @"supertoss"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%ED%86%A0%EC%8A%A4/id839333328";
    } else if([sUrl hasPrefix: @"kakaotalk"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/kakaotalk/id362057947";
    } else if([sUrl hasPrefix: @"chaipayment"]) {
        itunesUrl = @"https://apps.apple.com/kr/app/%EC%B0%A8%EC%9D%B4/id1459979272";
    }
    
    if(itunesUrl.length > 0) {
        NSURL *appstore = [NSURL URLWithString: itunesUrl];
        [self startAppToApp: appstore];
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
                       @"errorType" : [BTWKNavigationDelegate errorCodeToString:error.code],
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
