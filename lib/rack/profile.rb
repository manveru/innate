require 'ruby-prof'

module Rack
  class Profile
    def initialize(app)
      @app = app
    end

    def call(env)
      response = nil
      result = RubyProf.profile do
        response = @app.call(env)
      end

      printer = RubyProf::GraphHtmlPrinter.new(result)
      ::File.open('graph_result.html', 'w+') do |gr|
        printer.print(gr, :min_percent => 0.1)
      end

      return response
    end
  end
end
