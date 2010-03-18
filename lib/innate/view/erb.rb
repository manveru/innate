require 'erb'

module Innate
  module View
    module ERB
      def self.call(action, string)
        erb = View.compile(string){|str| ::ERB.new(str, nil, '%<>') }
        erb.filename = (action.view || action.method).to_s
        html = erb.result(action.binding)
        return html, Response.mime_type
      end
    end
  end
end
