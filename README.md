<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

Cordova WKWebView Engine
======

This plugin is an extension of the [Apache Cordova WKWebView plugin](https://github.com/apache/cordova-plugin-wkwebview-engine). It includes enhancements to resolve some of the issues surrounding XHR requests, along with some DOM exception issues. Ionic is working with the Cordova team
to fully test these changes with the eventual goal of merging the updates into the official Cordova plugin. After the beta testing period, our hope is to make the WKWebView plugin an Ionic default so all users can easily take advantage of this plugin's improved performance over UIWebView.

The WKWebView plugin is only used by iOS, so ensure the `cordova-ios` platform is installed. Additionly, the `cordova-ios` platform version must be `4.0` or greater.

Installation Instructions
-------------------

Ensure the latest Cordova CLI is installed:  (Sudo may be required)

```
npm install cordova -g
```

Ensure the `ios` platform has been added:

```
ionic platform ls
```

If the iOS platform is not listed, run the following command:

```
ionic platform add ios
```

If the iOS platform is installed but the version is < `4.x`, run the following commands:

```
ionic platform update ios
ionic plugin save           # creates backup of existing plugins
rm -rf ./plugins            # delete plugins directory
ionic prepare               # re-install plugins compatible with cordova-ios 4.x
```

Install the WKWebViewPlugin:

```
ionic plugin add https://github.com/driftyco/cordova-plugin-wkwebview-engine.git --save
```

Build the platform:

```
ionic prepare
```

Test the app on an iOS 9 or 10 device:

```
ionic run ios
```

An easy way to verify that WKWebView has been installed on iOS is to check if `window.indexedDB` exists.  For example:

```
if (window.indexedDB) {
   console.log("I'm in WKWebView!");
} else {
   console.log("I'm in UIWebView");
}
```
