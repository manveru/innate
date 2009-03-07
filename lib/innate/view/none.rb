module Innate
  module View
    module None
      def self.call(action, string)
        return string, 'text/html'
      end
    end
  end
end
