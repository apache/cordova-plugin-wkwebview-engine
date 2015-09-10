Cordova WKWebView Engine
======

This plugin makes `Cordova` use the `WKWebView` component instead of the default `UIWebView` component, and is installable only on a system with the iOS 9.0 SDK.


This plugin needs to use the master branch of `cordova-ios` which is the next release of cordova-ios (4.0.0).

To `alpha test` this:

    cordova create wkwvtest my.project.id wkwvtest
    cd wkwvtest
    cordova platform add https://github.com/apache/cordova-ios.git#master
    cordova plugin add https://github.com/apache/cordova-plugin-wkwebview-engine.git#master

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
