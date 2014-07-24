module Blinkr
  module Extensions
    class ATitle

      def initialize config
        @config = config
      end

      def collect page
        page.body.css('a:not([title])').each do |a|
          page.errors << OpenStruct.new({ :type => 'a_title_missing',  :title => "#{a['href']} (line #{a.line})", :message => 'title text missing', :snippet => a.to_s, :icon => 'fa-info' })
        end
      end

    end
  end
end
