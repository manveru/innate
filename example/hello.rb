require 'innate'

class Hello
  include Innate::Node
  map '/'

  def index
    'Hello, World!'
  end
end

Innate.start
