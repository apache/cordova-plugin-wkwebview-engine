Cordova WKWebView Engine
======

This plugin makes `Cordova` use the `WKWebView` component instead of the default `UIWebView` component, and is installable only on a system with the iOS 9.0 SDK. 

In iOS 9, Apple has fixed the [issue](http://www.openradar.me/18039024) present through iOS 8 where you cannot load locale files using file://, and must resort to using a local webserver. **However, you are still not able to use XHR from the file:// protocol without [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS) enabled on your server.**

Installation
-----------

This plugin needs to use the master branch of `cordova-ios` which is the next release of cordova-ios (4.0.0).

To `alpha test` this:

    cordova create wkwvtest my.project.id wkwvtest
    cd wkwvtest
    cordova platform add https://github.com/apache/cordova-ios.git#master
    cordova plugin add https://github.com/apache/cordova-plugin-wkwebview-engine.git#master
    
You also must have Xcode 7 and the iOS 9 SDK installed. If you have this and are still getting this error:

`Plugin doesn't support this project's apple-ios version. apple-ios: 8.4.0, failed version requirement: >=9.0`

You may need to switch to your Xcode Beta installation, using this command:

`sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer`

To switch back:

`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

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
