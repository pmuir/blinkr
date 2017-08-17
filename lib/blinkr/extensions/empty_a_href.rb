require 'blinkr/error'

module Blinkr
  module Extensions
    class EmptyAHref
      def initialize(config)
        @config = config
      end

      def collect(page)
        page.body.css('a[href]').each do |a|
          if a['href'].empty?
            page.errors << Blinkr::Error.new(severity: 'info',
                                             category: 'HTML Compatibility/Correctness',
                                             type: '<a href=""> empty',
                                             title: %(<a href=''> empty (line #{a.line})),
                                             message: %(<a href=''> empty),
                                             snippet: a.to_s,
                                             icon: 'fa-info')
          end
        end
      end
    end
  end
end
