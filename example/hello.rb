require 'innate'

class Hello
  Innate.node '/'

  def index
    'Hello, World!'
  end
end

Innate.start
