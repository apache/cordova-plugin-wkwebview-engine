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
  for (property in xhrInstance) {
    configProperty(property);
  }
  for (property in OriginalXHR) {
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

  function handleXHRResponse(id, body) {
    var context = consumeContext(id);
    if (!context) {
      console.error("Context not found: ", id);
      return;
    }
    console.debug("XHR polyfill: Response received: ", context.__getURL());

    context.__set('readyState', 4);
    context.__set('status', 200);
    context.__set('statusText', 'OK');
    context.__set('responseType', 'text');
    context.__set('responseText', body);
    context.__set('response', body);

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
})();
