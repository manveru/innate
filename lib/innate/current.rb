require 'innate/request'
require 'innate/response'

module Innate
  # Uses STATE to scope request/response/session per Fiber/Thread so we can
  # reach them from anywhere in the code without passing around the objects
  # directly.
  class Current
    extend Trinity

    def initialize(app, *rest)
      if rest.empty?
        @app = app
      else
        @app = Rack::Cascade.new([app, *rest])
      end
    end

    # Wrap into STATE, run setup and call the app inside STATE.

    def call(env)
      STATE.wrap do
        setup(env)
        @app.call(env)
      end
    end

    # Setup new Request/Response/Session for this request/response cycle

    def setup(env)
      req = STATE[:request] = Request.new(env)
      res = STATE[:response] = Response.new
      STATE[:actions] = []
      STATE[:session] = Session.new(req, res)
    end
  end
end
