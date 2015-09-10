module Blinkr
  SEVERITY = [:success, :info, :warning, :danger]
  class Error
    attr_reader :severity, :category, :type, :title, :message, :snippet, :icon, :code, :detail, :url

    def initialize (opts = {})
      raise TypeError 'severity must be a string or symbol' unless opts[:severity].is_a?(String) || opts[:severity].is_a?(Symbol)
      raise 'severity not a recognized value' unless SEVERITY.include? opts[:severity].to_sym

      @severity = opts[:severity].to_sym
      @category = opts[:category]
      @type = opts[:type]
      @title = opts[:title]
      @message = opts[:message]
      @snippet = opts[:snippet]
      @icon = opts[:icon]
      @code = opts[:code]
      @url = opts[:url]
      @detail = opts[:detail]
    end

    def to_json(*args)
      content = {}
      instance_variables.each do |v|
        content[v.to_s[1..-1]] = instance_variable_get v
      end
      content.to_json
    end
  end
end
