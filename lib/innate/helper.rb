module Innate

  # Acts as name-space for helpers
  module Helper
    # Public instance methods of helpers in here will be recognized as actions
    LOOKUP = EXPOSE = Set.new

    # Usually called from Innate::Node::included
    # We also include Innate::Trinity here, as it may be needed in models when
    # you use helper methods there.
    def self.included(into)
      into.extend(HelperAccess)
      into.__send__(:include, Trinity)
    end
  end

  # Provides access to #helper method without polluting the name-space any
  # further.
  module HelperAccess

    # Convenience method used by Innate::Node.
    #
    # Usage:
    #
    #   class Hi
    #     extend Innate::HelperAccess
    #     helper :cgi, :link, :aspect
    #   end
    #
    # This will require the helpers and call:
    #
    #     Hi.include(Innate::Helper::CGI)
    #     Hi.include(Innate::Helper::Link)
    #     Hi.include(Innate::Helper::Aspect)
    def helper(*helpers)
      HelpersHelper.each_include(self, *helpers)
    end
  end

  # Here come the utility methods used from the HelperAccess#helper method, we
  # do this to keep method count at a minimum and because HelpersHelper is such
  # an awesome name that just can't be wasted.
  #
  # Usage if you want to only extend with helpers:
  #
  #   class Hi
  #     Innate::HelpersHelper.each_extend(self, :cgi, :link, :aspect)
  #   end
  #
  # Usage if you only want to include helpers:
  #
  #   class Hi
  #     Innate::HelpersHelper.each_include(self, :cgi, :link, :aspect)
  #   end
  #
  # Usage for iteration:
  #
  #   Innate::HelpersHelper.each(:cgi, :link, :aspect) do |mod|
  #     p mod
  #   end
  #
  # Usage for translating helpers to modules:
  #
  #   p Innate::HelpersHelper.each(:cgi, :link, :aspect)
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
    #
    # NOTE: Unlike usual #each, this will actually return an Array of the found
    #       modules instead of the given +*names+
    #
    #
    # Usage:
    #
    #   Innate::HelpersHelper.each(:cgi, :link, :aspect) do |mod|
    #     p mod
    #   end

    def each(*names)
      names.map do |name|
        if name.class == Module
          yield(name) if block_given?
          name
        elsif mod = get(name)
          yield(mod) if block_given?
          mod
        elsif try_require(name)
          redo
        else
          raise LoadError, "Helper #{name} not found"
        end
      end
    end

    # Shortcut to extend +into+ with Helper modules corresponding to +*names+.
    # +into+ has to respond to #extend.
    #
    # Usage:
    #
    #   class Hi
    #     Innate::HelpersHelper.each_extend(self, :cgi, :link, :aspect)
    #   end
    def each_extend(into, *names, &block)
      return if names.empty?
      into.extend(*each(*names, &block))
    end

    # Shortcut to include Helper modules corresponding to +*names+ on +into+.
    # +into+ has to respond to #include.
    # #__send__(:include) is used in case #include raises due to being
    # private/protected
    #
    # in case #include is a private/protected method.
    #
    # Usage:
    #
    #   class Hi
    #     Innate::HelpersHelper.each_include(self, :cgi, :link, :aspect)
    #   end
    def each_include(into, *names, &block)
      return if names.compact.empty?
      into.__send__(:include, *each(*names, &block))
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
        found = namespace.constants.grep(/^#{name}$/i).first
        return namespace.const_get(found) if found
      end

      nil
    end

    # Figure out files that might have the helper we ask for and then require
    # the first we find, if any.
    def try_require(name)
      if found = Dir[glob(name)].first
        require(found) || true
      else
        raise(LoadError, "Helper #{name} not found")
      end
    end

    # Return a nice list of filenames in correct locations with correct
    # filename-extensions.
    def glob(name = '*')
      "{#{paths.join(',')}}/helper/#{name}.{#{EXTS.join(',')}}"
    end

    # In case you want to do something better.
    def paths
      PATH
    end
  end
end
