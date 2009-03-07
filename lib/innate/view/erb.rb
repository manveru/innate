require 'erb'

module Innate
  module View
    module ERB
      def self.call(action, string)
        return unless string.respond_to?(:to_str)

        action.copy_variables

        erb = ::ERB.new(string.to_str, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        html = erb.result(action.binding)

        return html, 'text/html'
      end
    end
  end
end
