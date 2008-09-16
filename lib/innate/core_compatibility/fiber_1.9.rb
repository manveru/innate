module Innate
  class Fiber < ::Fiber
    attr_accessor :state

    def initialize(*args)
      @state = {}
    end

    def [](key)
      @state[key]
    end

    def []=(key, value)
      @state[key] = value
    end

    def key?(key)
      @state.key?(key)
    end
  end
end
