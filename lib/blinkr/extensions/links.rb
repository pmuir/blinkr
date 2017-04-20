require 'uri'
require 'blinkr/error'
require 'blinkr/http_utils'

module Blinkr
  module Extensions
    # This class is used to collect and analyze links that are present on the page,
    # raise errors if links are broken, missing from sitemap, as well as user-configured errors/warnings.
    class Links
      include Blinkr::HttpUtils

      def initialize(config)
        @config = config
        @links = {}
        @logger = Blinkr.logger
      end

      # Collect all hrefs and return links and their location on page.
      def collect(page)
        page.body.css('a[href]').each do |a|
          attr = a.attribute('href')
          src = page.response.effective_url
          url = attr.value
          unless @config.skipped?(url)
            url = sanitize(url, src)
            unless url.nil?
              @links[url] ||= []
              @links[url] << { page: page, line: attr.line, snippet: attr.parent.to_s }
            end
          end
        end
        @links
      end

      def analyze(context, browser)
        @logger.info("Found #{@links.length} links".yellow)
        start = DateTime.now

        # warn if internal links do not exist within sitemap
        unless @config.ignore_internal
          internal_links = @links.select { |k| k.start_with? @config.base_url }
          internal_links.each do |url, locations|
            link = fixup_link(url)
            unless context.pages.keys.include?(link.to_s) || context.pages.keys.include?("#{link}/")
              locations.each do |location|
                location[:page].errors << Blinkr::Error.new(severity: :warning,
                                                            category: 'Resource missing from sitemap',
                                                            type: '<a href=""> target missing from sitemap',
                                                            url: link.to_s,
                                                            title: "#{link} (line #{location[:line]})",
                                                            code: nil,
                                                            message: 'Missing from sitemap',
                                                            detail: 'Checked with Typheous',
                                                            snippet: location[:snippet],
                                                            icon: 'fa-bookmark-o')
              end
            end
          end
        end

        unless @config.environments.empty?
          # Raise an error if links contain user specified environment urls.
          # For example in a staging environment you may wish to warn/error
          # if links are incorrectly linking to a production environment.
          @links.each do |url, locations|
            if @config.environments.kind_of?(Array)
              @config.environments.each do |env|
                if url.to_s.include?(env)
                  locations.each do |location|
                    location[:page].errors << Blinkr::Error.new(severity: :danger,
                                                                category: 'Incorrect Environment',
                                                                type: '<a href=""> target is incorrect environment',
                                                                url: url.to_s,
                                                                title: "#{url} (line #{location[:line]})",
                                                                code: nil,
                                                                message: 'Incorrect Environment',
                                                                detail: 'Checked with Typheous',
                                                                snippet: location[:snippet],
                                                                icon: 'fa-bookmark-o')
                  end
                end
              end
            else
              if url.to_s.include?(@config.environments)
                locations.each do |location|
                  location[:page].errors << Blinkr::Error.new(severity: :danger,
                                                              category: 'Incorrect Environment',
                                                              type: '<a href=""> target is incorrect environment',
                                                              url: url.to_s,
                                                              title: "#{url} (line #{location[:line]})",
                                                              code: nil,
                                                              message: 'Incorrect Environment',
                                                              detail: 'Checked with Typheous',
                                                              snippet: location[:snippet],
                                                              icon: 'fa-bookmark-o')
                end
              end
            end
          end
        end

        if @config.ignore_external
          @logger.info('Ignoring external links')
          internal_links = @links.select { |k| k.start_with? @config.base_url }
          check_links(browser, internal_links)
        elsif @config.ignore_internal
          @logger.info('Ignoring internal links')
          external_links = @links.reject { |k| k.start_with? @config.base_url }
          check_links(browser, external_links)
        else
          @logger.info('Checking internal and external links')
          check_links(browser, @links)
        end

        @logger.info("Total time to check links: #{(DateTime.now.to_time - start.to_time).duration}") if @config.verbose

      end

      private
      def fixup_link(url)
        link = URI.parse(url)
        link.fragment = nil
        link.query = nil
        link.path = link.path.gsub(%r{/\/+/}, '/') if link.path
        url = URI.parse(@config.base_url).merge(link).to_s
        url.chomp('/') if url[-1, 1] == '/'
      end

      def check_links(browser, links)
        processed = 0
        @logger.info("Checking #{links.length} links".yellow)
        links.each do |url, metadata|
          browser.process(url, @config.max_retrys, method: :get, followlocation: true, timeout: 60, cookiefile: '_tmp/cookies',
                          cookiejar: '_tmp/cookies', connecttimeout: 30, maxredirs: 3) do |resp|
            @logger.info("Loaded #{url} via #{browser.name} #{'(cached)' if resp.cached?}".green) if @config.verbose

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
                src[:page].errors << Blinkr::Error.new(severity: severity,
                                                       category: 'Broken link',
                                                       type: '<a href=""> target cannot be loaded',
                                                       url: url, title: "#{url} (line #{src[:line]})",
                                                       code: response.code.to_i, message: message,
                                                       detail: detail, snippet: src[:snippet],
                                                       icon: 'fa-bookmark-o') unless response.success?
              end
            end
            processed += 1
            @logger.info("Processed #{processed} of #{links.size}".yellow) if @config.verbose
          end
        end
        browser.hydra.run if browser.is_a? Blinkr::TyphoeusWrapper
      end
    end
  end
end
