require_relative '../../test/unit-test/test_helper'
require 'minitest/autorun'
require 'mocha/mini_test'

class TestBlinkr < Minitest::Test

  describe Blinkr do

    it 'should load user specified config file in a hash' do
      options = {}
      options[:config_file] = "#{__dir__}/config/valid_blinkr.yaml"

      config = mock
      blinkr_engine = mock

      Blinkr::Config.expects(:read).with(options[:config_file], options.tap { |hs| hs.delete(options[:config_file]) }).returns(config)
      Blinkr::Engine.expects(:new).with(config).returns(blinkr_engine)

      blinkr_engine.expects(:run)
      Blinkr.run(options)
    end

    it 'should load default config if not specified' do

      options = {}

      config = mock
      blinkr_engine = mock

      Blinkr::Config.expects(:new).with(options).returns(config)
      Blinkr::Engine.expects(:new).with(config).returns(blinkr_engine)

      blinkr_engine.expects(:run)

      Blinkr.run(options)
    end

    it 'can check a single_url' do
      options = {}
      options[:single_url] = 'http://www.example.com/foo'

      config = mock
      typehouse_wrapper = mock

      Blinkr::Config.expects(:new).with(options).returns(config)

      Blinkr::TyphoeusWrapper.expects(:new).with(config, is_a(OpenStruct)).returns(typehouse_wrapper)

      typehouse_wrapper.expects(:debug)

      Blinkr.run(options)
    end
  end
end
