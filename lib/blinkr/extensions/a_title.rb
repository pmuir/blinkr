require 'blinkr/error'
require 'nokogiri'

module Blinkr
  module Extensions
    class ATitle

      def initialize config
        @config = config
      end

      def collect page
        Nokogiri::HTML(page.response.body).freeze.css('a:not([title])').each do |a|
          page.errors << Blinkr::Error.new({:severity => 'info', :category => 'SEO',
                                            :type => '<a title=""> missing',
                                            :title => "#{a['href']} (line #{a.line})",
                                            :message => '<a title=""> missing',
                                            :snippet => a.to_s, :icon => 'fa-info'})
        end
      end

    end
  end
end
