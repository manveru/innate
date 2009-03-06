require 'erb'

module Innate
  module View
    module ERB
      def self.call(action, string)
        ['text/html', render(action, string)]
      end

      def self.render(action, string)
        return unless string.respond_to?(:to_str)

        action.copy_variables

        erb = ::ERB.new(string.to_str, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        erb.result(action.binding)
      end
    end
  end
end
