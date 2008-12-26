require 'thread'

module Innate
  module State
    class Thread
      SEMAPHORE = Mutex.new

      def [](key)
        ::Thread.current[key]
      end

      def []=(key, value)
        ::Thread.current[key] = value
      end

      def wrap
        value = ::Thread.new{ begin; yield; rescue Exception => ex; ex; end }.value
        raise(value) if Exception === value
        return value
      end

      def sync(&block)
        SEMAPHORE.synchronize(&block)
      end
    end
  end
end
