module Innate
  module SingletonMethods
    # Shortcut for {Setup::new}
    # @param [Proc] block will be passed on to {Setup::new}
    def setup(&block)
      Setup.new(&block)
    end
  end

  class Setup
    def initialize(&block)
      instance_eval(&block) if block
    end

    def gem(*args)
      raise
    end

    def start(options = {})
      Innate.start(options)
    end

    def require(*libs)
      libs.flatten.each{|lib| Kernel::require(lib) }
    end
  end
end
