module Blinkr
  class Cache
    def initialize
      @memory = {}
    end

    def get(request)
      @memory[request]
    end

    def set(request, response)
      @memory[request] = response unless response.timed_out?
    end
  end
end

