module Innate

  # This is a container module for wrappers of templating engines and handles
  # lazy requiring of needed engines.

  module View
    ENGINE = {}
    TEMP = {}

    # Try to obtain given engine by its registered name.

    def self.get(engine)
      return unless engine
      engine = engine.to_s

      if klass = TEMP[engine]
        return klass
      elsif klass = ENGINE[engine]
        TEMP[engine] = obtain(klass)
      else
        TEMP[engine] = View::const_get(engine.capitalize)
      end
    end

    # We need to put this in a Mutex because simultanous calls for the same
    # class will cause race conditions and one call may return the wrong class
    # on the first request (before TEMP is set).
    # No mutex is used in Fiber environment, see Innate::State and subclasses.

    def self.obtain(klass)
      STATE.sync do
        obj = Object
        klass.split('::').each{|e| obj = obj.const_get(e) }
        obj
      end
    end

    # Register given templating engine wrapper and extensions for later usage.
    #
    # +name+ : the class name of the templating engine wrapper
    # +exts+ : any number of arguments will be turned into strings via #to_s
    #          that indicate which filename-extensions the templates may have.

    def self.register(klass, *exts)
      exts.each do |ext|
        ext = ext.to_s
        if k = ENGINE[ext]
          warn "#{ext} is assigned to #{k} already"
        else
          ENGINE[ext] = klass
        end
      end
    end

    # Combine Kernel#autoload and Innate::View::register

    def self.auto_register(name, *exts)
      autoload(name, "innate/view/#{name}".downcase)
      register("Innate::View::#{name}", *exts)
    end

    auto_register :None, :css
    auto_register :None, :html

    auto_register :Builder, :builder
    auto_register :Haml,    :haml
    auto_register :Sass,    :sass
    auto_register :Tenjin,  :rbhtml
    auto_register :Nagoro,  :xhtml
    auto_register :ERB,     :erb
  end
end
