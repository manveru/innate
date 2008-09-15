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
      STATE[:request] = Rack::Request.new(env)
      STATE[:response] = Rack::Response.new
    end
  end
end
