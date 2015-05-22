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
        non_internal_links = @links.reject {|k| k.start_with? @config.base_url}
        processed = 0
        non_internal_links.each do |url, metadata|
          # if link start_with? @config.base_url check to see if it's in the sitemap.xml
          typhoeus.process(url, @config.max_retrys, :method => :head, :followlocation => true) do |resp|
            puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @config.verbose
            if resp.code.to_i < 200 || resp.code.to_i > 300
              response = resp

              # Try a GET if HEAD failed, I've noticed some HEAD requests will fail but a GET works correctly
              if response.code.to_i < 200 || resp.code.to_i > 300
                response = Typhoeus.get(url, :followlocation => true)
              end

              metadata.each do |src|
                detail = nil
                if response.status_message.nil?
                  message = response.return_message
                else
                  message = response.status_message
                  detail = response.return_message unless resp.return_message == 'No error'
                end

                severity = :danger
                if response.code.to_i >= 300 && response.code.to_i < 400
                  severity = :warning
                end
                src[:page].errors << Blinkr::Error.new({:severity => severity,
                                                        :category => 'Resources missing',
                                                        :type => '<a href=""> target cannot be loaded',
                                                        :url => url, :title => "#{url} (line #{src[:line]})",
                                                        :code => response.code.to_i, :message => message,
                                                        :detail => detail, :snippet => src[:snippet],
                                                        :icon => 'fa-bookmark-o'}) unless response.success?
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

