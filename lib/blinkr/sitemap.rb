require 'open-uri'
module Blinkr
  module Sitemap

    def sitemap_locations
      open_sitemap.css('loc').collect { |loc| loc.content }
    end

    private

    def open_sitemap
      puts "Loading sitemap from #{@config.sitemap}"
      if @config.sitemap =~ URI::regexp
        Nokogiri::XML(open(@config.sitemap).read)
      else
        Nokogiri::XML(File.open(@config.sitemap))
      end
    end

  end
end
