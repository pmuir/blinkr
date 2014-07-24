require 'ostruct'
require 'slim'

module Blinkr
  module Extensions
    class Meta

      TMPL = File.expand_path('meta.html.slim', File.dirname(__FILE__))

      def initialize config
        @config = config
        @descriptions = {}
        @titles = {}
      end

      def collect page
        description page
        title page
      end

      def analyze context, typhoeus
        @descriptions.reject!{ |description, pages| pages.length <= 1 }
        @titles.reject!{ |title, pages| pages.length <= 1 }
      end

      def append context
        Slim::Template.new(TMPL).render(OpenStruct.new({ :descriptions => @descriptions, :titles => @titles }))
      end

      private

      def title page
        elms = page.body.css('title')
        if elms.length > 1
          snippets = []
          lines = []
          elms.each do |elm|
            lines << elm.line
            snippets << elm.to_s
          end
          page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{more than one <title> (lines #{lines.join(', ')})}, :message => %Q{more than one <title>}, :snippet => snippets.join('\n'), :icon => 'fa-header' })
        elsif elms.empty?
          page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{Missing <title>}, :message => %Q{Missing <title>}, :icon => 'fa-header' })
        else
          title = elms.first.text
          @titles[title] ||= {}
          @titles[title][page.response.effective_url] = page
          if title.length < 20
            page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{<title> too short (lines #{elms.first.line})}, :message => %Q{<title> too short (< 20 characters)}, :snippet => elms.first.to_s, :icon => 'fa-header' })
          end
          if title.length > 55
            page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{<title> too long (lines #{elms.first.line})}, :message => %Q{<title> too long (> 55 characters)}, :snippet => elms.first.to_s, :icon => 'fa-header' })
          end
        end
      end

      def description page
        elms = page.body.css('meta[name=description]')
        if elms.length > 1
          snippets = []
          lines = []
          elms.each do |elm|
            lines << elm.line
            snippets << elm.to_s
          end
          page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{more than one <meta name="description"> (lines #{lines.join(', ')})}, :message => %Q{more than one <meta name="description">}, :snippet => snippets.join('\n'), :icon => 'fa-header' })
        elsif elms.empty?
          page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{Missing <meta name="description">}, :message => %Q{Missing <meta name="description">}, :icon => 'fa-header' })
        else
          desc = elms.first['content']
          @descriptions[desc] ||= {}
          @descriptions[desc][page.response.effective_url] = page
          if desc.length < 60
            page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{<meta name="description"> too short (lines #{elms.first.line})}, :message => %Q{<meta name="description"> too short (< 60 characters)}, :snippet => elms.first.to_s, :icon => 'fa-header' })
          end
          if desc.length > 115
            page.errors << OpenStruct.new({ :type => 'meta',  :title => %Q{<meta name="description"> too long (lines #{elms.first.line})}, :message => %Q{<meta name="description"> too long (> 115 characters)}, :snippet => elms.first.to_s, :icon => 'fa-header' })
          end
        end
      end

    end
  end
end
