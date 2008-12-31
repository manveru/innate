module Innate

  # This is a dynamic routing mapper used to outsmart Rack::URLMap
  # Every time a mapping is changed a new Rack::URLMap will be put into
  # Innate::DynaMap::CACHE[:map]

  class DynaMap
    MAP = {}
    CACHE = {}

    # Delegate the call to the current Rack::URLMap instance.

    def self.call(env)
      if app = CACHE[:map]
        app.call(env)
      else
        raise "Nothing mapped yet"
      end
    end

    # Map node to location, create a new Rack::URLMap instance and cache it.

    def self.map(location, node)
      MAP[location] = node
      CACHE[:map] = Rack::URLMap.new(MAP)
    end
  end

  module_function

  # Example:
  #
  #   Innate.map('/', lambda{|env| [200, {}, "Hello, World"] })
  #

  def map(location, node)
    DynaMap.map(location, node)
  end

  def at(location)
    DynaMap::MAP[location]
  end

  def to(node)
    DynaMap::MAP.invert[node]
  end
end
