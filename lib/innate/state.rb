module Innate
  begin
    require 'innate/state/fiber'
    require 'innate/state/thread'
    STATE = State::Fiber.new
    puts "Innate uses Fiber"
  rescue LoadError
    require 'innate/state/thread'
    STATE = State::Thread.new
    puts "Innate uses Thread"
  end
end
