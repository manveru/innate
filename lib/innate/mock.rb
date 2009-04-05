module Innate
  module Mock
    HTTP_METHODS = %w[ CONNECT DELETE GET HEAD OPTIONS POST PUT TRACE ]
    OPTIONS = {:app => Innate}

    HTTP_METHODS.each do |method|
      (class << self; self; end).
        send(:define_method, method.downcase){|*args|
        mock(method, *args)
      }
    end

    def self.mock(method, *args)
      mock_request.request(method, *args)
    end

    def self.mock_request(app = OPTIONS[:app])
      Rack::MockRequest.new(app)
    end

    def self.session
      yield Session.new
    end

    class Session
      attr_accessor :cookie

      def initialize
        @cookie = nil
      end

      HTTP_METHODS.each do |method|
        define_method(method.downcase){|*args|
          extract_cookie(method, *args)
        }
      end

      def extract_cookie(method, path, hash = {})
        hash['HTTP_COOKIE'] ||= @cookie if @cookie
        response = Mock::mock(method, path, hash)

        cookie = response['Set-Cookie']
        @cookie = cookie if cookie

        response
      end
    end
  end
end
