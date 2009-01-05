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

  # Log.debug("Innate keeps state with %p" % STATE.class)

  def self.sync(&block)
    STATE.sync(&block)
  end
end
