// Render Multiple URLs to file

var renderUrlsToFile, system, fs, config;

system = require("system");
fs = require("fs");

/*
Render given urls
@param array of URLs to render
@param callbackPerUrl Function called after finishing each URL, including the last URL
@param callbackFinal Function called after finishing everything
*/
renderUrlsToFile = function(config, callbacks) {
  var getFilename, next, page, retrieve, urlIndex, webpage;
  urlIndex = 0;
  webpage = require("webpage");
  page = null;
  getFilename = function() {
    return "rendermulti-" + urlIndex + ".png";
  };
  next = function(status, url, file) {
    page.close();
    callbackPerUrl(status, url, file);
    return retrieve();
  };
  retrieve = function() {
    var url;
    if (urls.length > 0) {
      url = urls.shift();
      urlIndex++;
      page = webpage.create();
      page.viewportSize = {
        width: 800,
        height: 600
      };
      page.settings.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.17';
      return page.open("http://" + url, function(status) {
        var file;
                file = getFilename();
                if (status === "success") {
                    return window.setTimeout((function() {
                        page.render(file);
                        return next(status, url, file);
                    }), 200);
                } else {
                    return next(status, url, file);
                }
            });
        } else {
            return callbackFinal();
        }
    };
    return retrieve();
};

if (system.args.length !== 4) {
  console.log('Usage: snap.js <in> <out> <retries>');
  phantom.exit();
}
config = {};
config.inFile = system.args[1];
config.outFile = system.args[2];
config.retries = system.args[3];
config.urls = JSON.parse(fs.read(config.inFile));

renderUrlsToFile(config, {
    exit: function() {
      return phantom.exit();
    },
    onResourceRequested: function(req) {
      current_requests += 1;
    },
    onResourceReceived: function(resp) {
      if (resp.stage === 'end') {
        current_requests -= 1;
      }
      timeout();
    },
    onResourceError: function(metadata) {
      info.resourceErrors[info.resourceErrors.length] = metadata;
    },
  onError: function(msg, trace) {
      info.javascriptErrors[info.javascriptErrors.length] = {msg: msg, trace: trace};
    }
  }
);
