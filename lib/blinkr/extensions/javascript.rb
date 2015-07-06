require 'blinkr/error'

module Blinkr
  module Extensions
    class JavaScript

      def initialize config
        @config = config
      end

      def collect page
        page.javascript_errors.each do |error|
          page.errors << Blinkr::Error.new(:severity => 'danger', :category => 'JavaScript',
                                           :type => 'JavaScript error', :title => error['msg'],
                                           :snippet => error['trace'], :icon => 'fa-gears')
        end
      end

    end
  end
end
