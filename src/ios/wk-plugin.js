
(function _wk_plugin() {
  // Check if we are running in WKWebView
  if (!window.webkit) {
    return;
  }

  if (!window.webkit.messageHandlers) {
    return;
  }

  var stopScrollHandler = window.webkit.messageHandlers.stopScroll;
  if (!stopScrollHandler) {
    return;
  }

  var stopScrollFunc = null;
  window.IonicStopScroll = {
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
  console.debug("Ionic Stop Scroll injected!");
})();
