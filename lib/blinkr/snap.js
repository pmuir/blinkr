var system = require('system');
var page = require('webpage').create();
var fs = require('fs');

if (system.args.length === 2) {
    console.log('Usage: snap.js <URL> <view port width>');
    phantom.exit();
}

var info = {};
info.resourceErrors = [];
info.javascriptErrors = [];
info.url = system.args[1];
info.view_port_width = system.args[2];

var current_requests = 0;
var last_request_timeout;
var final_timeout;


page.viewportSize = { width: info.view_port_width, height: 1500};
page.settings = { loadImages: true, javascriptEnabled: true };

// If you want to use additional phantomjs commands, place them here
page.settings.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.17';

// You can place custom headers here, example below.
// page.customHeaders = {

//      'X-Candy-OVERRIDE': 'https://api.live.bbc.co.uk/'
 
//  };

// If you want to set a cookie, just add your details below in the following way.

// phantom.addCookie({
//     'name': 'ckns_policy',
//     'value': '111',
//     'domain': '.bbc.co.uk'
// });
// phantom.addCookie({
//     'name': 'locserv',
//     'value': '1#l1#i=6691484:n=Oxford+Circus:h=e@w1#i=8:p=London@d1#1=l:2=e:3=e:4=2@n1#r=40',
//     'domain': '.bbc.co.uk'
// });

page.onResourceRequested = function(req) {
  current_requests += 1;
};

page.onResourceReceived = function(resp) {
  if (resp.stage === 'end') {
    current_requests -= 1;
  }
  timeout();
};

page.onResourceError = function(metadata) {
  info.resourceErrors[info.resourceErrors.length] = metadata;
}


page.onError = function(msg, trace) {
  info.javascriptErrors[info.javascriptErrors.length] = {msg: msg, trace: trace};
}

page.open(info.url, function(status) {
  if (status !== 'success') {
    exit(1);
  }
});

var exit = function exit(err_code) {
  info.content = page.content;
  // Re-read the URL in case we've been redirected
  info.url = page.url;
  system.stdout.write(JSON.stringify(info));
  if (err_code === undefined) {
    err_code = 0;
  }
  phantom.exit(err_code);
};

function timeout() {
  clearTimeout(last_request_timeout);
  clearTimeout(final_timeout);

  // If there's no more ongoing resource requests, wait for 1 second before
  // exiting, just in case the page kicks off another request
  if (current_requests < 1) {
      clearTimeout(final_timeout);
      last_request_timeout = setTimeout(exit, 1000);
  }

  // Sometimes, straggling requests never make it back, in which
  // case, timeout after 5 seconds and exit anyway
  // TODO record which requests timed out!
  final_timeout = setTimeout(exit, 5000);
}

