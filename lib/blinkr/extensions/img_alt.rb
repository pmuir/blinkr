require 'blinkr/error'
require 'nokogiri'

module Blinkr
  module Extensions
    class ImgAlt

      def initialize config
        @config = config
      end

      def collect page
        Nokogiri::HTML(page.response.body).freeze.css('img:not([alt])').each do |img|
          page.errors << OpenStruct.new({:severity => 'warning', :category => 'SEO',
                                         :type => '<img alt=""> missing',
                                         :title => "#{img['src']} (line #{img.line})",
                                         :message => '<img alt=""> missing', :snippet => img.to_s,
                                         :icon => 'fa-info'})
        end
      end

    end
  end
end
