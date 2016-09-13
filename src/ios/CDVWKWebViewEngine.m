/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWKWebViewEngine.h"
#import "CDVWKWebViewUIDelegate.h"
#import <Cordova/NSDictionary+CordovaPreferences.h>

#import <objc/message.h>

#define CDV_BRIDGE_NAME @"cordova"
#define CDV_IONIC_WK @"xhr"
#define CDV_WKWEBVIEW_FILE_URL_LOAD_SELECTOR @"loadFileURL:allowingReadAccessToURL:"

@interface CDVWKWebViewEngine ()

@property (nonatomic, strong, readwrite) NSOperationQueue* fileQueue;
@property (nonatomic, strong, readwrite) UIView* engineWebView;
@property (nonatomic, strong, readwrite) id <WKUIDelegate> uiDelegate;

@end

// see forwardingTargetForSelector: selector comment for the reason for this pragma
#pragma clang diagnostic ignored "-Wprotocol"

@implementation CDVWKWebViewEngine

@synthesize engineWebView = _engineWebView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        if (NSClassFromString(@"WKWebView") == nil) {
            return nil;
        }

        self.engineWebView = [[WKWebView alloc] initWithFrame:frame];
        self.fileQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}

- (WKWebViewConfiguration*) createConfigurationFromSettings:(NSDictionary*)settings
{
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    if (settings == nil) {
        return configuration;
    }

    configuration.allowsInlineMediaPlayback = [settings cordovaBoolSettingForKey:@"AllowInlineMediaPlayback" defaultValue:NO];
    configuration.mediaPlaybackRequiresUserAction = [settings cordovaBoolSettingForKey:@"MediaPlaybackRequiresUserAction" defaultValue:YES];
    configuration.suppressesIncrementalRendering = [settings cordovaBoolSettingForKey:@"SuppressesIncrementalRendering" defaultValue:NO];
    configuration.mediaPlaybackAllowsAirPlay = [settings cordovaBoolSettingForKey:@"MediaPlaybackAllowsAirPlay" defaultValue:YES];

    return configuration;
}

- (void)pluginInitialize
{
    // viewController would be available now. we attempt to set all possible delegates to it, by default
    NSDictionary* settings = self.commandDelegate.settings;

    self.uiDelegate = [[CDVWKWebViewUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];

    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:CDV_BRIDGE_NAME];
    [userContentController addScriptMessageHandler:self name:CDV_IONIC_WK];

    // Inject XHR Polyfill
    BOOL disableXHRPolyfill = [settings cordovaBoolSettingForKey:@"DisableXHRPolyfill" defaultValue:NO];
    if (!disableXHRPolyfill) {
        NSLog(@"CDVWKWebViewEngine: trying to inject XHR polyfill");
        WKUserScript *xhrScript = [self xhrPolyfillScript];
        if (xhrScript) {
            [userContentController addUserScript:xhrScript];
        }
    } else {
        NSLog(@"CDVWKWebViewEngine: skipped XHR polyfill");
    }


    WKWebViewConfiguration* configuration = [self createConfigurationFromSettings:settings];
    configuration.userContentController = userContentController;

    // re-create WKWebView, since we need to update configuration
    WKWebView* wkWebView = [[WKWebView alloc] initWithFrame:self.engineWebView.frame configuration:configuration];
    wkWebView.UIDelegate = self.uiDelegate;
    self.engineWebView = wkWebView;

    if ([self.viewController conformsToProtocol:@protocol(WKUIDelegate)]) {
        wkWebView.UIDelegate = (id <WKUIDelegate>)self.viewController;
    }

    if ([self.viewController conformsToProtocol:@protocol(WKNavigationDelegate)]) {
        wkWebView.navigationDelegate = (id <WKNavigationDelegate>)self.viewController;
    } else {
        wkWebView.navigationDelegate = (id <WKNavigationDelegate>)self;
    }

    if ([self.viewController conformsToProtocol:@protocol(WKScriptMessageHandler)]) {
        [wkWebView.configuration.userContentController addScriptMessageHandler:(id < WKScriptMessageHandler >)self.viewController name:CDV_BRIDGE_NAME];
    }

    [self updateSettings:settings];

    // check if content thread has died on resume
    NSLog(@"%@", @"CDVWKWebViewEngine will reload WKWebView if required on resume");
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(onAppWillEnterForeground:)
               name:UIApplicationWillEnterForegroundNotification object:nil];

    NSLog(@"Using WKWebView");
}

