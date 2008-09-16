module Rack
  class MiddlewareCompiler
    CACHE = {}

    def self.build(name, &block)
      CACHE[name] ||= new(name, &block)
    end

    def self.build!(name, &block)
      CACHE[name] = new(name, &block)
    end

    def initialize(name)
      @name = name
      @mw = []
      @compiled = nil
      yield(self) if block_given?
    end

    def use(mw)
      @mw.unshift(mw)
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
      !! @compiled
    end

    def compile
      return self if compiled?
      @compiled = @mw.inject(@app){|a,e| e.new(a) }
      self
    end
  end
end
