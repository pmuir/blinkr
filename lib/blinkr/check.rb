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

    def initialize base_url, sitemap: '', skips: [], max_retrys: 3, max_page_retrys: 3, verbose: false, vverbose: false, browser: 'typhoeus', viewport: 1200
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
      @verbose = vverbose || verbose
      @vverbose = vverbose
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
      @links = {}
      pages(sitemap.css('loc').collect { |loc| loc.content }) do |resp|
        if resp.success?
          puts "Loaded page #{resp.request.base_url}" if @verbose
          body = Nokogiri::HTML(resp.body)
          body.css('a[href]').each do |a|
            attr = a.attribute('href')
            src = resp.request.base_url
            url = attr.value
            if !url.nil? && @skips.none? { |regex| regex.match(url) }
              url = sanitize url, src
              @links[url] ||= []
              @links[url] << {:src => src, :line => attr.line, :snippet => attr.parent.to_s}
            end
          end
        else
          puts "#{resp.code} #{resp.status_message} Unable to load page #{resp.request.base_url} #{'(' + resp.return_message + ')' unless resp.return_message.nil?}"
        end
      end
      @hydra.run
      puts "-----------------------------------------------" if @verbose
      puts " Page load complete, #{@links.size} links to check " if @verbose
      puts "-----------------------------------------------" if @verbose 
      @links.each do |url, srcs|
        typhoeus(url) do |resp|
          puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @verbose
          unless resp.success?
            srcs.each do |src|
              add_error url, resp.code, resp.status_message, resp.return_message, src[:src], "line #{src[:line]}", src[:snippet]
            end
          end
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

    def sanitize url, src
      begin
        uri = URI(url)
        uri = URI.join(src, url) if uri.path.nil? || uri.path.empty? || uri.relative?
        uri = URI.join(@base_url, uri) if uri.scheme.nil?
        url = uri.to_s
      rescue Exception => e
      end
      url.chomp('#').chomp('index.html')
    end

    def add_error url, code, status_message, return_message, src, src_location, snippet
      @errors.links[url] ||= OpenStruct.new({ :code => code.nil? ? nil : code.to_i, :status_message => status_message, :return_message => return_message, :refs => [], :uid => uid(url) })
      @errors.links[url].refs << OpenStruct.new({:src => src, :src_location => src_location, :snippet => snippet})
    end

    def uid url
       url.gsub(/:|\/|\.|\?|#|%|=|&|,|~|;|\!|@|\)|\(/, '_')
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

    def phantomjs url, limit = @max_retrys, max = -1
      max = limit if max == -1
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
            response = Typhoeus::Response.new(code: 200, body: json['content'], mock: true)
            response.request = Typhoeus::Request.new(url)
            Typhoeus.stub(url).and_return(response)
            yield response
          else
            if limit > 1
              puts "Loading #{url} via phantomjs (attempt #{max - limit + 2} of #{max})" if @verbose
              phantomjs url, limit - 1, max, &Proc.new
            else
              puts "Loading #{url} via phantomjs failed" if @verbose
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out", mock: true)
              response.request = Typhoeus::Request.new(url)
              Typhoeus.stub(url).and_return(response)
              yield response
            end
          end
        end
        @phantomjs_count += 1
      end
    end

    def typhoeus url, limit = @max_retrys, max = -1
      max = limit if max == -1
      if @skips.none? { |regex| regex.match(url) }
        req = Typhoeus::Request.new(
          url,
          followlocation: true,
          verbose: @vverbose 
        )
        req.on_complete do |resp|
          if resp.timed_out?
            if limit > 1 
              puts "Loading #{url} via typhoeus (attempt #{max - limit + 2} of #{max})" if @verbose
              typhoeus(url, limit - 1, max, &Proc.new)
            else
              puts "Loading #{url} via typhoeus failed" if @verbose
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out", mock: true)
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

