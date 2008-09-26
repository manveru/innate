require 'haml/engine'

module Innate
  class View
    class Haml
      def self.render(action, string = nil)
        string ||= action.view
        haml = ::Haml::Engine.new(string, action.options)
        haml.to_html(action.instance, action.variables)
      end
    end
  end
end
