require 'manticore'
require 'blinkr/cache'
require 'blinkr/http_utils'

module Blinkr
  class ManticoreWrapper
    include HttpUtils

    attr_reader :count

    def initialize(config, context)
      @config = config.validate
      @client = Manticore::Client.new({:pool_max => (@config.maxconnects || 50),
                                       :pool_max_per_route => 10
                                      })
      @count = 0
      @context = context
    end

    def process_all(urls, limit, opts = {}, &block)
      urls.each do |url|
        process url, limit, opts, &block
      end
      @client.execute!
    end

    def process(url, limit, opts = {}, &block)
      _process url, limit, limit, opts, &block
    end

    def name
      'manticore'
    end

    private

    def _process(url, limit, max, opts = {}, &block)
      unless @config.skipped? url
        resp = @client.async.get(url)
        resp.on_success do |resp|
          if resp.times_retried > limit
              puts "Loading #{url} via manticore failed" if @config.verbose
              response = @client.respond_with(:code => 0, :status_message => "Server timed out after #{max} retries",
                                              :body => '').get(url)
              block.call response, url, nil
          else
            block.call resp, url, nil
          end
          @count += 1
        end
        resp.on_failure do |resp|
          # TODO: Figure out how to get this to create an error
          puts "#{resp} failed, code #{resp.code}"
        end
      end
    end
  end
end
