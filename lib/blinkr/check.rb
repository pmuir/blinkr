require 'nokogiri'
require 'uri'
require 'typhoeus'
require 'blinkr/cache'
require 'ostruct'
require 'tempfile'
require 'parallel'

module Blinkr 
  class Check

    SNAP_JS = File.expand_path('snap.js', File.dirname(__FILE__))

    def initialize base_url, sitemap: '', skips: [], max_retrys: 3, max_page_retrys: 3, verbose: false, browser: 'typhoeus', viewport: 1200
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
      @browser = browser || 'typhoeus'
      @verbose = verbose
      @viewport = viewport || 1200
      @typhoeus_cache = Blinkr::Cache.new
      Typhoeus::Config.cache = @typhoeus_cache
      @hydra = Typhoeus::Hydra.new(max_concurrency: 200)
      @phantomjs_count = 0
      @typhoeus_count = 0
    end

    def check
      @errors = OpenStruct.new({:links => {}})
      @errors.javascript = {} if @browser == 'phantomjs'
      puts "Loading sitemap from #{@sitemap}"
      if @sitemap =~ URI::regexp
        sitemap = Nokogiri::XML(Typhoeus.get(@sitemap, followlocation: true).body)
      else
        sitemap = Nokogiri::XML(File.open(@sitemap))
      end
      pages(sitemap.css('loc').collect { |loc| loc.content }) do |resp|
        if resp.success?
          body = Nokogiri::HTML(resp.body)
          body.css('a[href]').each do |a|
            check_attr(a.attribute('href'),resp.request.base_url)
          end
        else
          puts "#{resp.code} #{resp.status_message} Unable to load page #{resp.request.base_url} #{'(' + resp.return_message + ')' unless resp.return_message.nil?}"
        end
      end
      @hydra.run
      msg = "Checked #{@phantomjs_count + @typhoeus_count} urls."
      msg << " Loaded #{@phantomjs_count} pages using phantomjs." if @phantomjs_count > 0
      msg << " Fetched #{@typhoeus_cache.size} pages into typhoeus cache, for #{@typhoeus_count} requests."
      puts msg
      @errors
    end

    def single url
      typhoeus(url) do |resp|
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
          typhoeus(url) do |resp|
            unless resp.success?
              add_error url, resp.code, resp.status_message, resp.return_message, src, "line #{attr.line}", attr.parent.to_s
            end
          end
        end
      end
    end

    def add_error url, code, status_message, return_message, src, src_location, snippet
      @errors.links[url] ||= OpenStruct.new({ :code => code.nil? ? nil : code.to_i, :status_message => status_message, :return_message => return_message, :refs => [], :uid => uid(url) })
      @errors.links[url].refs << OpenStruct.new({:src => src, :src_location => src_location, :snippet => snippet})
    end

    def uid url
       url.gsub(/:|\/|\.|\?|#|%|=|&|,|~|;|\!|@/, '_')
    end

    def pages urls
      if @browser == 'phantomjs'
        Parallel.each(urls, :in_threads => 8) do |url|
          phantomjs url, @max_page_retrys, &Proc.new
        end
      else
        urls.each do |url|
          typhoeus url, @max_page_retrys, &Proc.new
        end
      end
    end

    def phantomjs url, limit = @max_retrys
      if @skips.none? { |regex| regex.match(url) }
        Tempfile.open('blinkr') do|f|
          if system "phantomjs #{SNAP_JS} #{url} #{@viewport} #{f.path}"
            json = JSON.load(File.read(f.path))
            json['resourceErrors'].each do |error|
              add_error error['url'], error['errorCode'], error['errorString'], nil, url, 'Loading resource', nil
            end
            json['javascriptErrors'].each do |error|
              @errors.javascript[url] ||= OpenStruct.new({:uid => uid(url), :messages => []})
              @errors.javascript[url].messages << OpenStruct.new(error)
            end
            response = Typhoeus::Response.new(code: 200, body: json['content'])
            response.request = Typhoeus::Request.new(url)
            Typhoeus.stub(url).and_return(response)
            yield response
          else
            if limit > 0
              phantomjs url, limit - 1
            else
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out")
              response.request = Typhoeus::Request.new(url)
              Typhoeus.stub(url).and_return(response)
              yield response
            end
          end
        end
        @phantomjs_count += 1
      end
    end

    def typhoeus url, limit = @max_retrys
      if @skips.none? { |regex| regex.match(url) }
        req = Typhoeus::Request.new(
          url,
          followlocation: true,
          verbose: @verbose
        )
        req.on_complete do |resp|
          if resp.timed_out?
            if limit > 0
              typhoeus(url, limit - 1, &Proc.new)
            else
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out")
              response.request = Typhoeus::Request.new(url)
              Typhoeus.stub(url).and_return(response)
              yield response
            end
          else
            yield resp
          end
        end
        @hydra.queue req
        @typhoeus_count += 1
      end
    end
  end
end

