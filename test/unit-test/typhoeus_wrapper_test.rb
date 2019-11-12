require_relative '../../test/unit-test/test_helper'
require 'minitest/autorun'
require 'mocha/mini_test'

class TestTyphoeusWrapper < Minitest::Test

  describe TestTyphoeusWrapper do

    it 'should initialize without error' do
      config = OpenStruct.new
      context = OpenStruct.new
      config.expects(:validate).returns(config)

      Blinkr::TyphoeusWrapper.new(config, context)
    end
  end
end
