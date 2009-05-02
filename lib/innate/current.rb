require 'innate/request'
require 'innate/response'

module Innate
  # We track the current request/response/session (Trinity) in Thread.current
  # so we can reach them from anywhere in the code without passing around the
  # objects directly.
  class Current
    extend Trinity

    def initialize(app, *rest)
      if rest.empty?
        @app = app
      else
        @app = Rack::Cascade.new([app, *rest])
      end
    end

    # Run setup and call the app
    def call(env)
      setup(env)
      @app.call(env)
    end

    # Setup new Request/Response/Session for this request/response cycle.
    # The parameters are here to allow Ramaze to inject its own classes.
    def setup(env, request = Request, response = Response, session = Session)
      current = Thread.current
      req = current[:request] = request.new(env)
      res = current[:response] = response.new
      current[:actions] = []
      current[:session] = Session.new(req, res)
    end
  end
end
