require 'blinkr/version'
require 'blinkr/check'
require 'blinkr/report'
require 'yaml'

module Blinkr
  def self.run(base_url, config = 'blinkr.yaml')
    if !config.nil? && File.exists?(config)
      config = YAML.load_file(config) 
    else
      config = {}
    end
    blinkr = Blinkr::Check.new(base_url || config['base_url'], sitemap: config['sitemap'], skips: config['skips'], max_retrys: config['max_retrys'], max_page_retrys: config['max_page_retrys'])
    Blinkr::Report.render(blinkr.check, config['report'])
  end
end
