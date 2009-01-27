require 'erb'

module Innate
  module View
    module ERB
      def self.render(action, string = action.view)
        return unless string.respond_to?(:to_str)

        if action.variables.any?
          action.binding.eval('
            action = Innate::Current.actions.last
            action.variables.each do |iv, value|
              instance_variable_set("@#{iv}", value)
            end')
        end

        erb = ::ERB.new(string.to_str, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        erb.result(action.binding)
      end
    end
  end
end
