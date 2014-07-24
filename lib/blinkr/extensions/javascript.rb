module Blinkr
  module Extensions
    class JavaScript

      def initialize config
        @config = config
      end

      def collect page
        page.javascript_errors.each do |error|
          page.errors << OpenStruct.new({ :type => 'javascript', :title => error.msg, :snippet => error.trace, :icon => 'fa-gears' })
        end
      end

    end
  end
end
