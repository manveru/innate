require 'thread'

Thread.abort_on_exception = true

class Fiber
  class FiberError < StandardError; end

  attr_reader :yield, :thread, :hash

  def initialize
    raise ArgumentError, 'new Fiber requires a block' unless block_given?

    @yield = Queue.new
    @resume = Queue.new
    @hash = {}

    @thread = Thread.new{ @yield.push(yield(wait)) }
    @thread[:fiber] = self
  end

  def wait
    @resume.pop
  end

  def resume(*args)
    if @thread.alive?
      @resume.push(args)
      @yield.pop
    else
      raise FiberError, 'dead fiber called'
    end
  end

  def self.yield(*args)
    if fiber = Thread.current[:fiber]
      fiber.yield.push(*args)
      fiber.wait
    else
      raise FiberError, "can't yield from root fiber"
    end
  end

  def self.current
    Thread.current[:fiber]
  end

  def []=(key, value)
    @hash[key] = value
  end

  def [](key)
    @hash[key]
  end

  # There should be a way to do the correct id via:
  # '%#08x' % (object_id << 1)
  # but for some reason that results in a length of 9 instead of 8
  def inspect
    "#<#{self.class}:0x#{('%08x' % (object_id << 1))[1,8]}>"
  end
end
