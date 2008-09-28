module Innate
  class DynaMap
    MAP = {}
    CACHE = {}

    def self.call(env)
      CACHE[:map].call(env)
    end

    def self.map(location, node)
      MAP[location] = node
      CACHE[:map] = Rack::URLMap.new(MAP)
    end
  end

  module_function

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
