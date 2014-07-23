require 'slim'
require 'ostruct'

module Blinkr
  class Report

    TMPL = File.expand_path('report.html.slim', File.dirname(__FILE__))

    def self.render(context, pipeline, config)
      
    end

    def initialize context, pipeline, config
      @context = context
      @pipeline = pipeline
      @config = config
    end

    def render
      File.open(@config.report, 'w') { |file| file.write(Slim::Template.new(TMPL).render(OpenStruct.new({ :blinkr => @context, :pipeline => @pipeline }))) }
    end

  end
end
