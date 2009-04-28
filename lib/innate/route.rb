module Innate
  # Innate support simple routing using string, regex and lambda based routers.
  # Route are stored in a dictionary, which supports hash-like access but
  # preserves order, so routes are evaluated in the order they are added.
  #
  # This middleware should wrap Innate::DynaMap.
  #
  # Please note that Rack::File is put before Route and Rewrite, that means
  # that you cannot apply routes to static files unless you add your own route
  # middleware before.
  #
  # String routers are the simplest way to route in Innate. One path is
  # translated into another:
  #
  #   Innate::Route[ '/foo' ] = '/bar'
  #     '/foo'  =>  '/bar'
  #
  # Regex routers allow matching against paths using regex. Matches within
  # your regex using () are substituted in the new path using printf-like
  # syntax.
  #
  #   Innate::Route[ %r!^/(\d+)\.te?xt$! ] = "/text/%d"
  #     '/123.txt'  =>  '/text/123'
  #     '/789.text' =>  '/text/789'
  #
  # For more complex routing, lambda routers can be used. Lambda routers are
  # passed in the current path and request object, and must return either a new
  # path string, or nil.
  #
  #   Innate::Route[ 'name of route' ] = lambda{ |path, request|
  #     '/bar' if path == '/foo' and request[:bar] == '1'
  #   }
  #     '/foo'        =>  '/foo'
  #     '/foo?bar=1'  =>  '/bar'
  #
  # Lambda routers can also use this alternative syntax:
  #
  #   Innate::Route('name of route') do |path, request|
  #     '/bar' if path == '/foo' and request[:bar] == '1'
  #   end
  #
  # NOTE: Use self::ROUTES notation in singleton methods to force correct
  #       lookup.

  class Route
    ROUTES = []

    def self.[](key)
      found = self::ROUTES.assoc(key)
      found[1] if found
    end

    def self.[]=(key, value)
      self::ROUTES.delete_if{|k,v| k == key }
      self::ROUTES << [key, value]
    end

    def self.clear
      self::ROUTES.clear
    end

    def initialize(app = Innate::DynaMap)
      @app = app
    end

    def call(env)
      path = env['PATH_INFO']
      path << '/' if path.empty?

      if modified = resolve(path)
        Log.debug("%s routes %p to %p" % [self.class.name, path, modified])
        env['PATH_INFO'] = modified
      end

      @app.call(env)
    end

    def resolve(path)
      self.class::ROUTES.each do |key, value|
        if key.is_a?(Regexp)
          md = path.match(key)
          return value % md.to_a[1..-1] if md

        elsif value.respond_to?(:call)
          new_path = value.call(path, Current.request)
          return new_path if new_path

        elsif value.respond_to?(:to_str)
          return value.to_str if path == key

        else
          Log.error("Invalid route %p => %p" % [key, value])
        end
      end

      nil
    end
  end

  # Identical with Innate::Route, but is called before any Node::call is made
  class Rewrite < Route
    ROUTES = []
  end

  module SingletonMethods
    def Route(key, value = nil, &block)
      Route[key] = value || block
    end

    def Rewrite(key, value = nil, &block)
      Rewrite[key] = value || block
    end
  end
end
