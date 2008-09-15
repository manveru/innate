require 'thin'
require 'rack/handler/thin'

module Innate
  module Adapter
    class Thin
      def self.start(host, port)
        server = ::Thin::Server.new(host, port, Innate)
        server.timeout = 3
        server.start
      end
    end
  end
end
