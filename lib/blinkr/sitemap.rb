require 'open-uri'
require 'openssl'
module Blinkr
  class Sitemap

    def initialize(config)
      @config = config
    end

    def sitemap_locations
      open_sitemap.css('loc').collect(&:content)
    end

    private

    def open_sitemap
      Blinkr.logger.info("Loading sitemap from #{@config.sitemap}".yellow)
      if @config.sitemap =~ URI.regexp
        Nokogiri::XML(handle_redirect(@config.sitemap).read)
      else
        # locally stored sitemap.xml file
        Nokogiri::XML(File.open(@config.sitemap))
      end
    end

    # Handle redirection forbidden error: http -> https
    def handle_redirect(url)
      uri = URI.parse(url)
      tries = 3
      begin
        uri.open(redirect: false, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      rescue OpenURI::HTTPRedirect => redirect
        uri = redirect.uri
        retry if (tries -= 1) > 0
        raise
      end
    end
  end
end
