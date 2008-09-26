module Rack
  module Handler
    autoload :Thin,               'rack/handler/thin'
    autoload :Ebb,                'ebb'
    autoload :SwiftipliedMongrel, 'rack/handler/swiftiplied_mongrel'

    register 'thin',     'Rack::Handler::Thin'
    register 'ebb',      'Rack::Handler::Ebb'
    register 'smongrel', 'Rack::Handler::SwiftipliedMongrel'
  end
end

module Innate
  module Adapter
    class << self

      def start(app, config)
        name = config.adapter.to_s.downcase
        options = { :Host => config.host, :Port => config.port }
        puts "Innate uses #{name}"

        if respond_to?(method = "start_#{name}")
          send(method, app, options)
        else
          Rack::Handler.get(name).run(app, options)
        end
      end

      # Due to buggy autoload on Ruby 1.8 we have to require 'ebb' manually.
      # This most likely happens because autoload doesn't respect the require
      # of rubygems and uses the C require directly.
      def start_ebb(app, options)
        require 'ebb'
        Rack::Handler.get('ebb').run(app, options)
      end

      def start_webrick(app, options)
        handler = Rack::Handler.get('webrick')
        options = {
          :BindAddress => options[:Host],
          :Port => options[:Port],
          :Logger => Log,
          :AccessLog => [
            [Log, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
            [Log, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]]
        }

        handler.run(app, options)
      end

      def start_thin(app, options)
        require 'thin'
        handler = Rack::Handler.get('thin')
        ::Thin::Logging.silent = true
        handler.run(app, options)
      end

      def start_emongrel(app, options)
        require 'swiftcore/swiftiplied_mongrel'
        handler = Rack::Handler.get('mongrel')
        handler.run(app, options)
      end
    end
  end
end
