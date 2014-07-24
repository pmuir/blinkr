module Blinkr
  module Extensions
    class EmptyAHref

      def initialize config
        @config = config
      end

      def collect page
        page.body.css('a[href]').each do |a|
          if a['href'].empty?
            page.errors << OpenStruct.new({ :type => 'empty_a_href',  :title => %Q{empty <a href="" /> (line #{a.line})}, :message => %Q{empty <a href="" />}, :snippet => a.to_s, :icon => 'fa-info' })
          end
        end
      end

    end
  end
end
