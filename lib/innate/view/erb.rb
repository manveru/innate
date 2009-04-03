require 'erb'

module Innate
  module View
    module ERB
      def self.call(action, string)
        erb = ::ERB.new(string.to_s, nil, '%<>')
        erb.filename = (action.view || action.method).to_s
        html = erb.result(action.binding)

        return html, 'text/html'
      end
    end
  end
end
