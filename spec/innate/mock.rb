require File.expand_path('../../helper', __FILE__)

class SpecMock
  include Innate::Node
  map '/'

  def index
    ''
  end
end

class SpecMock2
  include Innate::Node
  map '/deep'

  def index
    'spec mock 2'
  end

  def foo
    'spec mock 2 foo'
  end
end

describe 'Innate::SpeckMock2' do
  should 'handle get request' do
    response = Innate::Mock.get('/deep/foo')
    # '/foo/bar'
    response.status.should == 200
    response.body.should == 'spec mock 2 foo'
  end
end

describe 'Innate::SpecMock' do
  should 'handle get request' do
    response = Innate::Mock.get('/')
    # '/one'
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle post request' do
    response = Innate::Mock.post('/')
    # '/'
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle head request' do
    response = Innate::Mock.head('/')
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle delete request' do
    response = Innate::Mock.delete('/')
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle put request' do
    response = Innate::Mock.put('/')
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle options request' do
    response = Innate::Mock.options('/')
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle connect request' do
    response = Innate::Mock.connect('/')
    response.status.should == 200
    response.body.should == ''
  end

  should 'handle trace request' do
    response = Innate::Mock.trace('/')
    response.status.should == 200
    response.body.should == ''
  end
end
