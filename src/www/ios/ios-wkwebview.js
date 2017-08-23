var exec = require('cordova/exec');

var WkWebKit = {
    allowsBackForwardNavigationGestures: function (allow) {
        exec(null, null, 'CDVWKWebViewEngine', 'allowsBackForwardNavigationGestures', [allow]);
    }
};

module.exports = WkWebKit;
