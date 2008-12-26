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

  # Lightweight wrapper around Rack::Handler, will apply our options in a
  # unified manner and deal with adapters that don't like to do what we want or
  # where Rack doesn't want to take a stand.

  module Adapter
    class << self

      # Pass given app to the Handler, handler is chosen based on
      # config.adapter option.
      # If there is a method named start_name_of_adapter it will be run instead
      # of the default run method of the handler, this makes it easy to define
      # custom startup of handlers for your server of choice
      def start(app, config)
        name = config.adapter.to_s.downcase
        options = { :Host => config.host, :Port => config.port }
        Log.debug "Innate uses #{name}"

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

      # We want webrick to use our logger.

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

      # Thin shouldn't give excessive output, especially not to $stdout

      def start_thin(app, options)
        require 'thin'
        handler = Rack::Handler.get('thin')
        ::Thin::Logging.silent = true
        handler.run(app, options)
      end

      # swiftcore has its own handler outside of rack

      def start_emongrel(app, options)
        require 'swiftcore/evented_mongrel'
        handler = Rack::Handler.get('emongrel')
        handler.run(app, options)
      end

      # swiftcore has its own handler outside of rack

      def start_smongrel(app, options)
        require 'swiftcore/swiftiplied_mongrel'
        handler = Rack::Handler.get('smongrel')
        handler.run(app, options)
      end
    end
  end
end
