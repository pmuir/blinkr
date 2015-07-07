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
        resp.on_complete do |resp|
          if retry? resp
            if limit > 1
              puts "Loading #{url} via manticore (attempt #{max - limit + 2} of #{max})" if @config.verbose
              _process(url, limit - 1, max, &Proc.new)
            else
              puts "Loading #{url} via manticore failed" if @config.verbose
              response = @client.respond_with(:code => 0, :status_message => "Server timed out after #{max} retries",
                                              :body => '').get(url)
              block.call response, nil, nil
            end
          else
            block.call resp, nil, nil
          end
          @count += 1
        end
      end
    end
  end
end
