require 'thread'

module Innate
  SEMAPHORE = Mutex.new

  module SingletonMethods
    # Use this method to achieve thread-safety for sensitive operations.
    #
    # This should be of most use when manipulating files to prevent other
    # threads from doing the same, no other code will be scheduled during
    # execution of this method.
    #
    # @param [Proc] block the things you want to execute
    def sync(&block)
      SEMAPHORE.synchronize(&block)
    end

    def defer
      outer = ::Thread.current
      ::Thread.new{
        inner = ::Thread.current
        outer.keys.each{|k| inner[k] = outer[k] }
        yield
      }
    end
  end
end
