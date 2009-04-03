module Innate
  module View
    module None
      def self.call(action, string)
        return string.to_s, 'text/html'
      end
    end
  end
end
