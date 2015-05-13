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
      @context.severities = {}
      @context.categories = {}
      @context.types = {}
      @context.pages.each do |url, page|
        page.max_severity = 'success'
        page.errors.each do |error|
          raise "#{error.severity} not a valid severity. Must be one of #{SEVERITY.join(',')}" unless SEVERITY.include? error.severity
          raise "#{error.category} must be specified." if error.category.nil?
          @context.severities[error.severity] ||= OpenStruct.new({ :id => error.severity, :count => 0 })
          @context.severities[error.severity].count += 1
          page.max_severity = error.severity if SEVERITY.index(error.severity) > SEVERITY.index(page.max_severity)
          @context.categories[error.category] ||= OpenStruct.new({ :id => @context.categories.length, :count => 0, :severities => Hash.new(0), :types => {} })
          @context.categories[error.category].severities[error.severity] += 1
          @context.categories[error.category].types[error.type] ||= OpenStruct.new({ :id => @context.categories[error.category].types.length, :count => 0, :severities => Hash.new(0) })
          @context.categories[error.category].types[error.type].severities[error.severity] += 1
        end
      end
      @context.error_count = @context.severities.reduce(0){ |sum, (severity, metadata)| sum += metadata.count }
      File.open(@config.report, 'w') do |file|
        file.write(Slim::Template.new(TMPL).render(OpenStruct.new({:blinkr => @context, :engine => @engine,
                                                                   :errors => @context.to_json})))
      end
      puts "Wrote report to #{@config.report}" if @config.verbose
    end

    private 
    
    SEVERITY = ['success', 'info', 'warning', 'danger']

  end
end
