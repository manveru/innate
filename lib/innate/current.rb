module Innate
  class Current
    extend Trinity

    def initialize(app)
      @app = app
    end

    def call(env)
      STATE.wrap do
        setup(env)
        @app.call(env)
      end
    end

    def setup(env)
      req = STATE[:request] = Rack::Request.new(env)
      res = STATE[:response] = Rack::Response.new
      STATE[:session] = Session.new(req, res)
    end
  end
end
