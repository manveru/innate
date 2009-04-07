require 'rubygems'
require 'innate'

class SpecMe
  Innate.node '/'

  def index
    "I should be at /"
  end

  def foo
    response['Content-Type'] = 'text/css'
    "I should be at /foo"
  end
end

require 'innate/spec'

describe 'An example spec' do
  behaves_like :mock

  should 'respond to /' do
    got = get('/')
    got.status.should == 200
    got.body.should == "I should be at /"
    got['Content-Type'].should == 'text/html'
  end

  should 'respond to /foo' do
    got = get('/foo')
    got.status.should == 200
    got.body.should == "I should be at /foo"
    got['Content-Type'].should == 'text/css'
  end
end
