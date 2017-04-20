require 'blinkr/error'

module Blinkr
  module Extensions
    class InlineCss
      def initialize(config)
        @config = config
      end

      def collect(page)
        page.body.css('[style]').each do |elm|
          elm_clone = Nokogiri.make(elm.to_s)
          elm_clone.inner_html = ''
          page.errors << if elm['style'] == ''
                           Blinkr::Error.new(severity: 'info',
                                             category: 'HTML Compatibility/Correctness',
                                             type: 'style attribute is empty',
                                             title: %{"#{elm['style']}" (line #{elm.line})},
                                             message: 'style attribute is empty', snippet: elm_clone.to_s,
                                             icon: 'fa-info')
                         else
                           Blinkr::Error.new(severity: 'info',
                                             category: 'HTML Compatibility/Correctness',
                                             type: 'Inline CSS detected',
                                             title: %{"#{elm['style']}" (line #{elm.line})},
                                             message: 'inline style', snippet: elm_clone.to_s,
                                             icon: 'fa-info')
                         end if @config.warn_inline_css
        end
      end
    end
  end
end
