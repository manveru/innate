module Innate
  class FakeState
    S = {}

    def initialize(&block)
      S[:current] = self
      @hash = {}
      @block = block
    end

    def [](key)
      @hash[key]
    end

    def []=(key, value)
      @hash[key] = value
    end

    def value
      @block.call
    end

    def self.current
      S[:current]
    end
  end

  class State
    def initialize
      detect
      puts "Innate::State relies on #@core"
    end

    def detect
      require 'fiber'
      require 'lib/innate/core_compatibility/fiber_1.9'
      @core = Innate::Fiber
      @extract = :resume
    rescue LoadError
      @core = Thread
      @extract = :value
    end

    def [](key)
      @core.current[key]
    end

    def []=(key, value)
      @core.current[key] = value
    end

    def wrap(&block)
      @core.new(&block).send(@extract)
    end
  end
end

state = Innate::State.new
state.wrap do
  state[:a] = 1
end
