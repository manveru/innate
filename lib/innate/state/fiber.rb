require 'fiber'

module Innate
  # Innate subclasses Fiber to enable lightweight request/respose-cycle local
  # variables.
  #
  # We do that by adding a state Hash to the Fiber instance on initalization
  # which can be accessed by #[], #[]= and #key?. Other Hash methods are not
  # necessary right now but may be added.
  #
  # We subclass to keep your Ruby clean and polished.
  class Fiber < ::Fiber
    attr_accessor :state

    def initialize(*args)
      super
      @state = {}
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

    def keys
      state.keys
    end
  end

  module State
    # Our accessor to the currently active Fiber, an instance of
    # Innate::State::Fiber will be assigned to Innate::STATE if fibers are
    # available.
    class Fiber
      def [](key)
        ::Fiber.current[key]
      end

      def []=(key, value)
        ::Fiber.current[key] = value
      end

      # We don't use Fiber in a concurrent manner and they don't run
      # concurrently by themselves, so we directly #resume the Fiber to get the
      # return value of +block+.

      def wrap(&block)
        Innate::Fiber.new(&block).resume
      end

      # In an environment where only Fiber is used there is no concurrency, so
      # we don't have to lock with a Mutex.

      def sync
        yield
      end

      def defer
        a = Innate::Fiber.current
        ::Thread.new do
          b = Innate::Fiber.new{ a.keys.each{|k| b[k] = a[k] }; yield }
          b.resume
        end
      end
    end
  end
end