- (void) onAppWillEnterForeground:(NSNotification*)notification {
    if ([self shouldReloadWebView]) {
        NSLog(@"%@", @"CDVWKWebViewEngine reloading!");
        [(WKWebView*)_engineWebView reload];
    }
}

- (BOOL)shouldReloadWebView
{
    WKWebView* wkWebView = (WKWebView*)_engineWebView;
    return [self shouldReloadWebView:wkWebView.URL title:wkWebView.title];
}

- (BOOL)shouldReloadWebView:(NSURL*)location title:(NSString*)title
{
    BOOL title_is_nil = (title == nil);
    BOOL location_is_blank = [[location absoluteString] isEqualToString:@"about:blank"];
    
    BOOL reload = (title_is_nil || location_is_blank);
    
#ifdef DEBUG
    NSLog(@"%@", @"CDVWKWebViewEngine shouldReloadWebView::");
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView title: %@", title);
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView location: %@", [location absoluteString]);
    NSLog(@"CDVWKWebViewEngine shouldReloadWebView reload: %u", reload);
#endif
    
    return reload;
}


- (id)loadRequest:(NSURLRequest*)request
{
    if ([self canLoadRequest:request]) { // can load, differentiate between file urls and other schemes
        if (request.URL.fileURL) {
            SEL wk_sel = NSSelectorFromString(CDV_WKWEBVIEW_FILE_URL_LOAD_SELECTOR);
            NSURL* readAccessUrl = [request.URL URLByDeletingLastPathComponent];
            return ((id (*)(id, SEL, id, id))objc_msgSend)(_engineWebView, wk_sel, request.URL, readAccessUrl);
        } else {
            return [(WKWebView*)_engineWebView loadRequest:request];
        }
    } else { // can't load, print out error
        NSString* errorHtml = [NSString stringWithFormat:
                               @"<!doctype html>"
                               @"<title>Error</title>"
                               @"<div style='font-size:2em'>"
                               @"   <p>The WebView engine '%@' is unable to load the request: %@</p>"
                               @"   <p>Most likely the cause of the error is that the loading of file urls is not supported in iOS %@.</p>"
                               @"</div>",
                               NSStringFromClass([self class]),
                               [request.URL description],
                               [[UIDevice currentDevice] systemVersion]
                               ];
        return [self loadHTMLString:errorHtml baseURL:nil];
    }
}

- (id)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL
{
    return [(WKWebView*)_engineWebView loadHTMLString:string baseURL:baseURL];
}

- (NSURL*) URL
{
    return [(WKWebView*)_engineWebView URL];
}

- (BOOL) canLoadRequest:(NSURLRequest*)request
{
    // See: https://issues.apache.org/jira/browse/CB-9636
    SEL wk_sel = NSSelectorFromString(CDV_WKWEBVIEW_FILE_URL_LOAD_SELECTOR);

    // if it's a file URL, check whether WKWebView has the selector (which is in iOS 9 and up only)
    if (request.URL.fileURL) {
        return [_engineWebView respondsToSelector:wk_sel];
    } else {
        return YES;
    }
}

