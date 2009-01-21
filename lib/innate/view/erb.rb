require 'erb'

module Innate
  module View
    module ERB
      def self.render(action, string = action.view)
        action.variables.each do |iv, value|
          action.instance.instance_variable_set("@#{iv}", value)
        end

        erb = ::ERB.new(string, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        erb.result(action.binding)
      end
    end
  end
end
