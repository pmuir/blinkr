require 'blinkr/version'
require 'blinkr/engine'
require 'blinkr/report'
require 'blinkr/config'
require 'blinkr/error'
require 'blinkr/hacks'
require 'blinkr/typhoeus_wrapper'
require 'yaml'

module Blinkr
  module_function

  def self.run(options = {})
    config = if options[:config_file] && File.exist?(options[:config_file])
               Blinkr::Config.read(options[:config_file], options.tap { |hs| hs.delete(:config_file) })
             else
               Blinkr::Config.new(options)
             end

    if options[:single_url].nil?
      Blinkr::Engine.new(config).run
    else
      Blinkr::TyphoeusWrapper.new(config, OpenStruct.new).debug(options[:single_url])
    end
  end
end
