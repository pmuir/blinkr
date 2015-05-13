require 'blinkr/error'
require 'blinkr/http_utils'

module Blinkr
  module Extensions
    class Links
      include Blinkr::HttpUtils

      def initialize(config)
        @config = config
        @links = {}
      end

      def collect(page)
        page.body.css('a[href]').each do |a|
          attr = a.attribute('href')
          src = page.response.effective_url
          url = attr.value
          unless @config.skipped?(url)
            url = sanitize url, src
            unless url.nil?
              @links[url] ||= []
              @links[url] << {:page => page, :line => attr.line, :snippet => attr.parent.to_s}
            end
          end
        end
      end

      def analyze(context, typhoeus)
        puts '----------------------'
        puts " #{@links.length} links to check "
        puts '----------------------'
        processed = 0
        @links.each do |url, metadata|
          typhoeus.process(url, @config.max_retrys, {:method => :head}) do |resp|
            puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @config.verbose
            unless resp.success? || resp.code == 200
              metadata.each do |src|
                code = resp.code.to_i unless resp.code.nil? || resp.code == 0
                if resp.status_message.nil?
                  message = resp.return_message
                else
                  message = resp.status_message
                  detail = resp.return_message unless resp.return_message == 'No error'
                end
                src[:page].errors << Blinkr::Error.new({:severity => 'danger', :category => 'Resources missing',
                                                        :type => '<a href=""> target cannot be loaded',
                                                        :url => url, :title => "#{url} (line #{src[:line]})",
                                                        :code => code, :message => message, :detail => detail,
                                                        :snippet => src[:snippet], :icon => 'fa-bookmark-o'})
              end
            end
            processed += 1
            puts "Processed #{processed} of #{@links.size}" if @config.verbose
          end
        end
        typhoeus.hydra.run
      end

    end
  end
end

