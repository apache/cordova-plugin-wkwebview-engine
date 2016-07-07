
(function _wk_xhr_proxy() {
  if (!window.webkit.messageHandlers) {
    return;
  }

  var xhrMessager = window.webkit.messageHandlers.xhr;
  var loc = window.location.protocol;
  if (!xhrMessager || loc !== 'file:') {
    return;
  }

  var originalInstanceKey = '__wk_original'

  // Adapted from zone.js
  var OriginalClass = window.XMLHttpRequest;

  if (!OriginalClass) {
    console.error('XMLHttpRequest does not exist!??');
    return;
  }

  var XHRProxy = function () {
    this.__fakeData = null;
    this[originalInstanceKey] = new OriginalClass();
  };

  var instance = new OriginalClass(function () {});

  var prop;
  for (prop in instance) {
    (function (prop) {
      if (typeof instance[prop] === 'function') {
        XHRProxy.prototype[prop] = function () {
          return this[originalInstanceKey][prop].apply(this[originalInstanceKey], arguments);
        };
      } else {
        Object.defineProperty(XHRProxy.prototype, prop, {
          enumerable: true,
          set: function (fn) {
            this[originalInstanceKey][prop] = fn;
          },
          get: function () {
            var v = this.__get(prop);
            if (v !== undefined) {
              return v;
            }
            return this[originalInstanceKey][prop];
          }
        });
      }
    }(prop));
  }

  for (prop in OriginalClass) {
    if (prop !== 'prototype' && OriginalClass.hasOwnProperty(prop)) {
      XHRProxy[prop] = OriginalClass[prop];
    }
  }

  // Patch XML class
  XHRProxy.prototype.open = function _wk_open(method, url, async) {
    if (!(/^[a-zA-Z0-9]+:\/\//.test(url))) {
      console.debug("WK intercepted XHR:", url);
      this.__set('readyState', 1); // OPENED
      this.__set('status', 0);
      this.__set('responseText', '');
      this.__set('interceptedURL', url);

      this.__fireEvent('Event', 'readystatechange');

      if (async === false) {
        throw new Error("wk does not support sync XHR.")
      }
    }
    var original = this[originalInstanceKey];
    return this[originalInstanceKey].open.apply(this[originalInstanceKey], arguments);
  };

  XHRProxy.prototype.send = function _wk_send() {
    if (this.__fakeData) {
      this.__set('readyState', 3);
      this.__fireEvent('ProgressEvent', 'loadstart');
      this.__fireEvent('Event', 'readystatechange');
      var url = this.__get('interceptedURL');
      return scheduleXHRRequest(this, url);
    }

    var original = this[originalInstanceKey];
    return original.send.apply(original, arguments);
  };

  XHRProxy.prototype.__fireEvent = function _wk_fire(type, name) {
    var event = document.createEvent(type);
    event.initEvent(name, false, false);
    this.dispatchEvent(event);
  };

  XHRProxy.prototype.__set = function _wk_set(key, value) {
    if (!this.__fakeData) {
      this.__fakeData = {};
    }
    this.__fakeData['__' + key] = value;
  };

  XHRProxy.prototype.__get = function _wk_get(key) {
    if (this.__fakeData) {
      return this.__fakeData['__' + key];
    }
  };


  var reqId = 1;
  var requests = {};

  function scheduleXHRRequest(context, url) {
    requests[reqId] = context;

    xhrMessager.postMessage(JSON.stringify({
      id: reqId,
      url: url
    }));
    reqId++;
  };

  function handleXHRResponse(id, body) {
    var context = requests[id];
    if (!context) {
      console.error("Context not found: ", id);
      return;
    }
    requests[id] = null;

    context.__set('readyState', 4);
    context.__set('status', 200);
    context.__set('responseText', body);
    context.__set('response', body);

    context.__fireEvent('Event', 'readystatechange');
    context.__fireEvent('UIEvent', 'load');
    context.__fireEvent('ProgressEvent', 'loadend');
  };

  window.handleXHRResponse = handleXHRResponse;
  window.XMLHttpRequest = XHRProxy;

  console.debug("XHR polyfill injected!");
})();
