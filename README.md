Cordova WKWebView Engine
======

This plugin makes `Cordova` use the `WKWebView` component (new in iOS 8.0) instead of the default `UIWebView` component.

This will also install the `Cordova Local WebServer` plugin.

This plugin currently needs to use the `4.0.x` branch of `cordova-ios`.

To `alpha test` this:

    cordova create wkwvtest my.project.id wkwvtest
    cd wkwvtest
    cordova platform add https://github.com/apache/cordova-ios.git#4.0.x
    cordova plugin add https://github.com/apache/cordova-plugins.git#master:wkwebview-engine

Permissions
-----------

#### config.xml

        <feature name="CDVWKWebViewEngine">
            <param name="ios-package" value="CDVWKWebViewEngine" />
        </feature>

        <preference name="CordovaWebViewEngine" value="CDVWKWebViewEngine" />

Supported Platforms
-------------------

- iOS

Known Issues
-------------------

When you build, it might complain of a linking error. This is a `plugman` bug that does not install `WebKit.framework` properly. Open up your project file in `Xcode` and add it manually.

If you are using the CLI, open `Xcode` by:

        open -a Xcode platforms/ios
