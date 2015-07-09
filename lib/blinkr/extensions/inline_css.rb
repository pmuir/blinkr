require 'blinkr/error'
require 'nokogiri'

module Blinkr
  module Extensions
    class InlineCss

      def initialize config
        @config = config
      end

      def collect page
        Nokogiri::HTML(page.response.body).freeze.css('[style]').each do |elm|
          if elm['style'] == ""
            page.errors << Blinkr::Error.new({:severity => 'info', :category => 'HTML Compatibility/Correctness',
                                              :type => 'style attribute is empty',
                                              :title => %Q{"#{elm['style']}" (line #{elm.line})},
                                              :message => 'style attribute is empty', :snippet => elm.to_s,
                                              :icon => 'fa-info'})
          else
            page.errors << Blinkr::Error.new({:severity => 'info',
                                              :category => 'HTML Compatibility/Correctness',
                                              :type => 'Inline CSS detected',
                                              :title => %Q{"#{elm['style']}" (line #{elm.line})},
                                              :message => 'inline style', :snippet => elm.to_s,
                                              :icon => 'fa-info'})
          end
        end
      end

    end
  end
end
