module Innate
  # Innate support simple routing using string, regex and lambda based routers.
  # Route are stored in a dictionary, which supports hash-like access but
  # preserves order, so routes are evaluated in the order they are added.
  #
  # This middleware should be inserted before calling the application but after
  # Innate::Current is called.
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

  class Route
    ROUTES = []

    def self.[](key)
      found = ROUTES.assoc(key)
      found[1] if found
    end

    def self.[]=(key, value)
      ROUTES.delete_if{|k,v| k == key }
      ROUTES << [key, value]
    end

    def self.clear
      ROUTES.clear
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      path = env['PATH_INFO']
      path << '/' if path.empty?

      if modified = resolve(path)
        env['PATH_INFO'] = modified
      end

      @app.call(env)
    end

    def resolve(path)
      ROUTES.each do |key, value|
        case key
        when Regexp
          md = path.match(key)
          return value % md.to_a[1..-1] if md
        when Proc
          new_path = value.call(path, Current.request)
          return new_path if new_path
        when String
          return value if key == path
        else
          Log.error("Invalid route %p => %p" % [key, value])
        end
      end

      nil
    end
  end

  def self.Route(key, value = nil, &block)
    Route[key] = value || block
  end
end
