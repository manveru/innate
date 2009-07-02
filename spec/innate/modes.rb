require File.expand_path('../../helper', __FILE__)

class SpecModeDummy
  Innate.node '/'

  def index
    'Hello, World!'
  end

  def random
    rand.to_s
  end
end

describe 'Innate modes' do
  describe 'dev' do
    behaves_like :rack_test
    Innate.options.mode = :dev

    should 'handle GET request' do
      get('/').status.
        should == 200
      last_response.headers.
        should == {'Content-Length' => '13', 'Content-Type' => 'text/html'}
      last_response.body.
        should == 'Hello, World!'
    end

    should 'handle HEAD requests by omitting body' do
      head('/').status.
        should == 200
      last_response.headers.
        should == {'Content-Length' => '13', 'Content-Type' => 'text/html'}
      last_response.body.
        should == ''
    end
  end

  describe 'live' do
    behaves_like :rack_test
    Innate.options.mode = :live

    should 'handle GET request' do
      get('/').status.
        should == 200
      last_response.headers.
        should == {'Content-Length' => '13', 'Content-Type' => 'text/html'}
      last_response.body.
        should == 'Hello, World!'
    end

    should 'handle HEAD requests by omitting body' do
      head('/').status.
        should == 200
      last_response.headers.
        should == {'Content-Length' => '13', 'Content-Type' => 'text/html'}
      last_response.body.
        should == ''
    end
  end
end