- (void)updateSettings:(NSDictionary*)settings
{
    WKWebView* wkWebView = (WKWebView*)_engineWebView;

    wkWebView.configuration.preferences.minimumFontSize = [settings cordovaFloatSettingForKey:@"MinimumFontSize" defaultValue:0.0];

    /*
     wkWebView.configuration.preferences.javaScriptEnabled = [settings cordovaBoolSettingForKey:@"JavaScriptEnabled" default:YES];
     wkWebView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = [settings cordovaBoolSettingForKey:@"JavaScriptCanOpenWindowsAutomatically" default:NO];
     */

    // By default, DisallowOverscroll is false (thus bounce is allowed)
    BOOL bounceAllowed = !([settings cordovaBoolSettingForKey:@"DisallowOverscroll" defaultValue:NO]);

    // prevent webView from bouncing
    if (!bounceAllowed) {
        if ([wkWebView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[wkWebView scrollView]).bounces = NO;
        } else {
            for (id subview in wkWebView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }

    wkWebView.scrollView.scrollEnabled = [settings cordovaFloatSettingForKey:@"ScrollEnabled" defaultValue:YES];

    NSString* decelerationSetting = [settings cordovaSettingForKey:@"WKWebViewDecelerationSpeed"];
    if (!decelerationSetting) {
        // Fallback to the UIWebView-named preference
        decelerationSetting = [settings cordovaSettingForKey:@"UIWebViewDecelerationSpeed"];
    }

    if (![@"fast" isEqualToString:decelerationSetting]) {
        [wkWebView.scrollView setDecelerationRate:UIScrollViewDecelerationRateNormal];
    } else {
        [wkWebView.scrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    }
}

- (void)updateWithInfo:(NSDictionary*)info
{
    NSDictionary* scriptMessageHandlers = [info objectForKey:kCDVWebViewEngineScriptMessageHandlers];
    NSDictionary* settings = [info objectForKey:kCDVWebViewEngineWebViewPreferences];
    id navigationDelegate = [info objectForKey:kCDVWebViewEngineWKNavigationDelegate];
    id uiDelegate = [info objectForKey:kCDVWebViewEngineWKUIDelegate];

    WKWebView* wkWebView = (WKWebView*)_engineWebView;

    if (scriptMessageHandlers && [scriptMessageHandlers isKindOfClass:[NSDictionary class]]) {
        NSArray* allKeys = [scriptMessageHandlers allKeys];

        for (NSString* key in allKeys) {
            id object = [scriptMessageHandlers objectForKey:key];
            if ([object conformsToProtocol:@protocol(WKScriptMessageHandler)]) {
                [wkWebView.configuration.userContentController addScriptMessageHandler:object name:key];
            }
        }
    }

    if (navigationDelegate && [navigationDelegate conformsToProtocol:@protocol(WKNavigationDelegate)]) {
        wkWebView.navigationDelegate = navigationDelegate;
    }

    if (uiDelegate && [uiDelegate conformsToProtocol:@protocol(WKUIDelegate)]) {
        wkWebView.UIDelegate = uiDelegate;
    }

    if (settings && [settings isKindOfClass:[NSDictionary class]]) {
        [self updateSettings:settings];
    }
}

// This forwards the methods that are in the header that are not implemented here.
// Both WKWebView and UIWebView implement the below:
//     loadHTMLString:baseURL:
//     loadRequest:
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _engineWebView;
}

- (UIView*)webView
{
    return self.engineWebView;
}

- (WKUserScript*)xhrPolyfillScript
{
    NSString *scriptFile = [[NSBundle mainBundle] pathForResource:@"www/xhr" ofType:@"js"];
    if (scriptFile == nil) {
        NSLog(@"CDVWKWebViewEngine: XHR polyfill was not found");
        return nil;
    }
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:scriptFile encoding:NSUTF8StringEncoding error:&error];
    if (source == nil || error != nil) {
        NSLog(@"CDVWKWebViewEngine: XHR polyfill can not be loaded: %@", error);
        return nil;
    }
    return [[WKUserScript alloc] initWithSource:source
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                               forMainFrameOnly:YES];
}

#pragma mark WKScriptMessageHandler implementation

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    if ([message.name isEqualToString:CDV_BRIDGE_NAME]) {
        [self handleCordovaMessage: message];
    } else if ([message.name isEqualToString:CDV_IONIC_WK]) {
        [self handleXHRMessage: message];
    }
}

