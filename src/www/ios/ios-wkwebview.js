var exec = require('cordova/exec');

const WkWebKit = {
    allowsBackForwardNavigationGestures: function(allow) {
        exec(null, null, "CDVWKWebViewEngine", "allowsBackForwardNavigationGestures", [allow]);
    }
}

module.exports = WkWebKit
