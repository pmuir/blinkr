require 'nokogiri'
require 'uri'
require 'typhoeus'
require 'blinkr/cache'
require 'ostruct'

module Blinkr 
  class Check

    def initialize base_url, sitemap: sitemap, skips: skips, max_retrys: max_retrys, max_page_retrys: max_page_retrys, verbose: verbose
      raise "Must specify base_url" if base_url.nil?
      unless sitemap.nil?
        @sitemap = sitemap
      else
        @sitemap = URI.join(base_url, 'sitemap.xml').to_s
      end
      @skips = skips || []
      @base_url = base_url
      @max_retrys = max_retrys || 3
      @max_page_retrys = max_page_retrys || @max_retrys
      @verbose = verbose
      Typhoeus::Config.memoize = true
      Typhoeus::Config.cache = Blinkr::Cache.new
      @hydra = Typhoeus::Hydra.new(max_concurrency: 200)
    end

    def check
      @errors = {}
      puts "Loading sitemap from #{@sitemap}"
      if @sitemap =~ URI::regexp
        sitemap = Nokogiri::XML(Typhoeus.get(@sitemap, followlocation: true).body)
      else
        sitemap = Nokogiri::XML(File.open(@sitemap))
      end
      sitemap.css('loc').each do |loc|
        request = Typhoeus::Request.new(
          loc.content,
          method: :get,
          followlocation: true
        )
        perform(request, @max_page_retrys) do |resp|
          page = Nokogiri::HTML(resp.body)
          page.css('a[href]').each do |a|
            check_attr(a.attribute('href'), loc.content)
          end
          page.css('img[src]').each do |img|
            check_attr(img.attribute('src'), loc.content)
          end
        end
      end
      @hydra.run
      @errors
    end

    def single url
      perform(head(url)) do |resp|
        puts "\n++++++++++"
        puts "+ Blinkr +"
        puts "++++++++++"
        puts "\nRequest"
        puts "======="
        puts "Method: #{resp.request.options[:method]}"
        puts "Max redirects: #{resp.request.options[:maxredirs]}"
        puts "Follow location header: #{resp.request.options[:followlocation]}"
        puts "\nHeaders"
        puts "-------"
        unless resp.request.options[:headers].nil?
          resp.request.options[:headers].each do |name, value|
            puts "#{name}: #{value}"
          end
        end
        puts "\nResponse"
        puts "========"
        puts "Status Code: #{resp.code}"
        puts "Status Message: #{resp.status_message}"
        puts "Message: #{resp.return_message}" unless resp.return_message.nil? || resp.return_message == 'No error'
        puts "\nHeaders"
        puts "-------"
        puts resp.response_headers
      end
      @hydra.run
    end

    private

    def check_attr attr, src
      url = attr.value
      unless url.nil?
        begin
          uri = URI(url)
          uri = URI.join(src, url) if uri.path.nil? || uri.path.empty? || uri.path.relative?
          uri = URI.join(@base_url, uri) if uri.scheme.nil?
          url = uri.to_s
        rescue Exception => e
        end
        if uri.nil? || uri.is_a?(URI::HTTP)
          perform(head(url)) do |resp|
            unless resp.success?
              @errors[request] ||= OpenStruct.new({ :url => url, :code => resp.code.to_i, :status_message => resp.status_message, :return_message => resp.return_message, :refs => [], :uid => url.gsub(/:|\/|\.|\?|#/, '_') })
              @errors[request].refs << OpenStruct.new({:src => src, :line_no => attr.line, :snippet => attr.parent.to_s})
            end
          end
        end
      end
    end

    def head url
      Typhoeus::Request.new(
        url,
        method: :head,
        followlocation: true,
        verbose: @verbose
      )
    end

    def perform req, limit = @max_retrys
      if @skips.none? { |regex| regex.match(req.base_url) }
        req.on_complete do |resp|
          if resp.timed_out?
            if limit > 0
              perform(Typhoeus::Request.new(req.base_url, req.options), limit - 1, &Proc.new)
            else
              yield OpenStruct.new({:success => false, :code => '0', :status_message => "Server timed out"})
            end
          else
            yield resp
          end
        end
        @hydra.queue req
      end
    end
  end
end

