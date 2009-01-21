module Innate
  module View
    module None
      def self.render(action, string = nil)
        string || action.view
      end
    end
  end
end
