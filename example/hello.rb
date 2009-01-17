require 'innate'

class Hello
  include Innate::Node

  def index
    'Hello, World!'
  end
end

class Foo
  include Innate::Node

  def bar
    "Hello, Bar"
  end
end

Innate.start
