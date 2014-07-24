module Blinkr
  module Extensions
    class InlineCss

      def initialize config
        @config = config
      end

      def collect page
        page.body.css('[style]').each do |elm|
          page.errors << OpenStruct.new({ :type => 'inline_css',  :title => %Q{"#{elm['style']}" (line #{elm.line})}, :message => 'inline style', :snippet => elm.to_s, :icon => 'fa-info' })
        end
      end

    end
  end
end
