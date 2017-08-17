require 'ostruct'

module Blinkr
  class Config < OpenStruct
    def self.read(file, args)
      raise("Cannot read #{file}") unless File.exist?(file)
      Config.new(YAML.load_file(file).merge(args).merge(config_file: file))
    end

    DEFAULTS = { skips: [], ignores: [], environments: [], max_retrys: 3,
                browser: 'phantomjs', viewport: 1200, phantomjs_threads: 10,
                report: 'blinkr.html', warning_on_300s: false,
                ignore_internal: false, ignore_external: false,
                warn_js_errors: false, warn_inline_css: false,
                ignore_ssl: false, warn_resource_errors: false }.freeze

    def initialize(hash = {})
      super(DEFAULTS.merge(hash))
    end

    def validate
      unless single_url
        ignores.each { |ignore| raise 'An ignore must be a hash' unless ignore.is_a? Hash }
        raise 'Must specify base_url' if base_url.nil?
        raise 'Must specify sitemap' if sitemap.nil?
      end
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
      raise 'Retrys is nil' if r.nil?
      r
    end

    def ignored?(error)
      url = error.url
      code = error.code
      message = error.message
      snippet = error.snippet

      ignores.any? do |ignore|

        if ignore.key? 'url'
          return true if ignore['url'].is_a?(Regexp) && url && ignore['url'] =~ url
          return true if ignore['url'] == url
        end

        if ignore.key? 'code'
          return true if ignore['code'].is_a?(Regexp) && code && ignore['code'] == code
          return true if ignore['code'] == code
        end

        if ignore.key? 'message'
          return true if ignore['message'].is_a?(Regexp) && message && ignore['message'] =~ message
          return true if ignore['message'] == message
        end

        if ignore.key? 'snippet'
          return true if ignore['snippet'].is_a?(Regexp) && snippet && ignore['snippet'] =~ snippet
          return true if ignore['snippet'] == snippet
        end

        false
      end
    end

    def skipped?(url)
      if skips.any? do |skip|
        if skip.is_a?(Regexp)
          return true if skip =~ url
        else
          return true if skip == url
        end
      end
      end
    end

  end
end
