/*jshint loopfunc: true */
(function _wk_xhr_proxy() {
  if (!window.webkit.messageHandlers) {
    return;
  }

  var xhrMessager = window.webkit.messageHandlers.xhr;
  var loc = window.location.protocol;
  if (!xhrMessager || loc !== 'file:') {
    return;
  }

  var originalInstanceKey = '__wk_original';

  // Adapted from zone.js
  var OriginalClass = window.XMLHttpRequest;

  if (!OriginalClass) {
    console.error('XMLHttpRequest does not exist!??');
    return;
  }

  var XHRProxy = function () {
    this.__fakeData = null;
    this.__fakeListeners = {};
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
          configurable: true,
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
        throw new Error("wk does not support sync XHR.");
      }
    }
    var original = this[originalInstanceKey];
    return original.open.apply(original, arguments);
  };

  XHRProxy.prototype.send = function _wk_send() {
    if (this.__fakeData) {
      this.__set('readyState', 3);
      this.__fireEvent('Event', 'readystatechange');
      var url = this.__get('interceptedURL');
      return scheduleXHRRequest(this, url);
    }

    var original = this[originalInstanceKey];
    return original.send.apply(original, arguments);
  };

  XHRProxy.prototype.addEventListener = function _wk_addEventListener(eventName, handler) {
    console.debug('_wk_addEventListener', eventName);
    if (this.__fakeListeners.hasOwnProperty(eventName)) {
      this.__fakeListeners[eventName].push(handler);
    } else {
      this.__fakeListeners[eventName] = [handler];
    }
    var original = this[originalInstanceKey];
    return original.addEventListener.apply(original, arguments);
  };

  XHRProxy.prototype.removeEventListener = function _wk_removeEventListener(eventName, handler) {
    console.debug('_wk_removeEventListener', eventName);
    if (!this.__fakeListeners.hasOwnProperty(eventName)) {
      return;
    }

    var index = this.__fakeListeners[eventName].indexOf(handler);
    if (index !== -1) {
      this.__fakeListeners[eventName].splice(index, 1);
    }
    var original = this[originalInstanceKey];
    return original.removeEventListener.apply(original, arguments);
  };

  XHRProxy.prototype.__fireEvent = function _wk_fireEvent(type, name) {
    var handlers = null;
    var event = document.createEvent(type);
    event.initEvent(name, false, false);

    if (this.__fakeListeners.hasOwnProperty(name)) {
      handlers = this.__fakeListeners[name];
      for (var i = 0; i < handlers.length; i++) {
        try {
          handlers[i](event);
        } catch (e) {
          console.error(e);
        }
      }
    }

    var handler = this['on' + name];
    if (handler && (!handlers || handlers.indexOf(handler) === -1)) {
      handler(event);
    }
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
  }

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
  }

  window.handleXHRResponse = handleXHRResponse;
  window.XMLHttpRequest = XHRProxy;

  console.debug("XHR polyfill injected!");
})();
