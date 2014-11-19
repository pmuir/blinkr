require 'blinkr/version'
require 'blinkr/engine'
require 'blinkr/report'
require 'blinkr/config'
require 'blinkr/typhoeus_wrapper'
require 'yaml'

module Blinkr
  def self.run(base_url, config = 'blinkr.yaml', single, verbose, vverbose)
    args = { :base_url => base_url, :verbose => verbose, :vverbose => vverbose }
    if !config.nil? && File.exists?(config)
      config = Blinkr::Config.read config, args
    else
      config = Blinkr::Config.new args
    end
    
    if single.nil?
      Blinkr::Engine.new(config).run
    else
      Blinkr::TyphoeusWrapper.new(config, OpenStruct.new).debug(single)
    end
  end

end