- (void)handleCordovaMessage:(WKScriptMessage*)message
{
    CDVViewController* vc = (CDVViewController*)self.viewController;

    NSArray* jsonEntry = message.body; // NSString:callbackId, NSString:service, NSString:action, NSArray:args
    CDVInvokedUrlCommand* command = [CDVInvokedUrlCommand commandFromJson:jsonEntry];
    CDV_EXEC_LOG(@"Exec(%@): Calling %@.%@", command.callbackId, command.className, command.methodName);

    if (![vc.commandQueue execute:command]) {
#ifdef DEBUG
        NSError* error = nil;
        NSString* commandJson = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonEntry
                                                           options:0
                                                             error:&error];

        if (error == nil) {
            commandJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }

        static NSUInteger maxLogLength = 1024;
        NSString* commandString = ([commandJson length] > maxLogLength) ?
        [NSString stringWithFormat : @"%@[...]", [commandJson substringToIndex:maxLogLength]] :
        commandJson;

        NSLog(@"FAILED pluginJSON = %@", commandString);
#endif
    }
}

- (void)handleXHRMessage:(WKScriptMessage *)message
{
    NSString *str = message.body;
    if (!str || ![str isKindOfClass:[NSString class]] || [str length] < 4) {
        NSLog(@"CDVWKWebViewEngine: Invalid XHR request");
        return;
    }
    NSData *data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *request = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!request || error != nil) {
        NSLog(@"CDVWKWebViewEngine: JSON response could not be parsed");
        return;
    }

    NSNumber *reqID = request[@"id"];
    if(!reqID || ![reqID isKindOfClass:[NSNumber class]]) {
        NSLog(@"CDVWKWebViewEngine: XHR's ID is invalid'");
        return;
    }
    NSString *url = request[@"url"];
    if(!url || ![url isKindOfClass:[NSString class]]) {
        NSLog(@"CDVWKWebViewEngine: XHR's URL is invalid'");
        return;
    }
    [self sendXHRResponse:reqID path:url];
}

- (NSURL *)xhrBaseURL
{
    return [[[(WKWebView*)_engineWebView URL] URLByStandardizingPath] URLByDeletingLastPathComponent];
}


- (NSURL *)securePathAppend:(NSString *)relativePath
{
    if (relativePath == nil || [relativePath length] == 0) {
        NSLog(@"CDVWKWebViewEngine: requested path is empty");
        return nil;
    }

    if ([relativePath isAbsolutePath]) {
        NSLog(@"CDVWKWebViewEngine: requested path is an absolute path");
        return nil;
    }
    // Remove # and ?
    NSRange range = [relativePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"#?"]];
    if(range.location != NSNotFound) {
        relativePath = [relativePath substringToIndex:range.location];
    }

    NSURL *base = [self xhrBaseURL];
    NSURL *final = [[base URLByAppendingPathComponent:relativePath] standardizedURL];

    // Security sensitive
    // Ensure URL does not leave the base URL
    if (![[final absoluteString] hasPrefix:[base absoluteString]]) {
        NSLog(@"CDVWKWebViewEngine: requested path can not be accessed: %@", final);
        return nil;
    }

    return final;

}

- (void)sendXHRResponse:(NSNumber *)requestId path:(NSString *)requestPath
{
    [self.fileQueue addOperationWithBlock:^{
        if (requestId == nil) {
            NSLog(@"CDVWKWebViewEngine: requestID is empty");
            return;
        }

        if ([requestId integerValue] <= 0) {
            NSLog(@"CDVWKWebViewEngine: invalid requestID");
            return;
        }

        NSLog(@"CDVWKWebViewEngine: XHR intercepted: %@", requestPath);

        NSInteger requestIdInteger = [requestId integerValue];
        NSURL *path = [self securePathAppend: requestPath];
        if (path == nil) {
            [self js_handleXHRError:requestIdInteger errorMessage:@"bad path"];
            return;
        }

        NSError *error = nil;
        NSData *source = [NSData dataWithContentsOfURL:path options:0 error:&error];
        if (source == nil || error != nil) {
            NSLog(@"CDVWKWebViewEngine: Error while opening file with path");
            NSLog(@"CDVWKWebViewEngine: %@", error);
            [self js_handleXHRError:requestIdInteger errorMessage:@"file not found"];
            return;
        }

        NSString *content = [source base64EncodedStringWithOptions:0];
        if (content == nil) {
            [self js_handleXHRError:requestIdInteger errorMessage:@"file content can not be serialized. BUG!"];
            return;
        }

        [self js_handleXHRResponse:requestIdInteger content:content];
    }];
}

