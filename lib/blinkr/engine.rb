require 'nokogiri'
require 'uri'
require 'blinkr/cache'
require 'blinkr/phantomjs_wrapper'
require 'blinkr/typhoeus_wrapper'
require 'blinkr/http_utils'
require 'blinkr/sitemap'
require 'blinkr/report'
require 'blinkr/extensions/links'
require 'blinkr/extensions/javascript'
require 'blinkr/extensions/resources'
require 'blinkr/extensions/pipeline'

module Blinkr
  class Engine 
    include HttpUtils
    include Sitemap

    def initialize config
      @config = config.validate
      @extensions = []
      load_pipeline
    end

    def run
      context = OpenStruct.new({:pages => {}})
      typhoeus, browser = TyphoeusWrapper.new(@config, context)
      browser = PhantomJSWrapper.new(@config, context) if @config.browser == 'phantomjs'
      page_count = 0
      browser.process_all(sitemap_locations, @config.max_page_retrys) do |response, resource_errors, javascript_errors|
        if response.success?
          url = response.request.base_url
          puts "Loaded page #{url}" if @config.verbose
          body = Nokogiri::HTML(response.body)
          page = OpenStruct.new({ :response => response, :body => body, :errors => ErrorArray.new(@config), :resource_errors => resource_errors || [], :javascript_errors => javascript_errors || [] })
          context.pages[url] = page
          collect page
          page_count += 1
        else
          puts "#{respones.code} #{response.status_message} Unable to load page #{url} #{'(' + response.return_message + ')' unless response.return_message.nil?}"
        end
      end
      typhoeus.hydra.run if @config.browser == 'typhoeus'
      analyze context, typhoeus
      puts "Loaded #{page_count} pages using #{browser.name}. Performed #{typhoeus.count} requests using typhoeus."
      context.pages.reject! { |url, page| page.errors.empty? }
      Blinkr::Report.new(context, self, @config).render
    end

    def append context
      exec :append, context
    end
      
    def transform page, error, &block
      default = yield
      result = exec(:transform, page, error, default)
      if result.empty?
        default
      else
        result.join
      end
    end

    def analyze context, typhoeus
      exec :analyze, context, typhoeus
    end

    def collect page
      exec :collect, page
    end

    private

    class ErrorArray < Array

      def initialize config
        @config = config
      end

      def << error
        unless @config.ignored?(error.url, error.code, error.message)
          super
        else
          self
        end
      end

    end

    def extension ext
      @extensions << ext
    end

    def default_pipeline
      extension Blinkr::Extensions::Links.new @config
      extension Blinkr::Extensions::JavaScript.new @config
      extension Blinkr::Extensions::Resources.new @config
    end

    def exec method, *args
      result = []
      @extensions.each do |e|
        result << e.send(method, *args) if e.respond_to? method
      end
      result
    end

    def load_pipeline
      unless @config.pipeline.nil?
        pipeline_file = File.join(File.dirname(@config.config_file), @config.pipeline)
        if  File.exists?( pipeline_file )
          p = eval(File.read( pipeline_file ), nil, pipeline_file, 1).load @config
          p.extensions.each do |e|
            extension( e )
          end
        else
          raise "Cannot find pipeline file #{pipeline_file}"
        end
      else
        default_pipeline
      end
    end

  end
end

