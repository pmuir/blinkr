require 'slim'
require 'ostruct'
require 'blinkr/error'

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
      @context.pages.delete_if { |_, page| page.errors.empty? }
      @context.total = 0
      @context.severity = {}
      @context.category = {}
      @context.pages.each do |_, page|
        page.max_severity = ::Blinkr::SEVERITY.first # :success
        page.errors.each do |error|
          raise "#{error.severity} not a valid severity. Must be one of #{::Blinkr::SEVERITY.join(',')}" unless ::Blinkr::SEVERITY.include? error.severity
          raise "#{error.category} must be specified." if error.category.nil?
          @context.total += 1
          @context.severity[error.severity] ||= OpenStruct.new({:count => 0})
          @context.severity[error.severity].count += 1
          page.max_severity = error.severity if ::Blinkr::SEVERITY.index(error.severity) > ::Blinkr::SEVERITY.index(page.max_severity)
          @context.category[error.category] ||= OpenStruct.new({:count => 0, :types => {}})
          @context.category[error.category].count += 1
          @context.category[error.category].types[error.type] ||= OpenStruct.new({:count => 0})
          @context.category[error.category].types[error.type].count += 1
        end
      end
      File.open(@config.report, 'w') do |file|
        file.write(Slim::Template.new(TMPL).render(OpenStruct.new({:blinkr => @context, :engine => @engine,
                                                                   :errors => @context.to_json})))
      end
      
      # File.open(@config.json_report, 'w') do |file|
      #   file.write(@context.to_json)
      # end
      puts "Wrote report to #{@config.report}" if @config.verbose
    end

  end
end
