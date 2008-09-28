module Rack
  class MiddlewareCompiler
    COMPILED = {}

    def self.build(name, &block)
      COMPILED[name] ||= new(name, &block)
    end

    def self.build!(name, &block)
      COMPILED[name] = new(name, &block)
    end

    attr_reader :middlewares, :name

    def initialize(name)
      @name = name
      @middlewares = []
      @compiled = nil
      yield(self) if block_given?
    end

    # FIXME: Should we use `|` or `+`?
    def use(*mws)
      @middlewares = mws | @middlewares
    end

    def run(app)
      @app = app
    end

    def cascade(*apps)
      @app = Rack::Cascade.new(apps)
    end

    def call(env)
      compile
      @compiled.call(env)
    end

    def compiled?
      @compiled
    end

    def compile
      return self if compiled?
      @compiled = @middlewares.inject(@app){|a,e| e.new(a) }
      self
    end
  end
end
