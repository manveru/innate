require 'erb'

module Innate
  module View
    module ERB
      module_function

      def render(action, string = action.view)
        binding = action.instance.__send__(:binding)
        action.variables.each do |iv, value|
          action.instance.instance_variable_set("@#{iv}", value)
        end
        ::ERB.new(string).result(binding)
      end
    end
  end
end
