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
      p "State uses #@core"
    end

    def detect
      @extract = :value
      @core = Thread
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
