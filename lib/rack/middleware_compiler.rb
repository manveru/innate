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
      @name = name.to_sym
      @middlewares = []
      @compiled = nil
      yield(self) if block_given?
    end

    def use(app, *args, &block)
      @middlewares << [app, args, block]
    end

    def apps(*middlewares)
      @middlewares.concat(middlewares.map{|mw| [mw, [], nil]})
    end

    def run(app)
      @app = app
    end

    def cascade(*apps)
      @app = Rack::Cascade.new(apps)
    end

    # Default application for Innate
    def innate
      public_root = ::File.join(Innate.options.app.root.to_s,
                                Innate.options.app.public.to_s)
      cascade(Rack::File.new(public_root),
              Innate::Current.new(Innate::Route.new, Innate::Rewrite.new))
    end

    def static(path)
      require 'rack/contrib'
      Rack::ETag.new(Rack::ConditionalGet.new(Rack::File.new(path)))
    end

    def directory(path)
      require 'rack/contrib'
      Rack::ETag.new(Rack::ConditionalGet.new(Rack::Directory.new(path)))
    end

    def call(env)
      compile
      @compiled.call(env)
    end

    def compiled?
      @compiled
    end

    def compile
      compiled? ? self : compile!
    end

    def compile!
      @compiled = @middlewares.inject(@app){|s, (app, args, block)|
        app.new(s, *args, &block) }
      self
    end
  end
end
