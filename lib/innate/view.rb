module Innate
  class View
    ENGINE = {}

    def self.get(engine)
      return unless engine
      engine = engine.to_s

      if klass = ENGINE[engine]
        obj = Object
        klass.split('::').each{|e| obj = obj.const_get(e) }
        return obj
      else
        View::const_get(engine.capitalize)
      end
    end

    def self.register(engine, klass)
      ENGINE[engine] = klass
    end

    autoload :Haml, 'innate/view/haml'
    autoload :None, 'innate/view/none'
    autoload :Sass, 'innate/view/sass'

    register 'css',  'Innate::View::None'
    register 'haml', 'Innate::View::Haml'
    register 'html', 'Innate::View::None'
    register 'sass', 'Innate::View::Sass'
  end
end
