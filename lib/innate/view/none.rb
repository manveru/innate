module Innate
  module View
    module None
      def self.call(action, string)
        ['text/plain', string]
      end
    end
  end
end
