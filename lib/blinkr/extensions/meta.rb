require 'blinkr/error'
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
        context.duplicate_descriptions = @descriptions.reject{ |description, pages| pages.length <= 1 }
        context.duplicate_titles = @titles.reject{ |title, pages| pages.length <= 1 }
      end

      def append context
        Slim::Template.new(TMPL).render(OpenStruct.new({ :descriptions => context.duplicate_descriptions, :titles => context.duplicate_titles }))
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
          page.errors << Blinkr::Error.new({:severity => :danger, :category => 'HTML Compatibility/Correctness',
                                            :type => '<title> tag declared more than once',
                                            :title => %Q{<title> declared more than once (lines #{lines.join(', ')})},
                                            :message => %Q{<title> declared more than onc},
                                            :snippet => snippets.join('\n'), :icon => 'fa-header'})
        elsif elms.empty?
          page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO', :type => '<title> tag missing',
                                            :title => %Q{<title> tag missing}, :message => %Q{<title> tag missing},
                                            :icon => 'fa-header'})
        else
          title = elms.first.text
          @titles[title] ||= {}
          @titles[title][page.response.effective_url] = page
          if title.length < 20
            page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO', :type => 'page title too short',
                                              :title => %Q{<title> too short (line #{elms.first.line})},
                                              :message => %Q{<title> too short (< 20 characters)},
                                              :snippet => elms.first.to_s, :icon => 'fa-header'})
          end
          if title.length > 55
            page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO', :type => 'page title too long',
                                              :title => %Q{<title> too long (line #{elms.first.line})},
                                              :message => %Q{<title> too long (> 55 characters)},
                                              :snippet => elms.first.to_s, :icon => 'fa-header'})
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
          page.errors << Blinkr::Error.new({:severity => :danger, :category => 'HTML Compatibility/Correctness',
                                            :type => '<meta name="description"> tag declared more than once',
                                            :title => %Q{<meta name="description"> tag declared more than once (lines #{lines.join(', ')})},
                                            :message => %Q{<meta name="description"> tag declared more than once},
                                            :snippet => snippets.join('\n'), :icon => 'fa-header'})
        elsif elms.empty?
          page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO',
                                            :type => '<meta name="description"> tag missing',
                                            :title => %Q{<meta name="description"> tag missing},
                                            :message => %Q{<meta name="description"> tag missing},
                                            :icon => 'fa-header'})
        else
          desc = elms.first['content']
          @descriptions[desc] ||= {}
          @descriptions[desc][page.response.effective_url] = page
          if desc.length < 60
            page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO',
                                              :type => '<meta name="description"> too short',
                                              :title => %Q{<meta name="description"> too short (lines #{elms.first.line})},
                                              :message => %Q{<meta name="description"> too short (< 60 characters)},
                                              :snippet => elms.first.to_s, :icon => 'fa-header'})
          end
          if desc.length > 115
            page.errors << Blinkr::Error.new({:severity => :warning, :category => 'SEO',
                                              :type => '<meta name="description"> too long',
                                              :title => %Q{<meta name="description"> too long (lines #{elms.first.line})},
                                              :message => %Q{<meta name="description"> too long (> 115 characters)},
                                              :snippet => elms.first.to_s, :icon => 'fa-header'})
          end
        end
      end

    end
  end
end
