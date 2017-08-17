require 'blinkr'
require 'minitest/reporters'
require 'webmock/minitest'
reporter_options = {color: true}
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]


def sitemap_stub
  "<?xml version='1.0' encoding='UTF-8'?>
   <urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>
   <url>
   <loc>#{__dir__}/test-site/blinkr.htm</loc>
   <lastmod>2017-06-14T11:21:47+01:00</lastmod>
   </url>
   </urlset>"
end

