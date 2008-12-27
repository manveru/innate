module Innate
  begin
    require 'innate/state/fiber'
    require 'innate/state/thread'
    STATE = State::Fiber.new
    # Log.debug "Innate uses Fiber"
  rescue LoadError
    require 'innate/state/thread'
    STATE = State::Thread.new
    # Log.debug "Innate uses Thread"
  end

  def self.sync(&block)
    STATE.sync(&block)
  end
end
