Cordova WKWebView Engine
======

This plugin makes Cordova use the WKWebView component (new in iOS 8.0) instead of the default UIWebView component.

This will also install the Cordova Local Web Server plugin (TODO: move this into Labs)

Permissions
-----------

#### config.xml

            <feature name="CDVWKWebViewEngine">
                <param name="ios-package" value="CDVWKWebViewEngine" />
            </feature>

Supported Platforms
-------------------

- iOS
