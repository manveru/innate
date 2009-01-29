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
      def start(app, options = Innate.options)
        adapter_name = options[:adapter].to_s.downcase
        config = { :Host => options[:host], :Port => options[:port] }
        Log.debug "Innate uses #{adapter_name}"

        if respond_to?(method = "start_#{adapter_name}")
          send(method, app, config)
        else
          Rack::Handler.get(adapter_name).run(app, config)
        end
      end

      # Due to buggy autoload on Ruby 1.8 we have to require 'ebb' manually.
      # This most likely happens because autoload doesn't respect the require
      # of rubygems and uses the C require directly.
      def start_ebb(app, config)
        require 'ebb'
        Rack::Handler.get('ebb').run(app, config)
      end

      # We want webrick to use our logger.

      def start_webrick(app, config)
        handler = Rack::Handler.get('webrick')
        config = {
          :BindAddress => config[:Host],
          :Port => config[:Port],
          :Logger => Log,
          :AccessLog => [
            [Log, ::WEBrick::AccessLog::COMMON_LOG_FORMAT],
            [Log, ::WEBrick::AccessLog::REFERER_LOG_FORMAT]]
        }

        handler.run(app, config)
      end

      # Thin shouldn't give excessive output, especially not to $stdout

      def start_thin(app, config)
        require 'thin'
        handler = Rack::Handler.get('thin')
        ::Thin::Logging.silent = true
        handler.run(app, config)
      end

      # swiftcore has its own handler outside of rack

      def start_emongrel(app, config)
        require 'swiftcore/evented_mongrel'
        handler = Rack::Handler.get('emongrel')
        handler.run(app, config)
      end

      # swiftcore has its own handler outside of rack

      def start_smongrel(app, config)
        require 'swiftcore/swiftiplied_mongrel'
        handler = Rack::Handler.get('smongrel')
        handler.run(app, config)
      end
    end
  end
end
