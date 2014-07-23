require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/hydra'
require 'typhoeus'
require 'blinkr/cache'
require 'blinkr/http_utils'

module Blinkr
  class TyphoeusWrapper
    include HttpUtils

    attr_reader :count, :hydra

    def initialize config, errors
      @config = config.validate
      @hydra = Typhoeus::Hydra.new(max_concurrency: 200)      
      @count = 0
      @errors = errors
    end

    def process_all urls, limit, &block
      urls.each do |url|
        process url, limit, &block
      end
    end

    def process url, limit, &block
      _process url, limit, limit, &block
    end

    def debug url
      process(url, @config.max_retrys) do |resp|
        puts "\n++++++++++"
        puts "+ Blinkr +"
        puts "++++++++++"
        puts "\nRequest"
        puts "======="
        puts "Method: #{resp.request.options[:method]}"
        puts "Max redirects: #{resp.request.options[:maxredirs]}"
        puts "Follow location header: #{resp.request.options[:followlocation]}"
        puts "Timeout (s): #{resp.request.options[:timeout] || 'none'}"
        puts "Connection timeout (s): #{resp.request.options[:connecttimeout] || 'none'}"
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

    def name
      'typhoeus'
    end

    private

    def _process url, limit, max, &block
      unless @config.skipped? url
        req = Typhoeus::Request.new(
          url,
          followlocation: true,
          verbose: @config.vverbose
        )
        req.on_complete do |resp|
          if retry? resp
            if limit > 1 
              puts "Loading #{url} via typhoeus (attempt #{max - limit + 2} of #{max})" if @config.verbose
              _process(url, limit - 1, max, &Proc.new)
            else
              puts "Loading #{url} via typhoeus failed" if @config.verbose
              response = Typhoeus::Response.new(code: 0, status_message: "Server timed out after #{max} retries", mock: true)
              response.request = Typhoeus::Request.new(url)
              Typhoeus.stub(url).and_return(response)
              block.call response
            end
          else
            block.call resp
          end
        end
        @hydra.queue req
        @count += 1
      end
    end

  end
end

