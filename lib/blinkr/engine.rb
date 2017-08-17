require 'nokogiri'
require 'blinkr/phantomjs_wrapper'
require 'blinkr/typhoeus_wrapper'
require 'blinkr/slimer_js_wrapper'
require 'blinkr/http_utils'
require 'blinkr/sitemap'
require 'blinkr/report'
require 'blinkr/formatter/default_logger'
require 'blinkr/extensions/links'
require 'blinkr/extensions/javascript'
require 'blinkr/extensions/resources'
require 'blinkr/extensions/pipeline'
require 'json'
require 'pathname'
require 'fileutils'
require 'ostruct'

# Monkeypatch OpenStruct
class OpenStruct
  EXCEPT = %I[response body resource_errors javascript_errors].freeze

  def to_json(*args)
    to_h.delete_if { |k, _v| EXCEPT.include?(k) }.to_json(*args)
  end
end

module Blinkr
  class Engine
    include HttpUtils

    def initialize(config)
      @config = config.validate
      @extensions = []
      @logger = Blinkr.logger
      load_pipeline
    end

    def run
      context = OpenStruct.new(pages: {})

      bulk_browser, browser = define_browser(context)
      page_count = 0
      urls = Sitemap.new(@config).sitemap_locations.uniq

      @logger.info("Fetching #{urls.size} pages from sitemap".yellow)
      browser.process_all(urls, @config.max_page_retrys) do |response, resource_errors, javascript_errors|
        url = response.request.base_url
        if response.success?
          @logger.info("Loaded page #{url}".green) if @config.verbose
          body = Nokogiri::HTML(response.body)
          page = OpenStruct.new(response: response,
                                body: body.freeze,
                                errors: ErrorArray.new(@config),
                                resource_errors: resource_errors || [],
                                javascript_errors: javascript_errors || [])
          context.pages[url] = page
          collect(page)
          page_count += 1
        else
          @logger.info("#{response.code} #{response.status_message} Unable to load page #{url} #{'(' + response.return_message + ')' unless response.return_message.nil?}".red)
        end
      end
      @logger.info('Executing Typhoeus::Hydra.run, this could take awhile'.magenta) if @config.browser == 'typhoeus'
      @logger.info("Loaded #{page_count} pages using #{browser.name}.".green)
      @logger.info('Analyzing pages'.yellow)
      analyze(context, bulk_browser)
      context.pages.reject! { |_, page| page.errors.empty? }

      unless @config.export.nil?
        FileUtils.mkdir_p Pathname.new(@config.report).parent
      end
      Blinkr::Report.new(context, self, @config).render
    end

    # generate user-defined browser to use for duration of checks
    # if using Jruby defaults to Manticore, else uses Typhoeus.
    def define_browser(context)
      if defined?(JRUBY_VERSION)
        require 'blinkr/manticore_wrapper'
        bulk_browser = browser = ManticoreWrapper.new(@config, context)
      else
        bulk_browser = browser = TyphoeusWrapper.new(@config, context)
      end
      browser = SlimerJSWrapper.new(@config, context) if @config.browser == 'slimerjs'
      browser = PhantomJSWrapper.new(@config, context) if @config.browser == 'phantomjs'
      return bulk_browser, browser
    end

    def append(context)
      execute :append, context
    end

    def transform(page, error, &block)
      default = yield
      result = execute(:transform, page, error, default)
      if result.empty?
        default
      else
        result.join
      end
    end

    def analyze(context, typhoeus)
      execute :analyze, context, typhoeus
    end

    def collect(page)
      execute :collect, page
    end

    private

    class ErrorArray < Array
      def initialize(config)
        @config = config
      end

      def <<(error)
        if @config.ignored?(error)
          self
        else
          super
        end
      end
    end

    def extension(ext)
      @extensions << ext
    end

    def default_pipeline
      extension Blinkr::Extensions::Links.new @config
      extension Blinkr::Extensions::JavaScript.new @config
      extension Blinkr::Extensions::Resources.new @config
    end

    def execute(method, *args)
      result = []
      @extensions.each do |e|
        result << e.send(method, *args) if e.respond_to? method
      end
      result
    end

    def load_pipeline
      if @config.pipeline.nil?
        @logger.info('Loaded default pipeline'.yellow) if @config.verbose
        default_pipeline
      else
        pipeline_file = File.join(File.dirname(@config.config_file), @config.pipeline)
        if File.exist?(pipeline_file)
          p = eval(File.read(pipeline_file), nil, pipeline_file, 1).load @config
          p.extensions.each do |e|
            extension(e)
          end
          if @config.verbose
            @logger.info("Loaded custom pipeline from #{@config.pipeline}".yellow)
            pipeline = @extensions.inject { |memo, v| "#{memo}, #{v}" }
            @logger.info("Pipeline: #{pipeline}".yellow)
          end
        else
          raise "Cannot find pipeline file #{pipeline_file}"
        end
      end
    end
  end
end
