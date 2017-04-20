module Blinkr
  class Cache
    def initialize
      @memory = {}
    end

    def get(request)
      @memory[request]
    end

    def set(request, response)
      if request.is_a? String # HACK: for caching resource and js errors
        @memory[request] = response
      else
        @memory[request] = response unless response.timed_out?
      end
    end

    def size
      @memory.size
    end
  end
end
