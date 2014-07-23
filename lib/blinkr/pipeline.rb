require 'nokogiri'
require 'uri'
require 'blinkr/cache'
require 'blinkr/phantomjs_wrapper'
require 'blinkr/typhoeus_wrapper'
require 'blinkr/http_utils'
require 'blinkr/sitemap'
require 'parallel'

module Blinkr
  class Pipeline
    include HttpUtils
    include Sitemap

    def initialize config
      @config = config.validate
    end

    def run
      errors = OpenStruct.new({:links => {}})
      typhoeus, browser = TyphoeusWrapper.new(@config, errors)
      browser = PhantomJSWrapper.new(@config, errors) if @config.browser == 'phantomjs'
      
      links = {}
      page_count = 0
      browser.process_all(sitemap_locations, @config.max_page_retrys) do |resp|
        if resp.success?
          puts "Loaded page #{resp.request.base_url}" if @config.verbose
          body = Nokogiri::HTML(resp.body)
          body.css('a[href]').each do |a|
            attr = a.attribute('href')
            src = resp.request.base_url
            url = attr.value
            unless url.nil? || @config.skipped?(url)
              url = sanitize url, src
              links[url] ||= []
              links[url] << {:src => src, :line => attr.line, :snippet => attr.parent.to_s}
            end
          end
          page_count += 1
        else
          puts "#{resp.code} #{resp.status_message} Unable to load page #{resp.request.base_url} #{'(' + resp.return_message + ')' unless resp.return_message.nil?}"
        end
      end
      typhoeus.hydra.run
      puts "-----------------------------------------------" if @config.verbose
      puts " Page load complete, #{links.length} links to check " if @config.verbose
      puts "-----------------------------------------------" if @config.verbose 
      links.each do |url, srcs|
        typhoeus.process(url, @config.max_retrys) do |resp|
          puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @config.verbose
          unless resp.success? || resp.code == 200
            srcs.each do |src|
              unless @config.ignored? url, resp.code, resp.status_message || resp.return_message
                errors.links[url] ||= OpenStruct.new({ :code => resp.code.nil? ? nil : resp.code.to_i, :status_message => resp.status_message, :return_message => resp.return_message, :refs => [], :uid => uid(url) })
                errors.links[url].refs << OpenStruct.new({:src => src[:src], :src_location => "line #{src[:line]}", :snippet => src[:snippet]})
              end
            end
          end
        end
      end
      typhoeus.hydra.run
      puts "Loaded #{page_count} pages using #{browser.name}. Performed #{typhoeus.count} requests using typhoeus."
      errors
    end

  end
end

