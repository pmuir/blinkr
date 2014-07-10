# Blinkr

A broken link checker for websites

## Installation

Add this line to your application's Gemfile:

    gem 'blinkr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blinkr

## Usage

To run blinkr against your site, assuming you have a `sitemap.xml` in the root of your site:

````
blinkr -u http://www.jboss.org
````

If you want to customize blinkr, create a config file `blinkr.yaml`. For example:

````
# Links not to check
skips:
  - !ruby/regexp /^\/video\/((?!91710755).)*\/$/
  - !ruby/regexp /^\/quickstarts\/((?!eap\/kitchensink).)*\/*$/
  - !ruby/regexp /^\/boms\/((?!eap\/jboss-javaee-6_0).)*\/*$/
  - !ruby/regexp /^\/archetypes\/((?!eap\/jboss-javaee6-webapp-archetype).)*\/*$/
# The output file to write the report to
report: _tmp/blinkr.html
# The URL to check
base_url: http://www.jboss.org
sitemap: http://www.jboss.org/my_sitemap.xml
````

Specify a custom config file on the command link:

````
blinkr -c my_blinkr.yaml
````

## Contributing

1. Fork it ( http://github.com/pmuir/blinkr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

