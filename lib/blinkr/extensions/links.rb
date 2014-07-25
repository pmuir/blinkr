require 'blinkr/http_utils'

module Blinkr
  module Extensions
    class Links
      include HttpUtils

      def initialize config
        @config = config
        @links = {}
      end

      def collect page
        page.body.css('a[href]').each do |a|
          attr = a.attribute('href')
          src = page.response.effective_url
          url = attr.value
          url = sanitize url, src
          unless url.nil? || @config.skipped?(url)
            @links[url] ||= []
            @links[url] << {:page => page, :line => attr.line, :snippet => attr.parent.to_s}
          end
        end
      end

      def analyze context, typhoeus
        puts "----------------------" if @config.verbose
        puts " #{@links.length} links to check " if @config.verbose
        puts "----------------------" if @config.verbose
        @links.each do |url, metadata|
          typhoeus.process(url, @config.max_retrys) do |resp|
            puts "Loaded #{url} via typhoeus #{'(cached)' if resp.cached?}" if @config.verbose
            unless resp.success? || resp.code == 200
              metadata.each do |src|
                code = resp.code.to_i unless resp.code.nil? || resp.code == 0
                if resp.status_message.nil?
                  message = resp.return_message
                else
                  message = resp.status_message
                  detail = resp.return_message unless resp.return_message == "No error"
                end
                src[:page].errors << OpenStruct.new({ :severity => 'danger', :category => 'Resources missing', :type => '<a href=""> target cannot be loaded', :url => url, :title => "#{url} (line #{src[:line]})", :code => code, :message => message, :detail => detail, :snippet => src[:snippet], :icon => 'fa-bookmark-o' })
              end
            end
          end
        end
        typhoeus.hydra.run
      end

    end
  end
end

