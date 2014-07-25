module Blinkr
  module Extensions
    class EmptyAHref

      def initialize config
        @config = config
      end

      def collect page
        page.body.css('a[href]').each do |a|
          if a['href'].empty?
            page.errors << OpenStruct.new({ :severity => 'info', :category => 'HTML Compatibility/Correctness', :type => '<a href=""> empty',  :title => %Q{<a href=""> empty (line #{a.line})}, :message => %Q{<a href=""> empty}, :snippet => a.to_s, :icon => 'fa-info' })
          end
        end
      end

    end
  end
end
