require_relative '../../test/unit-test/test_helper'
require 'minitest/autorun'
require 'mocha/mini_test'

class TestBlinkr < Minitest::Test

  describe Blinkr::Config do

    it 'should raise an error if it cannot read config file' do
      options = {}
      args = {}
      options[:config_file] = '/no/way/this/exists.yaml'
      exception = assert_raises(RuntimeError) {
        Blinkr::Config.read(options[:config_file], args)
      }
      assert_equal("Cannot read #{options[:config_file]}", exception.message)
    end

    it 'should create a default hash when no config is specified' do
      options = {}
      expected_default_hash = { skips: [], ignores: [], environments: [], max_retrys: 3,
                               browser: 'phantomjs', viewport: 1200, phantomjs_threads: 10,
                               report: 'blinkr.html', warning_on_300s: false,
                               ignore_internal: false, ignore_external: false,
                               warn_js_errors: false, warn_inline_css: false,
                               ignore_ssl: false, warn_resource_errors: false }.freeze

      actual_hash = Blinkr::Config.new(options)
      assert_equal(expected_default_hash, actual_hash.to_h)
    end

    it 'should create a merged Hash of user specified config options and default config options' do
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_blinkr.yaml"
      actual_hash = Blinkr::Config.read(options[:config_file], args)
      expected_hash = { skips: [/^http:\/\/(www\.)?example\.com\/foo/], ignores: [], environments: [], max_retrys: 3, browser: 'phantomjs', viewport: 1200, phantomjs_threads:20, report: 'blinkr.html', warning_on_300s: false, ignore_internal: false, ignore_external: false, warn_js_errors: false, warn_inline_css: false, ignore_ssl: false, warn_resource_errors: false, base_url: 'http://www.example.com/', max_page_retrys: 3, ignore_fragments: true, config_file:"#{__dir__}/config/valid_blinkr.yaml" }
      assert_equal expected_hash.to_s, actual_hash.to_h.to_s
    end

    it 'validate raises an error when ignores does not contain a Hash' do
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/invalid_ignores.yaml"
      exception = assert_raises(RuntimeError) {
        Blinkr::Config.read(options[:config_file], args).validate
      }
      assert_equal('An ignore must be a hash', exception.message)
    end

    it 'validate raises an error when base_url is not specified' do
      options = {}
      exception = assert_raises(RuntimeError) {
        Blinkr::Config.new(options).validate
      }
      assert_equal('Must specify base_url', exception.message)
    end

    it 'validate raises an error when sitemap is not specified' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      exception = assert_raises(RuntimeError) {
        config = Blinkr::Config.new(options)
        config.stubs(:sitemap).with(nil)
        config.validate
      }
      assert_equal('Must specify sitemap', exception.message)
    end

    it 'sitemap appends base_url with /sitemap.xml if not specified' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      assert_equal(Blinkr::Config.new(options).sitemap, "#{options[:base_url]}/sitemap.xml")
    end

    it 'accepts user specified sitemap' do
      options = {}
      options[:sitemap] = 'http://www.foo.com/sitemap.xml'
      options[:base_url] = 'http://www.example.com'
      assert_equal(Blinkr::Config.new(options).sitemap, "#{options[:sitemap]}")
    end

    it 'accepts sitemap as local xml filetype' do
      options = {}
      options[:sitemap] = "#{__dir__}/config/sitemap.xml"
      options[:base_url] = 'http://www.example.com'
      assert_equal(Blinkr::Config.new(options).sitemap, "#{options[:sitemap]}")
    end

    it 'max_page_retrys raises an error if nil' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      options[:max_retrys] = nil
      exception = assert_raises(RuntimeError) {
        config = Blinkr::Config.new(options)
        config.max_page_retrys
      }
      assert_equal('Retrys is nil', exception.message)
    end

    it 'ignores containing url option can be specified in Regex' do
      error = Blinkr::Error.new(severity: 'danger',
                                category: 'Broken link',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.example.com/foo', title: 'Foobar',
                                code: 500, message: 'Foobar',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_regex_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, true)
    end

    it 'ignores containing url can be specified as a string' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.example.com/foo', title: 'Foobar',
                                code: 500, message: 'Foobar',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, true)
    end

    it 'ignores option returns boolean (false) when no matched urls are found' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 500, message: 'Foobar',
                                detail: 'detail', snippet: "<a href='/foo/'>Oh Hi</a>",
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, false)
    end

    it 'ignores option ignore user specified error codes' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 404, message: 'Foobar',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, true)
    end

    it 'returns false when no matched error codes are found' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 503, message: 'Foobar',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, false)
    end


    it 'ignores option can ignore user specified messages ' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 500, message: 'Not Found',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, true)
    end

    it 'returns false when no matched messages are found' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 503, message: 'Foobar',
                                detail: 'detail', snippet: '',
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, false)
    end


    it 'ignores option can ignore user specified snippet' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 500, message: 'Foobar',
                                detail: 'detail', snippet: "<a href='/foo/'>I'm a link</a>",
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, true)
    end

    it 'returns false when no matched ignored snippets are found' do
      error = Blinkr::Error.new(severity: 'danger',
                                type: '<a href=""> target cannot be loaded',
                                url: 'http://www.foo.com/bar', title: 'Foobar',
                                code: 503, message: 'Foobar',
                                detail: 'detail', snippet: "<a href='/foo/'>Oh Hi</a>",
                                icon: 'fa-bookmark-o')
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_string_ignores.yaml"
      ignores = Blinkr::Config.read(options[:config_file], args).ignored?(error)
      assert_equal(ignores, false)
    end

    it 'skips option must ignore user configured links/pages specified in String' do
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_skips.yaml"
      skips = Blinkr::Config.read(options[:config_file], args).skipped?('http://www.example.com/bar')
      assert_equal(true, skips)
    end

    it 'skips option must ignore user configured links/pages specified in Regex' do
      options = {}
      args = {}
      options[:config_file] = "#{__dir__}/config/valid_skips.yaml"
      skips = Blinkr::Config.read(options[:config_file], args).skipped?('http://www.example.com/regex')
      assert_equal(true, skips)
    end

  end
end
