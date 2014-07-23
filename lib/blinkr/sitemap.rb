module Blinkr
  module Sitemap

    def sitemap_locations
      open.css('loc').collect { |loc| loc.content }
    end

    private
    
    def open
      puts "Loading sitemap from #{@config.sitemap}"
      if @config.sitemap =~ URI::regexp
        Nokogiri::XML(Typhoeus.get(@config.sitemap, followlocation: true).body)
      else
        Nokogiri::XML(File.open(@config.sitemap))
      end
    end

  end
end
