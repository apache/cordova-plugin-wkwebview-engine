(function _wk_xhr_proxy() {
  // Check if we are running in WKWebView
  if (!window.webkit.messageHandlers) {
    return;
  }

  var originalReferenceKey = '__wk_original';
  var xhrMessager = window.webkit.messageHandlers.xhr;
  var loc = window.location.protocol;

  // Do not hijack XHR if location is not file:
  if (!xhrMessager || loc !== 'file:') {
    return;
  }

  // Get original XHR implementaton
  var OriginalXHR = window.XMLHttpRequest;
  if (!OriginalXHR) {
    console.error('XHR polyfill: XMLHttpRequest does not exist!??');
    return;
  }

  // Constructs the XHR proxy
  var XHRProxy = function () {
    this.__fakeData = null;
    this.__fakeListeners = {};
    this[originalReferenceKey] = new OriginalXHR();
  };
  var XHRPrototype = XHRProxy.prototype;
  var xhrInstance = new OriginalXHR(function () {});

  // XHRProxy must proxy all methods/properties of the base class
  function configProperty(property) {
    if (typeof xhrInstance[property] === 'function') {
      XHRPrototype[property] = function () {
        return this[originalReferenceKey][property].apply(this[originalReferenceKey], arguments);
      };
    } else {
      Object.defineProperty(XHRPrototype, property, {
        enumerable: true,
        configurable: true,
        set: function (f) {
          this[originalReferenceKey][property] = f;
        },
        get: function () {
          var v = this.__get(property);
          if (v !== undefined) {
            return v;
          }
          return this[originalReferenceKey][property];
        }
      });
    }
  }
  for (var property in xhrInstance) {
    configProperty(property);
  }
  for (var property in OriginalXHR) {
    if (property !== 'prototype' && OriginalXHR.hasOwnProperty(property)) {
      XHRProxy[property] = OriginalXHR[property];
    }
  }


  XHRPrototype.open = function _wk_open(method, url, async) {
    if (!(/^[a-zA-Z0-9]+:\/\//.test(url))) {
      console.debug("XHR polyfill: open() intercepted XHR:", url);
      this.__setURL(url);
      this.__set('readyState', 1); // OPENED
      this.__set('status', 0);
      this.__set('responseText', '');

      this.__fireEvent('Event', 'readystatechange');

      if (async === false) {
        throw new Error("XHR polyfill: wk does not support sync XHR.");
      }
    }
    var original = this[originalReferenceKey];
    return original.open.apply(original, arguments);
  };

  XHRPrototype.send = function _wk_send() {
    if (this.__fakeData) {
      this.__set('readyState', 3);
      this.__fireEvent('Event', 'readystatechange');
      return scheduleXHRRequest(this, this.__getURL());
    }

    var original = this[originalReferenceKey];
    return original.send.apply(original, arguments);
  };

  XHRPrototype.addEventListener = function _wk_addEventListener(eventName, handler) {
    console.debug('XHR polyfill: _wk_addEventListener', eventName);
    if (this.__fakeListeners.hasOwnProperty(eventName)) {
      this.__fakeListeners[eventName].push(handler);
    } else {
      this.__fakeListeners[eventName] = [handler];
    }
    var original = this[originalReferenceKey];
    return original.addEventListener.apply(original, arguments);
  };

  XHRPrototype.removeEventListener = function _wk_removeEventListener(eventName, handler) {
    console.debug('XHR polyfill: _wk_removeEventListener', eventName);
    if (!this.__fakeListeners.hasOwnProperty(eventName)) {
      return;
    }

    var index = this.__fakeListeners[eventName].indexOf(handler);
    if (index !== -1) {
      this.__fakeListeners[eventName].splice(index, 1);
    }
    var original = this[originalReferenceKey];
    return original.removeEventListener.apply(original, arguments);
  };

  XHRPrototype.__fireEvent = function _wk_fireEvent(type, name) {
    var handlers = null;
    var event = document.createEvent(type);
    event.initEvent(name, false, false);

    // TODO: config event.target

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

  XHRPrototype.__set = function _wk_set(key, value) {
    if (!this.__fakeData) {
      this.__fakeData = {};
    }
    this.__fakeData['__' + key] = value;
  };

  XHRPrototype.__get = function _wk_get(key) {
    if (this.__fakeData) {
      return this.__fakeData['__' + key];
    }
  };

  XHRPrototype.__setURL = function _wk_setURL(url) {
    this.__set('interceptedURL', url);
  };

  XHRPrototype.__getURL = function _wk_getURL() {
    return this.__get('interceptedURL');
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

  function consumeContext(id) {
    var context = requests[id];
    if (!context) {
      return null;
    }
    requests[id] = null;
    return context;
  }

  function handleXHRResponse(id, base64) {
    var context = consumeContext(id);
    if (!context) {
      console.error("Context not found: ", id);
      return;
    }
    console.debug("XHR polyfill: Response received: ", context.__getURL());
    var buffer = decodeBase64(base64);
    switch (context.responseText) {
      case 'arraybuffer':
        context.__set('response', buffer);
        break;
      default:
        console.error('Unknown responseText:', context.responseText);
      case 'text':
      case '':
        var response = utf8Decode(buffer);
        context.__set('responseText', response);
        context.__set('response', response);
        break;
    }

    context.__set('readyState', 4);
    context.__set('status', 200);
    context.__set('statusText', 'OK');

    context.__fireEvent('Event', 'readystatechange');
    context.__fireEvent('UIEvent', 'load');
  }

  function handleXHRError(id, errorMessage) {
    var context = consumeContext(id);
    if (!context) {
      console.error("Context not found: ", id);
      return;
    }
    console.error("XHR polyfill:", errorMessage, context.__getURL());

    context.__set('readyState', 4);
    context.__set('status', 404);
    context.__set('statusText', 'Not Found');

    context.__fireEvent('Event', 'readystatechange');
    context.__fireEvent('UIEvent', 'error');
  }

  window.handleXHRResponse = handleXHRResponse;
  window.handleXHRError = handleXHRError;
  window.XMLHttpRequest = XHRProxy;

  console.debug("XHR polyfill: injected!");



  /*
  * base64-arraybuffer
  * https://github.com/niklasvh/base64-arraybuffer
  *
  * Copyright (c) 2012 Niklas von Hertzen
  * Licensed under the MIT license.
  */
  var base64key = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  // Use a lookup table to find the index.
  var lookup = new Uint8Array(256);
  for (var i = 0; i < base64key.length; i++) {
    lookup[base64key.charCodeAt(i)] = i;
  }

  function decodeBase64(base64) {
    var bufferLength = base64.length * 0.75,
    len = base64.length, i, p = 0,
    encoded1, encoded2, encoded3, encoded4;

    if (base64[base64.length - 1] === "=") {
      bufferLength--;
      if (base64[base64.length - 2] === "=") {
        bufferLength--;
      }
    }

    var arraybuffer = new ArrayBuffer(bufferLength),
    bytes = new Uint8Array(arraybuffer);

    for (i = 0; i < len; i+=4) {
      encoded1 = lookup[base64.charCodeAt(i)];
      encoded2 = lookup[base64.charCodeAt(i+1)];
      encoded3 = lookup[base64.charCodeAt(i+2)];
      encoded4 = lookup[base64.charCodeAt(i+3)];

      bytes[p++] = (encoded1 << 2) | (encoded2 >> 4);
      bytes[p++] = ((encoded2 & 15) << 4) | (encoded3 >> 2);
      bytes[p++] = ((encoded3 & 3) << 6) | (encoded4 & 63);
    }

    return arraybuffer;
  }

  function utf8Decode(buf) {
    var bytes = new Uint8Array(buf);
    var res = '';
    var tmp = '';
    var end = bytes.byteLength;
    for (var i = 0; i < end; i++) {
      if (bytes[i] <= 0x7F) {
        res += decodeUtf8Char(tmp) + String.fromCharCode(bytes[i]);
        tmp = '';
      } else {
        tmp += '%' + bytes[i].toString(16);
      }
    }

    return res + decodeUtf8Char(tmp);
  }

  function decodeUtf8Char (str) {
    try {
      return decodeURIComponent(str);
    } catch (err) {
      return String.fromCharCode(0xFFFD); // UTF 8 invalid char
    }
  }

})();
