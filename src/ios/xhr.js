

(function _wkionic_main() {
  if (!window.webkit.messageHandlers) {
    return;
  }
 
  var scrollbar = window.webkit.messageHandlers.ionic_scrollbar;
  window.ionicUpdateContentMargin = function(width, height, marginTop, marginBottom) {
    var message = width + ':' + height + ':' + marginTop + ':' + marginBottom;
    scrollbar.postMessage(message);
  }

 
  var wkionic = window.webkit.messageHandlers.xhr;
  var loc = window.location.protocol;
  if (!wkionic || loc !== 'file:') {
    return;
  }

  // create XMLHttpRequest proxy object
  var oldXMLHttpRequest = window.XMLHttpRequest;

  // define constructor for my proxy object
  XMLHttpRequest = function () {
    var originalXHR = new oldXMLHttpRequest();
    this.intercepted = false;
    this.interceptedURL = '';
    this.originalXHR = originalXHR;
  }

  XMLHttpRequest.UNSENT = 0;
  XMLHttpRequest.OPENED = 1;
  XMLHttpRequest.HEADERS_RECEIVED = 2;
  XMLHttpRequest.LOADING = 3;
  XMLHttpRequest.DONE = 4;

  
  // add all proxy getters
  var getters = ["status", "statusText", "response", "responseText", "readyState", "responseXML", "upload"];
  getters.forEach(function (item) {
    Object.defineProperty(XMLHttpRequest.prototype, item, {
      configurable: false,
      enumerable: true,
      get: function () {
        return (this.intercepted)
          ? this['__' + item]
          : this.originalXHR[item];
      },
    });
  });

    // add all getters/setters    
  var gettersSetters = ["ontimeout, timeout", "withCredentials", "responseType", "onload", "onerror", "onprogress", "onreadystatechange"];
  gettersSetters.forEach(function (item) {
    Object.defineProperty(XMLHttpRequest.prototype, item, {
      configurable: false,
      enumerable: true,
      get: function () { return this.originalXHR[item]; },
      set: function (val) { this.originalXHR[item] = val; }
    });
  });
  debugger;

  // add bypass
  var allBypass = ["addEventListener", "removeEventListener", "dispatchEvent", "abort", "getAllResponseHeaders", "getResponseHeader", "overrideMimeType", "setRequestHeader"];
  allBypass.forEach(function (item) {
    XMLHttpRequest.prototype[item] = function () {
      return this.originalXHR[item].apply(this.originalXHR, arguments);
    }
  });

  XMLHttpRequest.prototype.open = function _wk_open(method, url, async) {
    if (!(/^[a-zA-Z0-9]+:\/\//.test(url))) {
      console.debug("WKIonic intercepted XHR:", url);
      this.__readyState = 1; // OPENED
      this.__status = 0;
      this.__responseText = '';
      this.intercepted = true;
      this.interceptedURL = url;
      this._fireEvent('Event', 'readystatechange');

      if (async === false) {
        throw new Error("ionic wk does not support sync XHR.")
      }
    } else {
      console.debug("WKIonic NO intercepted XHR:", url);
      return this.originalXHR.open.apply(this.originalXHR, arguments);
    }
  };

  XMLHttpRequest.prototype.send = function _wk_send() {
    if (this.intercepted) {
      this.__readyState = 3; // LOADING
      this._fireEvent('ProgressEvent', 'loadstart');
      this._fireEvent('Event', 'readystatechange');
      return scheduleWKRequest(this, this.interceptedURL);
    } else {
      return this.originalXHR.send.apply(this.originalXHR, arguments);
    }
  }

  XMLHttpRequest.prototype._fireEvent = function (type, name) {
    debugger;
    console.debug("Firing event: ", name);
    var event = document.createEvent(type);
    event.initEvent(name, false, false);
    this.dispatchEvent(event);
  }

  
  console.debug("WKIonic polyfill injected");

  var reqcounter = 0;  
  var requests = {};

  function scheduleWKRequest(context, url) {
    requests[reqcounter] = context;
    var message = reqcounter + '->' + url;
    wkionic.postMessage(message);
    reqcounter++;
  }

  function handleXHRResponse(id, body) {
    var context = requests[id];
    if (!context) {
      console.error("Context not found: ", id);
      return;
    }
    delete requests[id];
    
    context.__readyState = 4;
    context.__status = 200;
    context.__responseText = body;
    context.__response = body;

    context._fireEvent('Event', 'readystatechange');
    context._fireEvent('UIEvent', 'load');    
    context._fireEvent('ProgressEvent', 'loadend');
  }
  window.handleXHRResponse = handleXHRResponse;
  
})();     
