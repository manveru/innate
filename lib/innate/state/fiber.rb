require 'fiber'

module Innate
  class Fiber < ::Fiber
    attr_accessor :state

    def self.new(*args)
      instance = super
      instance.state = {}
      instance
    end

    def [](key)
      state[key]
    end

    def []=(key, value)
      state[key] = value
    end

    def key?(key)
      state.key?(key)
    end
  end

  module State
    class Fiber
      def [](key)
        Innate::Fiber.current[key]
      end

      def []=(key, value)
        Innate::Fiber.current[key] = value
      end

      def wrap(&block)
        Innate::Fiber.new(&block).resume
      end

      def sync #(&block)
        yield
      end
    end
  end
end
