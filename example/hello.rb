require 'lib/innate'

class Hello
  include Innate::Node
  map '/'

  def index
    'Hello, World from index!'
  end

  def foo
    'Hi from foo'
  end
end

Innate.start
