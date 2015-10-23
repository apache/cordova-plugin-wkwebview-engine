Cordova WKWebView Engine
======

This plugin makes `Cordova` use the `WKWebView` component instead of the default `UIWebView` component, and is installable only on a system with the iOS 9.0 SDK. 

In iOS 9, Apple has fixed the [issue](http://www.openradar.me/18039024) present through iOS 8 where you cannot load locale files using file://, and must resort to using a local webserver. **However, you are still not able to use XHR from the file:// protocol without [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS) enabled on your server.**

Installation
-----------

This plugin needs to use the master branch of `cordova-ios` which is the next release of cordova-ios (4.0.0).

To test this:

    cordova create wkwvtest my.project.id wkwvtest
    cd wkwvtest
    cordova platform add https://github.com/apache/cordova-ios.git#master
    cordova plugin add https://github.com/apache/cordova-plugin-wkwebview-engine.git#master

Currently, you will have to add the `master` version (>=1.1.1) of the cordova-plugin-whitelist, not the one in npm. So do this also:

    cordova plugin rm cordova-plugin-whitelist
	cordova plugin add https://github.com/apache/cordova-plugin-whitelist.git#master

   
You also must have Xcode 7 (iOS 9 SDK) installed. Check which Xcode command-line tools is in use by running:

    xcode-select --print-path


Notes
------

On an iOS 8 system, Apache Cordova during runtime will switch to using the UIWebView engine instead of using this plugin. If you want to use WKWebView on both iOS 8 and iOS 9 platforms, you will have to resort to using a local webserver.

We have an [experimental plugin](https://github.com/apache/cordova-plugins/tree/master/wkwebview-engine-localhost) that does this. You would use that plugin instead of this one.

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
