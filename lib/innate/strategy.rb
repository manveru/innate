module Innate
  class Strategy
    def self.call(env)
    end

    module Dumb
      def self.call(env)
        p Point::TRACK
        Innate.response.write 'Hello, World!'
      end
    end

    module Ramaze
    end
  end
end
