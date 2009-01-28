require 'erb'

module Innate
  module View
    module ERB
      def self.render(action, string = action.view)
        return unless string.respond_to?(:to_str)

        action.copy_variables

        erb = ::ERB.new(string.to_str, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        erb.result(action.binding)
      end
    end
  end
end
