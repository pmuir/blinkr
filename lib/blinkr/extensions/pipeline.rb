
Dir[ File.join( File.dirname(__FILE__), '*.rb' ) ].each do |f|
  begin
    require f
  rescue LoadError => e
    $LOG.warn "Missing required dependency to activate optional built-in extension #{File.basename(f)}\n  #{e}" if $LOG.debug?
  rescue StandardError => e
    $LOG.warn "Missing runtime configuration to activate optional built-in extension #{File.basename(f)}\n  #{e}" if $LOG.debug?
  end
end

module Blinkr
  module Extensions
    class Pipeline

      attr_reader :extensions

      def initialize(&block)
        @extensions = []
        @block = block
      end

      def load config
        begin
          instance_exec config, &@block if @block && @block.arity == 1
          instance_exec &@block if @block && @block.arity == 0
          self
        rescue Exception => e
          abort("Failed to initialize pipeline: #{e}")
        end
      end

      def extension(ext)
        @extensions << ext
      end

    end
  end
end

