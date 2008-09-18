require 'set'
require 'rack'

module Innate
  module HelperManagment
    EXTS = %w[rb so bundle]

    module_function

    def helper(*names)
      names_to_helpers(*names) do |mod|
        include mod
      end
    end

    def class_helper(*names)
      names_to_helpers(*names) do |mod|
        extend mod
      end
    end

    def names_to_helpers(*names)
      names.each do |name|
        if mod = get(name)
          yield(mod)
        elsif require_helper(name)
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

    def require_helper(name)
      if found = Dir[helper_glob(name)].first
        require found
      else
        raise LoadError, "Helper #{name} not found"
      end
    end

    def helper_glob(name)
      glob = "{#{helper_paths * ','}}/helper/#{name}.{#{EXTS * ','}}"
    end

    def helper_paths
      [
        File.dirname(__FILE__),
      ]
    end
  end

  module Helper
    # This allows you to make the methods in your helper normal actions
    #
    # Usage:
    #
    #   module Innate
    #     module Helper
    #       module Smile
    #         EXPOSE << self
    #
    #         def smile
    #           ':)'
    #         end
    #       end
    #     end
    #   end
    #
    # Now /smile can be accessed on the Node this is included into.

    EXPOSE = Set.new

    # Ramaze compat
    LOOKUP = EXPOSE

    def self.included(into)
      into.extend(HelperManagment)
      into.__send__(:include, Trinity)
    end
  end
end
