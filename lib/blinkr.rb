require 'blinkr/version'
require 'blinkr/check'
require 'blinkr/report'
require 'yaml'

module Blinkr
  def self.run(base_url, config = 'blinkr.yaml', single, verbose, vverbose)
    if !config.nil? && File.exists?(config)
      config = YAML.load_file(config) 
    else
      config = {}
    end
    blinkr = Blinkr::Check.new(base_url || config['base_url'], sitemap: config['sitemap'], skips: config['skips'], max_retrys: config['max_retrys'], max_page_retrys: config['max_page_retrys'], verbose: verbose, vverbose: vverbose, browser: config['browser'], viewport: config['viewport'], ignore_fragments: config['ignore_fragments'])
    if single.nil?
      Blinkr::Report.render(blinkr.check, config['report'])
    else
      blinkr.single single
    end
  end

end
