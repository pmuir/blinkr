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

module Blinkr
  class Pipeline
    include HttpUtils
    include Sitemap

    def initialize config
      @config = config.validate
      @extensions = []
      default_pipeline config
    end

    def extension ext
      @extensions << ext
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
          page = OpenStruct.new({ :response => response, :body => body, :errors => [], :uid => uid(url), :resource_errors => resource_errors || [], :javascript_errors => javascript_errors || [] })
          context.pages[url] = page
          exec :collect, page
          page_count += 1
        else
          puts "#{respones.code} #{response.status_message} Unable to load page #{url} #{'(' + response.return_message + ')' unless response.return_message.nil?}"
        end
      end
      typhoeus.hydra.run if @config.browser == 'typhoeus'
      exec :analyse, context, typhoeus
      puts "Loaded #{page_count} pages using #{browser.name}. Performed #{typhoeus.count} requests using typhoeus."
      context.pages.reject! { |url, page| page.errors.empty? }
      Blinkr::Report.new(context, self, @config).render
    end
  
    def append context
      exec :append, context
    end
      
    def transform page, error
      default = yield
      result = exec(:transform, page, error, default)
      if result.empty?
        default
      else
        result.join
      end
    end

    private

    def default_pipeline config
      extension Blinkr::Extension::Links.new config
      extension Blinkr::Extension::JavaScript.new config
      extension Blinkr::Extension::Resources.new config
    end

    def exec method, *args
      result = []
      @extensions.each do |e|
        result << e.send(method, *args) if e.respond_to? method
      end
      result
    end
  end
end