- (void) js_handleXHRResponse:(NSInteger)requestId content:(NSString *)base64
{
    NSString *jsCode = [NSString stringWithFormat:@"handleXHRResponse(%ld, \"%@\")",
                        (long)requestId, base64];

    [(WKWebView*)_engineWebView evaluateJavaScript:jsCode completionHandler:nil];
}

- (void) js_handleXHRError:(NSInteger)requestId errorMessage:(NSString *)message
{
    NSString *jsCode = [NSString stringWithFormat:@"handleXHRError(%ld, \"%@\")",
                        (long)requestId, message];

    [(WKWebView*)_engineWebView evaluateJavaScript:jsCode completionHandler:nil];
}


#pragma mark WKNavigationDelegate implementation

- (void)webView:(WKWebView*)webView didStartProvisionalNavigation:(WKNavigation*)navigation
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginResetNotification object:webView]];
}

- (void)webView:(WKWebView*)webView didFinishNavigation:(WKNavigation*)navigation
{
    CDVViewController* vc = (CDVViewController*)self.viewController;
    [CDVUserAgentUtil releaseLock:vc.userAgentLockToken];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPageDidLoadNotification object:webView]];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(WKNavigation*)navigation withError:(NSError*)error
{
    CDVViewController* vc = (CDVViewController*)self.viewController;
    [CDVUserAgentUtil releaseLock:vc.userAgentLockToken];

    NSString* message = [NSString stringWithFormat:@"Failed to load webpage with error: %@", [error localizedDescription]];
    NSLog(@"%@", message);

    NSURL* errorUrl = vc.errorURL;
    if (errorUrl) {
        errorUrl = [NSURL URLWithString:[NSString stringWithFormat:@"?error=%@", [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:errorUrl];
        NSLog(@"%@", [errorUrl absoluteString]);
        [theWebView loadRequest:[NSURLRequest requestWithURL:errorUrl]];
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    [webView reload];
}

- (BOOL)defaultResourcePolicyForURL:(NSURL*)url
{
    // all file:// urls are allowed
    if ([url isFileURL]) {
        return YES;
    }

    return NO;
}


- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url = [navigationAction.request URL];
    CDVViewController* vc = (CDVViewController*)self.viewController;

    /*
     * Give plugins the chance to handle the url
     */
    BOOL anyPluginsResponded = NO;
    BOOL shouldAllowRequest = NO;

    for (NSString* pluginName in vc.pluginObjects) {
        CDVPlugin* plugin = [vc.pluginObjects objectForKey:pluginName];
        SEL selector = NSSelectorFromString(@"shouldOverrideLoadWithRequest:navigationType:");
        if ([plugin respondsToSelector:selector]) {
            anyPluginsResponded = YES;
            shouldAllowRequest = (((BOOL (*)(id, SEL, id, int))objc_msgSend)(plugin, selector, navigationAction.request, navigationAction.navigationType));
            if (!shouldAllowRequest) {
                break;
            }
        }
    }

    if (!anyPluginsResponded) {
        /*
         * Handle all other types of urls (tel:, sms:), and requests to load a url in the main webview.
         */
        shouldAllowRequest = [self defaultResourcePolicyForURL:url];
        if (!shouldAllowRequest) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
        }
    }


    if (shouldAllowRequest) {
        NSString *scheme = url.scheme;
        if ([scheme isEqualToString:@"tel"] || [scheme isEqualToString:@"mailto"]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
@end
