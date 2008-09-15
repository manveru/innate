require 'innate/adapter/thin'

module Innate
  module Adapter
    def self.start
      conf = Innate.conf
      handler = Rack::Handler.get(conf.adapter)
      handler.run(Innate, :Host => conf.host, :Port => conf.port)
    end
  end
end

module Rack::Handler
  autoload :Thin, 'rack/handler/thin'
  autoload :Ebb, 'ebb'
  autoload :SwiftipliedMongrel, 'rack/handler/swiftiplied_mongrel'

  register 'thin', 'Rack::Handler::Thin'
  register 'ebb', 'Rack::Handler::Ebb'
  register 'smongrel', 'Rack::Handler::SwiftipliedMongrel'
end
