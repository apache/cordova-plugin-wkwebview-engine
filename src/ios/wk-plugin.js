
(function _wk_plugin() {
  // Check if we are running in WKWebView
  if (!window.webkit || !window.webkit.messageHandlers) {
    return;
  }

  // Initialize Ionic
  window.Ionic = window.Ionic || {};

  function normalizeURL(url) {
    if (!url) {
      return url;
    }
    if (!url.startsWith("file://")) {
      return url;
    }
    url = url.substr(7); // len("file://") == 7
    if (url.length == 0 || url[0] !== '/') { // ensure the new URL starts with /
      url = '/' + url;
    }
    return 'http://localhost:8080' + url;
  }
  if (typeof window.wkRewriteURL === 'undefined') {
    window.wkRewriteURL = function (url) {
      console.warn('wkRewriteURL is deprecated, use normalizeURL instead');
      return normalizeURL(url);
    }
  }
  window.Ionic.normalizeURL = normalizeURL;

  var xhrPrototype = window.XMLHttpRequest.prototype;
  var originalOpen = xhrPrototype.open;

  xhrPrototype.open = function _wk_open(method, url) {
    arguments[1] = normalizeURL(url);
    originalOpen.apply(this, arguments);
  }
  console.debug("XHR polyfill injected!");

  var stopScrollHandler = window.webkit.messageHandlers.stopScroll;
  if (!stopScrollHandler) {
    console.error('Can not find stopScroll handler');
    return;
  }

  var stopScrollFunc = null;
  var stopScroll = {
    stop: function stop(callback) {
      if (!stopScrollFunc) {
        stopScrollFunc = callback;
        stopScrollHandler.postMessage('');
      }
    },
    fire: function fire() {
      stopScrollFunc && stopScrollFunc();
      stopScrollFunc = null;
    },
    cancel: function cancel() {
      stopScrollFunc = null;
    }
  };

  window.Ionic.StopScroll = stopScroll;
  // deprecated
  window.IonicStopScroll = stopScroll;

  console.debug("Ionic Stop Scroll injected!");
})();
