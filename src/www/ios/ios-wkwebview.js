/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var exec = require('cordova/exec');

var WkWebKit = {
    allowsBackForwardNavigationGestures: function (allow) {
        exec(null, null, 'CDVWKWebViewEngine', 'allowsBackForwardNavigationGestures', [allow]);
    },
    setCookie: function (url, name, value, successCallback, errorCallback) {
        const urlNoDomain = url.replace(/^https?:\/\//, '');
        const urlParts = urlNoDomain.split('/');
        const domain = urlParts.splice(0,1)[0];
        var path = urlParts.join('/');
    
        exec(successCallback, errorCallback, "CDVWKWebViewEngine",
          "setCookie", [domain, path, name ? name : "foo", value ? value : "bar"]);
    },
    injectCookie: function (url, successCallback, errorCallback) {
        this.setCookie(url, "foo", "bar", successCallback, errorCallback);
    }
};

module.exports = WkWebKit;
