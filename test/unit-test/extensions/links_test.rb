require_relative '../test_helper'
require 'minitest/autorun'
require 'mocha/mini_test'
require 'blinkr/sitemap'
require 'blinkr/error'
require 'blinkr/typhoeus_wrapper'

class TestBlinkr < Minitest::Test

  describe Blinkr::Extensions::Links do

    it 'collects links from page content' do
      options = {}
      options[:base_url] = 'http://www.example.com'
      @config = Blinkr::Config.new(options)

      test_site = Nokogiri::HTML(File.read("#{File.expand_path(".")}/test/test-site/blinkr.htm"))
      response = Typhoeus::Response.new(code: 200, body: test_site, effective_url: options[:base_url])
      foo = Typhoeus.stub(options[:base_url]).and_return(response)

      links = Blinkr::Extensions::Links.new(@config)
      page = OpenStruct.new(response: foo[0],
                            body: foo[0].body.freeze,
                            errors: nil,
                            resource_errors: [],
                            javascript_errors: [])

      assert_equal(10, links.collect(page).size)
    end

  end
end
