module Rack
  class RouteExceptions
    ROUTES = [
      [Exception, '/error_500']
    ]

    ROUTE_EXCEPTIONS_PATH_INFO = 'rack.route_exceptions.path_info'.freeze
    ROUTE_EXCEPTIONS_EXCEPTION = 'rack.route_exceptions.exception'.freeze
    ROUTE_EXCEPTIONS_RESPONSE = 'rack.route_exceptions.response'.freeze

    def initialize(app)
      @app = app
    end

    def call(env, try_again = true)
      status, header, body = response = @app.call(env)
    rescue Exception => exception
      raise(exception) unless try_again

      ROUTES.each do |klass, to|
        next unless exception === klass
        return route(to, env, response, exception)
      end
    end

    def route(to, env, response, exception)
      hash = {
        ROUTE_EXCEPTIONS_PATH_INFO => env['PATH_INFO'],
        ROUTE_EXCEPTIONS_EXCEPTION => exception,
        ROUTE_EXCEPTIONS_RESPONSE => response
      }
      env.merge!(hash)

      env['PATH_INFO'] = to

      call(env, try_again = false)
    end
  end
end
