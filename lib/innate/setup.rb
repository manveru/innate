module Innate
  def self.setup(&block)
    Setup.new(&block)
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
