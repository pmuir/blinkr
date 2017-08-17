require_relative '../../test/unit-test/test_helper'
require 'minitest/autorun'
require 'mocha/mini_test'
require 'blinkr/sitemap'

class TestBlinkr < Minitest::Test

  describe Blinkr::Sitemap do

    before do
      # make private method testable by switching it to public
      # for the purposes of testing only.
      Blinkr::Sitemap.send(:public, :open_sitemap)
    end

    it 'loads sitemap from locally stored sitemap' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      options[:sitemap] = "#{__dir__}/config/sitemap.xml"
      @config = Blinkr::Config.new(options)
      sitemap = Blinkr::Sitemap.new(@config).open_sitemap
      assert_includes(sitemap.to_s, 'http://www.example.com/home')
    end

    it 'loads sitemap from URL' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      stub_request(:get, "#{options[:base_url]}/sitemap.xml").to_return(status: 200, body: sitemap_stub, :headers => {})
      @config = Blinkr::Config.new(options)
      sitemap = Blinkr::Sitemap.new(@config).open_sitemap

      assert_includes(sitemap.to_s, 'test-site/blinkr.htm')
    end

    it 'returns sitemap locations' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      stub_request(:get, "#{options[:base_url]}/sitemap.xml").to_return(status: 200, body: sitemap_stub, :headers => {})
      @config = Blinkr::Config.new(options)
      sitemap = Blinkr::Sitemap.new(@config)
      assert_equal(1, sitemap.sitemap_locations.size)
    end

  end
end
