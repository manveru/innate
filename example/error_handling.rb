require 'innate'

class Flawed
  include Innate::Node
  map '/'

  def index
    raise ArgumentError, "No go"
  end

  def i_raise
    100 * "foo"
  end
end

class Errors
  include Innate::Node
  map '/error'

  def internal
    path = request.env['rack.route_exceptions.path_info']
    exception = request.env['rack.route_exceptions.exception']

    format = "Oh my, you just went to %p, something went horribly wrong: %p"
    format % [path, exception.message]
  end
end

Rack::RouteExceptions.route(Exception, '/error/internal')

Innate.start
