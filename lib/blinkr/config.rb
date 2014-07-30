require 'ostruct'

module Blinkr
  class Config < OpenStruct

    def self.read file, args
      raise "Cannot read #{file}" unless File.exists? file
      Config.new(YAML.load_file(file).merge(args).merge({ :config_file => file }))
    end

    DEFAULTS = {:skips => [], :ignores => [], :max_retrys => 3, :browser => 'typhoeus', :viewport => 1200, :phantomjs_threads => 8, :report => 'blinkr.html'}

    def initialize(hash={})
      super(DEFAULTS.merge(hash))
    end

    def validate
      ignores.each {|ignore| raise "An ignore must be a hash" unless ignore.is_a? Hash}
      raise "Must specify base_url" if base_url.nil?
      raise "Must specify sitemap" if sitemap.nil?
      self
    end

    def sitemap
      if super.nil?
        URI.join(base_url, 'sitemap.xml').to_s 
      else
        super
      end
    end

    def max_page_retrys
      r = super || max_retrys
      raise "Retrys is nil" if r.nil?
      r
    end

    def ignored? url, code, message
      ignores.any? { |ignore| ( !url.nil? && ignore.has_key?('url') ? !ignore['url'].match(url).nil? : true )  && ( !code.nil? && ignore.has_key?('code') ? ignore['code'] == code : true ) && ( !message.nil? && ignore.has_key?('message') ? !ignore['message'].match(message).nil? : true ) }
    end

    def skipped? url
      skips.any? { |regex| regex.match(url) }
    end

  end
end

