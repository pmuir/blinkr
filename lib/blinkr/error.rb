module Blinkr
  class Error
    attr_reader :severity, :category, :type, :title, :message, :snippet, :icon, :code, :detail, :url

    def initialize (opts = {})
      @severity = opts[:severity]
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
  end
end
