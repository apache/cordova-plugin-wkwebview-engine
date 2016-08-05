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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "CDVWKWebViewEngine.h"
#import <Cordova/NSDictionary+CordovaPreferences.h>
#import <Cordova/CDVAvailability.h>

@interface CDVWKWebViewEngineTest : XCTestCase

@property (nonatomic, strong) CDVWKWebViewEngine* plugin;
@property (nonatomic, strong) CDVViewController* viewController;

@end

@interface CDVWKWebViewEngine ()

// TODO: expose private interface, if needed

@end

@interface CDVViewController ()

// expose property as readwrite, for test purposes
@property (nonatomic, readwrite, strong) NSMutableDictionary* settings;

@end

@implementation CDVWKWebViewEngineTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // NOTE: no app settings are set, so it will rely on default WKWebViewConfiguration settings
    self.plugin = [[CDVWKWebViewEngine alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.viewController = [[CDVViewController alloc] init];
    [self.viewController registerPlugin:self.plugin withClassName:NSStringFromClass([self.plugin class])];
    
    XCTAssert([self.plugin conformsToProtocol:@protocol(CDVWebViewEngineProtocol)], @"Plugin does not conform to CDVWebViewEngineProtocol");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testCanLoadRequest {
    NSURLRequest* fileUrlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:@"path/to/file.html"]];
    NSURLRequest* httpUrlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apache.org"]];
    NSURLRequest* miscUrlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"foo://bar"]];
    id<CDVWebViewEngineProtocol> webViewEngineProtocol = self.plugin;
    
    SEL wk_sel = NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:");
    if ([self.plugin.engineWebView respondsToSelector:wk_sel]) {
        XCTAssertTrue([webViewEngineProtocol canLoadRequest:fileUrlRequest]);
    } else {
        XCTAssertFalse([webViewEngineProtocol canLoadRequest:fileUrlRequest]);
    }
    
    XCTAssertTrue([webViewEngineProtocol canLoadRequest:httpUrlRequest]);
    XCTAssertTrue([webViewEngineProtocol canLoadRequest:miscUrlRequest]);
}

- (void) testUpdateInfo {
    // Add -ObjC to Other Linker Flags to test project, to load Categories
    // Update objc test template generator as well
    
    id<CDVWebViewEngineProtocol> webViewEngineProtocol = self.plugin;
    WKWebView* wkWebView = (WKWebView*)self.plugin.engineWebView;
    
    // iOS >=10 defaults to NO, < 10 defaults to YES.
    BOOL mediaPlaybackRequiresUserActionDefault = IsAtLeastiOSVersion(@"10.0")? NO : YES;
    
    NSDictionary* preferences = @{
                               [@"MinimumFontSize" lowercaseString] : @1.1, // default is 0.0
                               [@"AllowInlineMediaPlayback" lowercaseString] : @YES, // default is NO
                               [@"MediaPlaybackRequiresUserAction" lowercaseString] : @(!mediaPlaybackRequiresUserActionDefault), // default is NO on iOS >= 10, YES for < 10
                               [@"SuppressesIncrementalRendering" lowercaseString] : @YES, // default is NO
                               [@"MediaPlaybackAllowsAirPlay" lowercaseString] : @NO, // default is YES
                               [@"DisallowOverscroll" lowercaseString] : @YES, // so bounces is to be NO. defaults to NO
                               [@"WKWebViewDecelerationSpeed" lowercaseString] : @"fast" // default is 'normal'
                               };
    NSDictionary* info = @{
                           kCDVWebViewEngineWebViewPreferences : preferences
                           };
    [webViewEngineProtocol updateWithInfo:info];
    
    // the only preference we can set, we **can** change this during runtime
    XCTAssertEqualWithAccuracy(wkWebView.configuration.preferences.minimumFontSize, 1.1, 0.0001);
    
    // the WKWebViewConfiguration properties, we **cannot** change outside of initialization
    if (IsAtLeastiOSVersion(@"10.0")) {
        XCTAssertFalse(wkWebView.configuration.mediaPlaybackRequiresUserAction);
    } else {
        XCTAssertTrue(wkWebView.configuration.mediaPlaybackRequiresUserAction);
    }
    XCTAssertFalse(wkWebView.configuration.allowsInlineMediaPlayback);
    XCTAssertFalse(wkWebView.configuration.suppressesIncrementalRendering);
    XCTAssertTrue(wkWebView.configuration.mediaPlaybackAllowsAirPlay);
    
    // in the test above, DisallowOverscroll is YES, so no bounce
    if ([wkWebView respondsToSelector:@selector(scrollView)]) {
        XCTAssertFalse(((UIScrollView*)[wkWebView scrollView]).bounces);
    } else {
        for (id subview in wkWebView.subviews) {
            if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                XCTAssertFalse(((UIScrollView*)subview).bounces = NO);
            }
        }
    }
    
    XCTAssertTrue(wkWebView.scrollView.decelerationRate == UIScrollViewDecelerationRateFast);
}

