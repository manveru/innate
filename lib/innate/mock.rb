module Innate
  module Mock
    def self.mock(method, *args)
      mock = Rack::MockRequest.new(Rack::Lint.new(Innate))
      mock.request(method, *args)
    end

    HTTP_METHODS = %w[ CONNECT DELETE GET HEAD OPTIONS POST PUT TRACE ]

    HTTP_METHODS.each do |method|
      (class << self; self; end).
        send(:define_method, method.downcase){|*args|
        mock(method, *args)
      }
    end
  end
end
