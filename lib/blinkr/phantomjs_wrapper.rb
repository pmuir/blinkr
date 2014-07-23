require 'typhoeus'
require 'ostruct'
require 'tempfile'
require 'blinkr/http_utils'

module Blinkr
  class PhantomJSWrapper 
    include HttpUtils

    SNAP_JS = File.expand_path('snap.js', File.dirname(__FILE__))

    attr_reader :count

    def initialize config, errors
      @config = config.validate
      @errors = errors
      @count = 0
      @errors.javascript = {}
      @errors.resources = {}
    end

    def process_all urls, limit, &block
      Parallel.each(urls, :in_threads => @config.phantomjs_threads) do |url|
        process url, limit, &block
      end
    end

    def process url, limit, &block
      _process url, limit, limit, &block
    end

    def name
      'phantomjs'
    end

    private

    def _process url, limit, max, &block
      unless @config.skipped? url
        Tempfile.open('blinkr') do|f|
          if system "phantomjs #{SNAP_JS} #{url} #{@config.viewport} #{f.path}"
            json = JSON.load(File.read(f.path))
            json['resourceErrors'].each do |error|
              start = error['errorString'].rindex('server replied: ')
              errorString = error['errorString'].slice(start.nil? ? 0 : start + 16, error['errorString'].length) unless error['errorString'].nil?
              unless @config.ignored? error['url'], error['errorCode'].nil? ? nil : error['errorCode'].to_i, errorString
                @errors.resources[url] ||= OpenStruct.new({:uid => uid(url), :messages => [] })
                @errors.resources[url].messages << OpenStruct.new(error.update({'errorString' => errorString}))
              end
            end
            json['javascriptErrors'].each do |error|
              @errors.javascript[url] ||= OpenStruct.new({:uid => uid(url), :messages => []})
              @errors.javascript[url].messages << OpenStruct.new(error)
            end
            response = Typhoeus::Response.new(code: 200, body: json['content'], mock: true)
            response.request = Typhoeus::Request.new(url)
            Typhoeus.stub(url).and_return(response)
            block.call response
          else
            if limit > 1
              puts "Loading #{url} via phantomjs (attempt #{max - limit + 2} of #{max})" if verbose
              _process url, limit - 1, max, &block
            else
              puts "Loading #{url} via phantomjs failed" if @config.verbose
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out after #{max} retries", mock: true)
              response.request = Typhoeus::Request.new(url)
              Typhoeus.stub(url).and_return(response)
              block.call response
            end
          end
        end
        @count += 1
      end
    end

  end
end
