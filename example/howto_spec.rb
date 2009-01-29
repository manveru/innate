require 'innate'
require 'bacon'

class SpecMe
  include Innate::Node
  map '/'

  def index
    "I should be at /"
  end

  def foo
    action.content_type = 'text/css'
    "I should be at /foo"
  end
end

class SpecMeToo
  include Innate::Node
  map '/too'

  def index
    "I should be at /too"
  end

  def foo
    action.content_type = 'text/css'
    "I should be at /too/foo"
  end
end

Innate.setup_middleware

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

describe 'An example spec' do
  def assert(url, body, content_type)
    response = Innate::Mock.get(url)
    response.status.should == 200
    response.body.should == body
    response.content_type.should == content_type
  end

  should 'respond to /' do
    assert('/', "I should be at /", 'text/html')
  end

  should 'respond to /foo' do
    assert('/foo', "I should be at /foo", 'text/css')
  end

  should 'respond to /too' do
    assert('/too', "I should be at /too", 'text/html')
  end

  should 'respond to /too/foo' do
    assert('/too/foo', "I should be at /too/foo", 'text/css')
  end
end
