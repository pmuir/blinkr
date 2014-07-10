require 'slim'
require 'ostruct'

module Blinkr
  class Report

    TMPL = File.expand_path('report.html.slim', File.dirname(__FILE__))

    def self.render(errors, out_file)
      out_file ||= 'blinkr.html'
      File.open(out_file, 'w') { |file| file.write(Slim::Template.new(TMPL).render(OpenStruct.new({:errors => errors}))) }
    end
  end
end
