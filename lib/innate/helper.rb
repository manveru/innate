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
      into.helper(*HelpersHelper.options[:default])
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
    include Optioned

    options.dsl do
      o "Paths that will be searched for helper files",
        :paths, [Dir.pwd, File.dirname(__FILE__)]

      o "Namespaces that will be searched for helper modules",
        :namespaces, [Helper]

      o "Filename extensions considered for helper files",
        :exts, %w[rb so bundle]

      o "Default helpers, added on inclusion of the Helper module",
        :default, [:aspect, :cgi, :flash, :link, :render, :redirect, :send_file]
    end

    EXTS = %w[rb so bundle]

    # all of the following are singleton methods

    module_function

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
      module_name = /^#{name.to_s.dup.delete('_')}$/i

      options.namespaces.each do |namespace|
        found = namespace.constants.grep(module_name).first
        return namespace.const_get(found) if found
      end

      nil
    end

    # Figure out files that might have the helper we ask for and then require
    # the first we find, if any.
    def try_require(name)
      if found = find_helper(name.to_s)
        require(found) || true
      else
        raise(LoadError, "Helper #{name} not found")
      end
    end

    def find_helper(name)
      options.paths.uniq.find do |path|
        base = ::File.join(path, 'helper', name)
        options.exts.find do |ext|
          full = "#{base}.#{ext}"
          return full if ::File.file?(full)
        end
      end
    end
  end
end
