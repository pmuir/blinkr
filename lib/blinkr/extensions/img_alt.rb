module Blinkr
  module Extensions
    class ImgAlt

      def initialize config
        @config = config
      end

      def collect page
        page.body.css('img:not([alt])').each do |img|
          page.errors << OpenStruct.new({ :type => 'img_alt_missing',  :title => "#{img['src']} (line #{img.line})", :message => 'alt text missing', :snippet => img.to_s, :icon => 'fa-info' })
        end
      end

    end
  end
end
