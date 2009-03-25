module Innate

  # This is a container module for wrappers of templating engines and handles
  # lazy requiring of needed engines.

  module View
    ENGINE, TEMP = {}, {}

    module_function

    def exts_of(engine)
      name = engine.to_s
      ENGINE.reject{|k,v| v != name }.keys
    end

    # Try to obtain given engine by its registered name.
    def get(engine)
      if klass = TEMP[engine]
        return klass
      elsif klass = ENGINE[engine]
        TEMP[engine] = obtain(klass)
      else
        TEMP[engine] = obtain(engine, View)
      end
    end

    # We need to put this in a Mutex because simultanous calls for the same
    # class will cause race conditions and one call may return the wrong class
    # on the first request (before TEMP is set).
    # No mutex is used in Fiber environment, see Innate::State and subclasses.
    def obtain(klass, root = Object)
      STATE.sync do
        klass.to_s.scan(/\w+/){|part| root = root.const_get(part) }
        root
      end
    end

    # Register given templating engine wrapper and extensions for later usage.
    #
    # +name+ : the class name of the templating engine wrapper
    # +exts+ : any number of arguments will be turned into strings via #to_s
    #          that indicate which filename-extensions the templates may have.
    def register(klass, *exts)
      exts.each do |ext|
        ext = ext.to_s
        engine = ENGINE[ext]
        Log.warn("overwriting %p, was set to %p" % [ext, engine]) if engine
        ENGINE[ext] = klass
      end
    end

    autoload :None,   'innate/view/none'
    autoload :ERB,    'innate/view/erb'
    autoload :Etanni, 'innate/view/etanni'

    register 'Innate::View::None',   :css, :html, :htm
    register 'Innate::View::ERB',    :erb
    register 'Innate::View::Etanni', :xhtml
  end
end
