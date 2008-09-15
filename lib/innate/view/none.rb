module Innate
  class View
    class None
      def self.render(action, string = nil)
        string || action.view
      end
    end
  end
end
