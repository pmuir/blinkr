module Blinkr
  class SlimerJSWrapper < PhantomJSWrapper
    def name
      'slimerjs'
    end

    def command
      return 'xvfb-run slimerjs' if @config.xvfb
      'slimerjs'
    end
  end
end
