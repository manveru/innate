module Innate
  class Fiber < ::Fiber
    def self.new(*args)
      instance = super
      instance.state = {}
      instance
    end

    attr_accessor :state

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
