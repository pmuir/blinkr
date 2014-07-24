require 'slim'
require 'ostruct'

module Blinkr
  class Report

    TMPL = File.expand_path('report.html.slim', File.dirname(__FILE__))

    def self.render(context, engine, config)
      
    end

    def initialize context, engine, config
      @context = context
      @engine = engine
      @config = config
    end

    def render
      File.open(@config.report, 'w') { |file| file.write(Slim::Template.new(TMPL).render(OpenStruct.new({ :blinkr => @context, :engine => @engine }))) }
    end

  end
end
