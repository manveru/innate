module Innate

  # Acts as name-space for helpers

  module Helper
    DEFAULT = Set.new
    LOOKUP = EXPOSE = Set.new

    # Usually called from Innate::Node::included
    # We also include Innate::Trinity here, as it may be needed in models when
    # you use helper methods there.

    def self.included(into)
      into.extend(HelperAccess)
      into.__send__(:include, Trinity)
      into.helper(*DEFAULT)
    end
  end

  # Provides access to #helper method
  #
  # Usage:
  #
  #   class Hi
  #     extend Innate::HelperAccess
  #     helper :cgi, :both => [:link, :aspect]
  #   end
  #
  # This will include the cgi helper into Hi, and include/extend Hi with the
  # link and aspect helpers
  #
  # NOTE:
  #   The API for the helper method isn't set in stone yet, I'm torn between
  #   making a single method that can handle both including and extending and
  #   separate methods.
  #   The current approach has some appeal, as it doesn't pollute the method
  #   names-pace further, but might be less intuitive to someone encountering
  #   one of the following:
  #
  #     helper :cgi, :link, :aspect
  #     helper :both => :link
  #     helper :extend => :link
  #     helper :cgi, :both => :link
  #     helper :both => [:link, :redirect]

  module HelperAccess

    # see comments above

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

  # Here come the utility methods used from the HelperAccess#helper method, we
  # do this to keep method count at a minimum and because HelpersHelper is such
  # an awesome name that just can't be wasted.

  module HelpersHelper
    EXTS = %w[rb so bundle]

    # By default, lib/innate/ is added to the PATH, you may add your
    # application root here so innate will look in your own helper/ directory.
    PATH = []

    # The namespaces that may container helper modules.
    # Lookup is done from left to right.
    POOL = []

    # all of the following are singleton methods

    module_function

    def add_pool(pool)
      POOL.unshift(pool)
      POOL.uniq!
    end

    add_pool(Helper)

    def add_path(path)
      PATH.unshift(File.expand_path(path))
      PATH.uniq!
    end

    add_path(File.dirname(__FILE__))
    add_path('')

    # Yield all the modules we can find for the given names of helpers, try to
    # require them if not available.

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

    # Based on a simple set of rules we will first construct the most likely
    # name for the helper and then grep the constants in the Innate::Helper
    # module for any matches.
    #
    # helper :foo_bar # => FooBar
    # helper :foo # => Foo

    def get(name)
      name = name.to_s.split('_').map{|e| e.capitalize}.join
      POOL.each do |namespace|
        if found = namespace.constants.grep(/^#{name}$/i).first
          return namespace.const_get(found)
        end
      end

      nil
    end

    # Figure out files that might have the helper we ask for and then require
    # the first we find, if any.

    def try_require(name)
      if found = Dir[glob(name)].first
        require File.expand_path(found)
      else
        raise LoadError, "Helper #{name} not found"
      end
    end

    # Return a nice list of filenames in correct locations with correct
    # filename-extensions.
    #
    # by the way: Array#* is an alias for Array#join

    def glob(name = '*')
      "{#{paths * ','}}/helper/#{name}.{#{EXTS * ','}}"
    end

    # In case you want to do something better.

    def paths
      PATH
    end
  end
end