- (void) testConfigurationFromSettings {
    // we need to re-set the plugin from the "setup" to take in the app settings we need
    self.plugin = [[CDVWKWebViewEngine alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.viewController = [[CDVViewController alloc] init];
    
    // generate the app settings
    // iOS >=10 defaults to NO, < 10 defaults to YES.
    BOOL mediaPlaybackRequiresUserActionDefault = IsAtLeastiOSVersion(@"10.0")? NO : YES;

    NSDictionary* settings = @{
                                  [@"MinimumFontSize" lowercaseString] : @1.1, // default is 0.0
                                  [@"AllowInlineMediaPlayback" lowercaseString] : @YES, // default is NO
                                  [@"MediaPlaybackRequiresUserAction" lowercaseString] : @(!mediaPlaybackRequiresUserActionDefault), // default is NO on iOS >= 10, YES for < 10
                                  [@"SuppressesIncrementalRendering" lowercaseString] : @YES, // default is NO
                                  [@"MediaPlaybackAllowsAirPlay" lowercaseString] : @NO, // default is YES
                                  [@"DisallowOverscroll" lowercaseString] : @YES, // so bounces is to be NO. defaults to NO
                                  [@"WKWebViewDecelerationSpeed" lowercaseString] : @"fast" // default is 'normal'
                                  };
    // this can be set because of the Category at the top of the file
    self.viewController.settings = [settings mutableCopy];
    
    // app settings are read after you register the plugin
    [self.viewController registerPlugin:self.plugin withClassName:NSStringFromClass([self.plugin class])];
    XCTAssert([self.plugin conformsToProtocol:@protocol(CDVWebViewEngineProtocol)], @"Plugin does not conform to CDVWebViewEngineProtocol");
    
    // after registering (thus plugin initialization), we can grab the webview configuration
    WKWebView* wkWebView = (WKWebView*)self.plugin.engineWebView;
    
    // the only preference we can set, we **can** change this during runtime
    XCTAssertEqualWithAccuracy(wkWebView.configuration.preferences.minimumFontSize, 1.1, 0.0001);
    
    // the WKWebViewConfiguration properties, we **cannot** change outside of initialization
    if (IsAtLeastiOSVersion(@"10.0")) {
        XCTAssertTrue(wkWebView.configuration.mediaPlaybackRequiresUserAction);
    } else {
        XCTAssertFalse(wkWebView.configuration.mediaPlaybackRequiresUserAction);
    }
    XCTAssertTrue(wkWebView.configuration.allowsInlineMediaPlayback);
    XCTAssertTrue(wkWebView.configuration.suppressesIncrementalRendering);
    // The test case below is in a separate test "testConfigurationWithMediaPlaybackAllowsAirPlay" (Apple bug) 
    // XCTAssertFalse(wkWebView.configuration.mediaPlaybackAllowsAirPlay);
    
    // in the test above, DisallowOverscroll is YES, so no bounce
    if ([wkWebView respondsToSelector:@selector(scrollView)]) {
        XCTAssertFalse(((UIScrollView*)[wkWebView scrollView]).bounces);
    } else {
        for (id subview in wkWebView.subviews) {
            if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                XCTAssertFalse(((UIScrollView*)subview).bounces = NO);
            }
        }
    }
    
    XCTAssertTrue(wkWebView.scrollView.decelerationRate == UIScrollViewDecelerationRateFast);
}

- (void) testConfigurationWithMediaPlaybackAllowsAirPlay {
    WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
    configuration.allowsAirPlayForMediaPlayback = NO;
    
    WKWebView* wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) configuration:configuration];
    
    XCTAssertFalse(configuration.allowsAirPlayForMediaPlayback);
    // Uh-oh, bug in WKWebView below. Tested on iOS 9, iOS 10 beta 3
    XCTAssertFalse(wkWebView.configuration.allowsAirPlayForMediaPlayback);    
}

@end
