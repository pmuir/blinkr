require 'uri'
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

      def analyze(context, browser)
        puts '----------------------'
        puts " #{@links.length} links to check "
        puts '----------------------'
        start = DateTime.now

        processed = 0

        # Find the internal links
        @links.select{|k| k.start_with? @config.base_url}.each do |url, locations|
          # TODO figure out what to do about relative links
          link = URI.parse(url)

          # fix up links so they're proper, also drop fragments and queries as they won't be in the sitemap that way
          link.fragment = nil
          link.query = nil
          link.path = link.path.gsub(/\/+/, '/') if link.path

          unless context.pages.keys.include?(link.to_s) || context.pages.keys.include?((link.to_s + '/'))
            locations.each do |location|
              location[:page].errors << Blinkr::Error.new({:severity => :warning,
                                                           :category => 'Resource missing from sitemap',
                                                           :type => '<a href=""> target missing from sitemap',
                                                           :url => url, :title => "#{url} (line #{location[:line]})",
                                                           :code => nil,
                                                           :message => 'Missing from sitemap',
                                                           :detail => 'Checked with Typheous',
                                                           :snippet => location[:snippet],
                                                           :icon => 'fa-bookmark-o'
                                                          })
              # It wasn't in the sitemap, so we'll add it to the "external_links" to still be checked
            end
          end
        end
        @links.each do |url, metadata|
          # if link start_with? @config.base_url check to see if it's in the sitemap.xml
          browser.process(url, @config.max_retrys, :method => :get, :followlocation => true, :timeout => 60,
                                                   :cookiefile => '_tmp/cookies', :cookiejar => '_tmp/cookies',
                          :connecttimeout => 30, :maxredirs => 3) do |resp|
            puts "Loaded #{url} via #{browser.name} #{'(cached)' if resp.cached?}" if @config.verbose

            resp_code = resp.code.to_i
            if ((resp_code > 300 && resp_code < 400) && @config.warning_on_300s) || resp_code > 400
              response = resp

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
              metadata.each do |src|
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
        browser.hydra.run if browser.is_a? Blinkr::TyphoeusWrapper
        puts "Total time in links: #{(DateTime.now.to_time - start.to_time).duration}" if @config.verbose
      end

    end
  end
end

