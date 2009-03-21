require 'thread'

module Innate
  module State
    # In case fibers are not available we fall back to this wrapper.
    #
    # It will raise errors happening inside the wrapping Thread even if
    # Thread::abort_on_exception is false.
    #
    # For things that require a mutex in a threaded environment, use
    # STATE#sync, if Fiber is available no mutex will be used.

    class Thread
      SEMAPHORE = Mutex.new

      def [](key)
        ::Thread.current[key]
      end

      def []=(key, value)
        ::Thread.current[key] = value
      end

      # Execute given block in a new Thread and rescue any exceptions before
      # they reach Thread::new, so in case Thread::raise_on_exception is false
      # we can still reraise the error outside of the Thread.
      #
      # This is not meant to be concurrent, we only use Thread as a wrapping
      # context so we can store objects in Thread::current and access them from
      # anywhere within this thread.
      def wrap
        value = ::Thread.new{ begin; yield; rescue Exception => ex; ex; end }.value
        raise(value) if Exception === value
        return value
      end

      def sync(&block)
        SEMAPHORE.synchronize(&block)
      end

      def defer
        a = ::Thread.current
        ::Thread.new{ b = ::Thread.current; a.keys.each{|k| b[k] = a[k] }; yield }
      end
    end
  end
end
