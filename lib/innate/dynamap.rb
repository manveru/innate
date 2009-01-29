module Innate

  # This is a dynamic routing mapper used to outsmart Rack::URLMap
  # Every time a mapping is changed a new Rack::URLMap will be put into
  # Innate::DynaMap::CACHE[:map]
  class DynaMap
    MAP = {}
    CACHE = {}

    # Delegate the call to the current Rack::URLMap instance.
    #
    # NOTE: Currently Rack::URLMap will destructively modify PATH_INFO and
    #       SCRIPT_NAME, which leads to incorrect routing as parts of the
    #       PATH_INFO are cut out if they matched once.
    #       Here I repair this damage and hope that my patch to rack will be
    #       accepted.
    def self.call(env)
      if app = CACHE[:map]
        script_name, path_info = env['SCRIPT_NAME'], env['PATH_INFO']
        answer = app.call(env)
        env.merge!('SCRIPT_NAME' => script_name, 'PATH_INFO' => path_info)
        answer
      else
        raise "Nothing mapped yet"
      end
    end

    # Map node to location, create a new Rack::URLMap instance and cache it.
    def self.map(location, node)
      return unless location
      MAP[location.to_s] = node
      CACHE[:map] = Rack::URLMap.new(MAP)
    end
  end

  module_function

  # Maps the given +object+ or +block+ to +location+, +object+ must respond to
  # #call in order to be of any use.
  #
  # Usage with passed +object+:
  #
  #   Innate.map('/', lambda{|env| [200, {}, "Hello, World"] })
  #   Innate.at('/').call({}) # => [200, {}, "Hello, World"]
  #
  # Usage with passed +block+:
  #
  #   Innate.map('/'){|env| [200, {}, ['Hello, World!']] }
  #   Innate.at('/').call({})
  def map(location, object = nil, &block)
    DynaMap.map(location, object || block)
  end

  # Answer with object at +location+.
  #
  # Usage:
  #
  #   class Hello
  #     include Innate::Node
  #     map '/'
  #   end
  #
  #   Innate.at('/') # => Hello
  def at(location)
    DynaMap::MAP[location.to_s]
  end

  # Returns one of the paths the given +object+ is mapped to.
  #
  # Usage:
  #
  #   class Hello
  #     include Innate::Node
  #     map '/'
  #   end
  #
  #   Innate.to(Hello) # => '/'
  def to(object)
    DynaMap::MAP.invert[object]
  end
end
