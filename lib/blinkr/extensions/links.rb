require 'blinkr/http_utils'

module Blinkr
  module Extension
    class Links
      include HttpUtils

      def initialize config
        @config = config
        @links = {}
      end

      def collect page
        page.body.css('a[href]').each do |a|
          attr = a.attribute('href')
          src = page.response.request.base_url
          url = attr.value
          unless url.nil? || @config.skipped?(url)
            url = sanitize url, src
            @links[url] ||= []
            @links[url] << {:page => page, :line => attr.line, :snippet => attr.parent.to_s}
          end
        end
      end

      def analyse context, typhoeus
        puts "----------------------" if @config.verbose
        puts " #{@links.length} links to check " if @config.verbose
        puts "----------------------" if @config.verbose
        @links.each do |url, metadata|
          typhoeus.process(url, @config.max_retrys) do |resp|
            puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @config.verbose
            unless resp.success? || resp.code == 200 || @config.ignored?(url, resp.code, resp.status_message || resp.return_message)
              metadata.each do |src|
                code = resp.code.to_i unless resp.code.nil? || resp.code == 0
                if resp.status_message.nil?
                  message = resp.return_message
                else
                  message = resp.status_message
                  detail = resp.return_message
                end
                src[:page].errors << OpenStruct.new({ :type => 'link', :url => url, :title => "#{url} (line #{src[:line]})", :code => code, :message => message, :detail => detail, :snippet => src[:snippet], :icon => 'fa-bookmark-o' })
              end
            end
          end
        end
        typhoeus.hydra.run
      end

    end
  end
end

