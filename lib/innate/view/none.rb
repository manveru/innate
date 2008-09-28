module Innate
  module View
    module None
      module_function

      def render(action, string = nil)
        string || action.view
      end
    end
  end
end
