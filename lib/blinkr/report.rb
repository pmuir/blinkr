require 'slim'
require 'ostruct'
require 'blinkr/error'
require 'fileutils'

module Blinkr
  class Report
    require 'colorize'
    TMPL = File.expand_path('report.html.slim', File.dirname(__FILE__))

    def self.render(context, engine, config) end

    def initialize(context, engine, config)
      @context = context
      @engine = engine
      @config = config
      @logger = Blinkr.logger
    end

    def render
      @context.total = 0
      @context.severity = {}
      @context.category = {}
      @context.type = {}
      @context.pages.each do |url, page|
        page.url = url
        page.max_severity = ::Blinkr::SEVERITY.first # :success
        page.severities = []
        page.categories = []
        page.types = []
        page.errors.each do |error|
          raise("#{error.severity} not a valid severity. Must be one of #{::Blinkr::SEVERITY.join(',')}") unless ::Blinkr::SEVERITY.include? error.severity
          raise("#{error.category} must be specified.") if error.category.nil?
          @context.total += 1
          @context.severity[error.severity] ||= OpenStruct.new(count: 0)
          @context.severity[error.severity].count += 1
          page.severities << error.severity
          page.max_severity = error.severity if ::Blinkr::SEVERITY.index(error.severity) > ::Blinkr::SEVERITY.index(page.max_severity)
          @context.category[error.category] ||= OpenStruct.new(count: 0)
          @context.category[error.category].count += 1
          page.categories << error.category
          @context.type[error.type] ||= OpenStruct.new(count: 0)
          @context.type[error.type].count += 1
          page.types << error.type
        end
        page.severities.uniq!
        page.categories.uniq!
        page.types.uniq!
      end
      @context.pages = @context.pages.values
      File.open(@config.report, 'w') do |file|
        file.write(Slim::Template.new(TMPL).render(OpenStruct.new(blinkr: @context, engine: @engine, errors: @context.to_json)))
      end
      if @context.total > 0
        @context.severity[:danger].nil? ? danger = 0 : danger = @context.severity[:danger].count
        @context.severity[:warning].nil? ? warning = 0 : warning = @context.severity[:warning].count
        puts("Completed with a total of " + "#{danger} errors".red + " and " + "#{warning} warnings".yellow)
        File.open('blinkr_errors.json', 'w') do |file|
          file.write(@context.to_json)
        end
      else
        puts('Completed with no errors or warnings'.green)
      end
      puts("Wrote report to #{@config.report}") if @config.verbose
    end
  end
end
