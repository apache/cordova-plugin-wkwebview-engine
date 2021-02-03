<!--
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
-->

# Release Notes

### 1.2.2 (Feb 02, 2021)
* chore: adds package-lock file ([#165](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/165))
* refactor(eslint): use cordova-eslint /w fix ([#164](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/164))
* chore(npm): use short notation in `package.json` ([#163](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/163))
* added WKWebViewOnly to `README` ([#161](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/161))
* Added **iOS** platform version restrictions ([#158](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/158))
* chore(asf): update git notification settings ([306a0ee](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/306a0eeea63ac69da85b9518b34855e9e618aff4))
* Update CONTRIBUTING.md ([6c4cd10](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/6c4cd10f087fa95d272307d8fde932628b36f4ac))
* ci: updates Node.js versions ([#136](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/136))
* chore(npm): improve ignore list ([#137](https://github.com/apache/cordova-plugin-wkwebview-engine/pull/137))

### 1.2.1 (Jul 20, 2019)

-   fix: Revert "CB-13987: (ios) Fix WKWebView doesn't layout properly at… ([#107](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/107)) ([`dc8b277`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/dc8b277))
-   ci(travis): upgrade to node8 ([`d8c8b3f`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/d8c8b3f))
-   ci(appveyor): replace node 6 with node 12 ([`557e275`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/557e275))


### 1.2.0 (Jun 27, 2019)

-   build: add `.gitattributes` to force LF (instead of possible CRLF on Windows) ([`797f088`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/797f088))
-   build: add `.npmignore` to remove unneeded files from npm package ([`2ddcf98`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/2ddcf98))
-   chore: add CONTRBUTING.md and NOTICE files that were missing ([`a8390a2`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/a8390a2))
-   chore: fix repo and issue urls and license in package.json and plugin.xml ([`9d7c120`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/9d7c120))
-   ci(travis): Update Travis CI configuration for new paramedic ([#93](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/93)) ([`3697ee1`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/3697ee1))
-   chore: add `ecosystem:cordova` to package.json keywords ([`4b14897`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/4b14897))
-   chore: drop Node.js v4 support ([#91](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/91)) ([`1f1a888`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/1f1a888))
-   chore: remove leftover .jshintrc ([#90](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/90)) ([`54af786`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/54af786))
-   fix(ios): Bug fix in recent change in iOSExec.nativeCallback ([#78](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/78)) ([`6f468f4`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/6f468f4))
-   chore(github): Add or update GitHub pull request and issue template ([`76bca66`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/76bca66))
-   feat(ios): [GH-68](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/68) (ios): Support for disabling 3D Touch link previews ([#69](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/69)) ([`d0bd80a`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/d0bd80a))
-   fix(ios): [CB-12815](https://issues.apache.org/jira/browse/CB-12815) (ios) Fix bug nativeCallback not executed when app is in background ([#49](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/49)) ([`bf0f236`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/bf0f236))
-   chore: Add cordova-ios in plugin keyword for npm plugin searching ([#47](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/47)) ([`4f8503d`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/4f8503d))
-   fix(ios): [CB-13987](https://issues.apache.org/jira/browse/CB-13987) (ios) Fix WKWebView doesn't layout properly at launch on iPhone X ([`7684545`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/7684545), [`81eeade`](https://github.com/apache/cordova-plugin-wkwebview-engine/commit/81eeade))


### 1.1.4 (Nov 06, 2017)
* added missing license header
* [CB-13519](https://issues.apache.org/jira/browse/CB-13519) (all): Add 'protective' entry to `cordovaDependencies`
* [CB-12895](https://issues.apache.org/jira/browse/CB-12895) added `eslint` and removed `jshint`
* [CB-12847](https://issues.apache.org/jira/browse/CB-12847) fixed `bugs` entry in `package.json`.

### 1.1.3 (Apr 27, 2017)
* [CB-12696](https://issues.apache.org/jira/browse/CB-12696) (iOS) Fixing some Xcode warnings
* [CB-12685](https://issues.apache.org/jira/browse/CB-12685) added `package.json` to tests folder
* [CB-12575](https://issues.apache.org/jira/browse/CB-12575) cordova-plugin-wkwebview-engine missing LICENSE file
* [CB-12519](https://issues.apache.org/jira/browse/CB-12519) added missing license header

### 1.1.2 (Feb 28, 2017)
* [CB-12497](https://issues.apache.org/jira/browse/CB-12497) `location.href` links are silently disallowed
* [CB-12490](https://issues.apache.org/jira/browse/CB-12490) - Updated experimental plugin link
* Allow to configure navigation by gestures
* [CB-12297](https://issues.apache.org/jira/browse/CB-12297) Support `WKProcessPool` for cookie sharing
* [CB-12414](https://issues.apache.org/jira/browse/CB-12414) **iOS:** Forward error from provisional load error to standard load error

### 1.1.1 (Dec 07, 2016)
* [CB-12224](https://issues.apache.org/jira/browse/CB-12224) Updated version and RELEASENOTES.md for release 1.1.1
* [CB-10228](https://issues.apache.org/jira/browse/CB-10228) - AppendUserAgent not working with WKWebView
* [CB-11997](https://issues.apache.org/jira/browse/CB-11997) - Add crash recovery for iOS 8
* [CB-11917](https://issues.apache.org/jira/browse/CB-11917) - Remove pull request template checklist item: "iCLA has been submitted…"
* [CB-11818](https://issues.apache.org/jira/browse/CB-11818) - Avoid retain cycle: WKUserContentController retains its message handler, to break it we cannot pass directly CDVWKWebViewEngine's instance
* [CB-11832](https://issues.apache.org/jira/browse/CB-11832) Incremented plugin version.


### 1.1.0 (Sep 08, 2016)
* [CB-11824](https://issues.apache.org/jira/browse/CB-11824) - Update tests to include objective-c tests
* [CB-11554](https://issues.apache.org/jira/browse/CB-11554) - fixed unit tests
* [CB-11815](https://issues.apache.org/jira/browse/CB-11815) (**iOS**) Fix hard-coded bridge name "cordova"
* [CB-11554](https://issues.apache.org/jira/browse/CB-11554) - too 'brutal' app reload when title is empty
* [CB-11074](https://issues.apache.org/jira/browse/CB-11074) - Ensure settings from `config.xml` are taken into consideration
* Add ability to set the deceleration rate for the scrollview to 'fast'
* [CB-11496](https://issues.apache.org/jira/browse/CB-11496) - Add obj-c unit tests for `WKWebViewConfiguration`, `WKPreference`
* [CB-11496](https://issues.apache.org/jira/browse/CB-11496) - Create Obj-C unit-tests for `wkwebview-engine` (fix linker error)
* [CB-11452](https://issues.apache.org/jira/browse/CB-11452) - Update README.md with latest news about `AllowInlineMediaPlayback` fix
* [CB-9888](https://issues.apache.org/jira/browse/CB-9888) (**iOS**) check & reload `WKWebView`
* [CB-11375](https://issues.apache.org/jira/browse/CB-11375) - `onReset` method of `CDVPlugin` is never called
* Add pull request template.
* [CB-10818](https://issues.apache.org/jira/browse/CB-10818) - Support the scroll deceleration speed preference.
* [CB-10817](https://issues.apache.org/jira/browse/CB-10817) - Will now reload the `webView` if a crash occurs

### 1.0.3 (Apr 15, 2016)
* [CB-10636](https://issues.apache.org/jira/browse/CB-10636) Add `JSHint` for plugins

### 1.0.2 (Feb 09, 2016)
* [CB-10269](https://issues.apache.org/jira/browse/CB-10269) - Replace cordova exec only when present in wkwebview
* [CB-10202](https://issues.apache.org/jira/browse/CB-10202) - Add README quirk about WKWebview does not work with the AllowInlineMediaPlayback preference


### 1.0.1 (Dec 11, 2015)

* [CB-10190](https://issues.apache.org/jira/browse/CB-10190) - WKWebView engine is not releasing the user-agent lock

### 1.0.0 (Dec 04, 2015)

* [CB-10146](https://issues.apache.org/jira/browse/CB-10146) - Add to README WKWebViewEngine quirks that will affect migration from UIWebView
* [CB-10133](https://issues.apache.org/jira/browse/CB-10133) - DataClone DOM Exception 25 thrown for postMessage
* [CB-10106](https://issues.apache.org/jira/browse/CB-10106) - added bridge proxy
* [CB-10107](https://issues.apache.org/jira/browse/CB-10107) - nativeEvalAndFetch called for all bridges
* [CB-10106](https://issues.apache.org/jira/browse/CB-10106) - iOS bridges need to take into account bridge changes
* [CB-10073](https://issues.apache.org/jira/browse/CB-10073) - WKWebViewEngine should post CDVPluginResetNotification
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) Updated RELEASENOTES to be newest to oldest
* [CB-10002](https://issues.apache.org/jira/browse/CB-10002) - WKWebView should propagate shouldOverrideLoadWithRequest to plugins
* [CB-9979](https://issues.apache.org/jira/browse/CB-9979) [CB-9972](https://issues.apache.org/jira/browse/CB-9972) Change ATS link to new link
* [CB-9636](https://issues.apache.org/jira/browse/CB-9636) - Plugin should detect at runtime iOS 8 and use of file:// url and present an error
* [CB-8839](https://issues.apache.org/jira/browse/CB-8839) - WKWebView ignores DisallowOverscroll preference
* [CB-8556](https://issues.apache.org/jira/browse/CB-8556) - fix handleOpenURL for WKWebViewEngine plugin
* [CB-8666](https://issues.apache.org/jira/browse/CB-8666) - Update CDVWKWebViewEngine plugin to use 4.0.x branch code


