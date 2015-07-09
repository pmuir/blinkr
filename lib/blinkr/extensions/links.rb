require 'uri'
require 'blinkr/error'
require 'blinkr/http_utils'
require 'nokogiri'

module Blinkr
  module Extensions
    class Links
      include Blinkr::HttpUtils

      def initialize(config)
        @config = config
        @links = {}
      end

      def collect(page)
        Nokogiri::HTML(page.response.body).freeze.css('a[href]').each do |a|
          attr = a.attribute('href')
          src = page.response.effective_url
          url = attr.value
          unless @config.skipped?(url)
            url = sanitize url, src
            if url.nil?
              page.errors << Blinkr::Error.new({:severity => :warning, :category => 'URL could not be checked',
                                                :type => 'URL could not be checked', :url => url,
                                                :title => "#{url} could not be checked (line #{attr.line})",
                                                :code => nil, :message => 'Not checked',
                                                :detail => 'Failed URI creation', :snippet => a.to_s,
                                                :icon => 'fa-bookmark-o'
                                               })
            else
              @links[url] ||= []
              @links[url] << {:page => page, :line => attr.line, :snippet => a.to_s}
            end
          end
        end
      end

      def analyze(context, browser)
        puts '----------------------'
        puts " #{@links.length} links to check "
        puts '----------------------'
        external_links = @links.reject { |k| k.start_with? @config.base_url }
        processed = 0
        # Find the internal links
        @links.select{|k| k.start_with? @config.base_url}.each do |url, locations|
          link = URI.parse(url)
          link.fragment = nil
          link.query = nil
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
              external_links[url] = locations
            end
          end
        end
        puts "Ready to process external links" if @config.verbose
        browser.process_all(external_links.keys, @config.max_retrys, :method => :get, :followlocation => true) do |resp, url|
          puts "Loaded #{url} via #{browser.name}" if @config.verbose
          if resp.code.to_i < 200 || resp.code.to_i > 300
            response = resp

            metadata = @links[url]
            metadata.each do |src|
              detail = nil
              if response.respond_to?(:status_message)
                message = response.status_message
              end

              if response.respond_to?(:message)
                message = response.message
              end

              if response.respond_to?(:return_message)
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
                                                      :icon => 'fa-bookmark-o'})
            end
          end
          processed += 1
          puts "Processed #{processed} of #{external_links.size}" if @config.verbose
        end
        # external_links.each do |url, metadata|
        #   # if link start_with? @config.base_url check to see if it's in the sitemap.xml
        #   browser.process(url, @config.max_retrys, :method => :get, :followlocation => true) do |resp|
        #     puts "Loaded #{url} via #{browser.name} #{'(cached)' if resp.cached?}" if @config.verbose
        #     if resp.code.to_i < 200 || resp.code.to_i > 300
        #       response = resp
        #
        #       metadata.each do |src|
        #         detail = nil
        #         if response.status_message.nil?
        #           message = response.return_message
        #         else
        #           message = response.status_message
        #           detail = response.return_message unless resp.return_message == 'No error'
        #         end
        #
        #         severity = :danger
        #         if response.code.to_i >= 300 && response.code.to_i < 400
        #           severity = :warning
        #         end
        #         src[:page].errors << Blinkr::Error.new({:severity => severity,
        #         :category => 'Resources missing',
        #         :type => '<a href=""> target cannot be loaded',
        #         :url => url, :title => "#{url} (line #{src[:line]})",
        #         :code => response.code.to_i, :message => message,
        #         :detail => detail, :snippet => src[:snippet],
        #         :icon => 'fa-bookmark-o'}) unless response.success?
        #       end
        #     end
        #     processed += 1
        #     puts "Processed #{processed} of #{external_links.size}" if @config.verbose
        #   end
        # end
        # browser.hydra.run if browser.is_a? Blinkr::TyphoeusWrapper
      end

    end
  end
end

