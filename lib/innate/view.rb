module Innate
  module View
    ENGINE = {}
    TEMP = {}

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
  end
end
