require 'blinkr/version'
require 'blinkr/pipeline'
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
      Blinkr::Pipeline.new(config).run
    else
      Blinkr::TyphoeusWrapper.new(config).debug(single)
    end
  end

end

