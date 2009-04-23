module Innate
  class URLMap < Rack::URLMap
    def initialize(map = {})
      @originals = map
      super
    end

    # super may raise when given invalid locations, so we only replace the
    # `@originals` if we are sure the new map is valid
    def remap(map)
      value = super
      @originals = map
      value
    end

    def map(location, object)
      return unless location and object
      remap(@originals.merge(location.to_s => object))
    end

    def delete(location)
      @originals.delete(location)
      remap(@originals)
    end

    def at(location)
      @originals[location]
    end

    def to(object)
      @originals.invert[object]
    end

    def to_hash
      @originals.dup
    end

    def call(env)
      raise "Nothing mapped yet" if @originals.empty?
      super
    end
  end

  DynaMap = URLMap.new

  # script_name, path_info = env['SCRIPT_NAME'], env['PATH_INFO']
  # answer = app.call(env)
  # env.merge!('SCRIPT_NAME' => script_name, 'PATH_INFO' => path_info)
  # answer

  module SingletonMethods
    # Maps the given +object+ or +block+ to +location+, +object+ must respond to
    # #call in order to be of any use.
    #
    # @example with passed +object+
    #
    #   Innate.map('/', lambda{|env| [200, {}, "Hello, World"] })
    #   Innate.at('/').call({}) # => [200, {}, "Hello, World"]
    #
    # @example with passed +block+
    #
    #   Innate.map('/'){|env| [200, {}, ['Hello, World!']] }
    #   Innate.at('/').call({})
    def map(location, object = nil, &block)
      DynaMap.map(location, object || block)
    end

    # Answer with object at +location+.
    #
    # @example
    #
    #   class Hello
    #     include Innate::Node
    #     map '/'
    #   end
    #
    #   Innate.at('/') # => Hello
    def at(location)
      DynaMap.at(location)
    end

    # Returns one of the paths the given +object+ is mapped to.
    #
    # @example
    #
    #   class Hello
    #     include Innate::Node
    #     map '/'
    #   end
    #
    #   Innate.to(Hello) # => '/'
    def to(object)
      DynaMap.to(object)
    end
  end
end
