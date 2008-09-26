module Innate
  # Acts as namespace for helpers
  module Helper
    DEFAULT = Set.new
    LOOKUP = EXPOSE = Set.new

    def self.included(into)
      into.extend(HelperAccess)
      into.__send__(:include, Trinity)
      into.helper(*DEFAULT)
    end
  end

  # Provides access to ::helper and ::class_helper methods
  module HelperAccess
    public

#     helper :cgi, :link, :aspect
#     helper :both => :link
#     helper :extend => :link
#     helper :cgi, :both => :link
#     helper :both => [:link, :redirect]

    def helper(*args)
      opts = {:include => [], :extend => [], :both => []}

      args.each do |arg|
        if arg.respond_to?(:each_pair)
          arg.each_pair{|k,v| opts[k] << v }
        else
          opts[:include] << arg
        end
      end

      opts.each do |meth, values|
        values = values.flatten
        next if values.empty?

        case meth
        when :include, :extend
          HelpersHelper.each(*values){|mod| __send__(meth, mod) }
        when :both
          HelpersHelper.each(*values){|mod| include(mod); extend(mod) }
        end
      end
    end
  end

  module HelpersHelper
    EXTS = %w[rb so bundle]
    PATH = [ File.dirname(__FILE__) ]

    module_function

    def each(*names)
      names.each do |name|
        if name.class == Module
          yield(name)
        elsif mod = get(name)
          yield(mod)
        elsif try_require(name)
          redo
        else
          raise LoadError, "Helper #{name} not found"
        end
      end
    end

    def get(name)
      name = name.to_s.split('_').map{|e| e.capitalize}.join
      if found = Helper.constants.grep(/^#{name}$/i).first
        Helper.const_get(found)
      end
    end

    def try_require(name)
      if found = Dir[glob(name)].first
        require File.expand_path(found)
      else
        raise LoadError, "Helper #{name} not found"
      end
    end

    def glob(name = '*')
      "{#{paths * ','}}/helper/#{name}.{#{EXTS * ','}}"
    end

    def paths
      PATH
    end
  end
end

# Require default helpers as far as we can find them
Dir[Innate::HelpersHelper.glob].each do |file|
  require file if File.read(file) =~ /^\s*DEFAULT/
end
