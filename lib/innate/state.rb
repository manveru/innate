module Innate
  state = options[:state]

  if state == :Fiber
    begin
      require 'innate/state/fiber'
      STATE = State::Fiber.new
    rescue LoadError
      require 'innate/state/thread'
      STATE = State::Thread.new
    end
  else
    require 'innate/state/thread'
    STATE = State::Thread.new
  end

  module SingletonMethods
    # Use this method to achieve thread-safety for sensitive operations.
    #
    # This should be of most use when manipulating files to prevent other
    # threads from doing the same, no other code will be scheduled during
    # execution of this method.
    #
    # @param [Proc] block the things you want to execute
    # @see State::Thread#sync State::Fiber#sync
    def sync(&block)
      STATE.sync(&block)
    end
  end
end
