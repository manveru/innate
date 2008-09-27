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

      def wrap
        thread = ::Thread.new{ begin; yield; rescue Object => ex; ex; end }
        value = thread.value
        raise(value) if Exception === value
        return value
      end
    end
  end
end
