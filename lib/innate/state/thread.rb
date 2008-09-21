require 'thread'

module Innate
  module State
    class Thread
      def [](key)
        ::Thread.current[key]
      end

      def []=(key, value)
        ::Thread.current[key] = value
      end

      def wrap(&block)
        ::Thread.new(&block).value
      end
    end
  end
end
