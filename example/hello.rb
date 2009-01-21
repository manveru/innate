require 'innate'

class Hello
  include Innate::Node

  def index
    'Hello, World!'
  end
end

Innate.start
