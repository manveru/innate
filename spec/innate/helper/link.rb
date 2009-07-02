require File.expand_path('../../../helper', __FILE__)

class One
  include Innate::Node
  map '/'

  def auto_route
    UsingRouteSelf.new.route.to_s
  end
end

class Two
  include Innate::Node
  map '/two'

  def auto_route
    UsingRouteSelf.new.route.to_s
  end
end

class UsingRouteSelf
  include Innate::Helper::Link

  attr_reader :route

  def initialize
    @route = route_self(:elsewhere)
  end
end

describe Innate::Helper::Link do
  describe '#route' do
    should 'respond with URI for node' do
      One.route.should == URI('/')
      Two.route.should == URI('/two/')
    end

    should 'respond with URI for node with path /' do
      One.route('/').should == URI('/')
      Two.route('/').should == URI('/two/')
    end

    should 'respond with URI for node with path /foo' do
      One.route('/foo').should == URI('/foo')
      One.route(:foo).should == URI('/foo')

      Two.route('/foo').should == URI('/two/foo')
      Two.route(:foo).should == URI('/two/foo')
    end

    should 'respond with URI for node with path /foo/bar' do
      One.route('/foo/bar').should == URI('/foo/bar')
      One.route(:foo, :bar).should == URI('/foo/bar')

      Two.route('/foo/bar').should == URI('/two/foo/bar')
      Two.route(:foo, :bar).should == URI('/two/foo/bar')
    end

    should 'respond with URI for node with path /foo/bar+baz' do
      One.route('/foo/bar+baz').should == URI('/foo/bar+baz')
      One.route(:foo, 'bar baz').should == URI('/foo/bar+baz')

      Two.route('/foo/bar+baz').should == URI('/two/foo/bar+baz')
      Two.route(:foo, 'bar baz').should == URI('/two/foo/bar+baz')
    end

    should 'respond with URI for node with GET params' do
      One.route('/', :a => :b).should == URI('/?a=b')

      One.route('/foo', :a => :b).should == URI('/foo?a=b')
      One.route(:foo, :a => :b  ).should == URI('/foo?a=b')

      One.route('/foo/bar', :a => :b).should == URI('/foo/bar?a=b')
      One.route(:foo, :bar, :a => :b).should == URI('/foo/bar?a=b')

      Two.route('/', :a => :b).should == URI('/two/?a=b')

      Two.route('foo', :a => :b).should == URI('/two/foo?a=b')
      Two.route(:foo, :a => :b ).should == URI('/two/foo?a=b')
      Two.route('/foo/bar', :a => :b).should == URI('/two/foo/bar?a=b')
      Two.route(:foo, :bar, :a => :b).should == URI('/two/foo/bar?a=b')
    end

    should 'prefix the links as defined in the options' do
      Innate.options.prefix = '/bar'
      One.route('/foo').should == URI('/bar/foo')
      Innate.options.prefix = '/'
    end
  end

  describe '#anchor' do
    should 'respond with a tag with default text' do
      One.anchor('hello').should == '<a href="/hello">hello</a>'
      Two.anchor('hello').should == '<a href="/two/hello">hello</a>'
    end

    should 'respond with a tag with explicit text' do
      One.anchor('hello', :foo).should == '<a href="/foo">hello</a>'
      Two.anchor('hello', :foo).should == '<a href="/two/foo">hello</a>'
    end

    should 'pass parameters to #route' do
      One.anchor('hello', :foo, :a => :b).
        should == '<a href="/foo?a=b">hello</a>'
      Two.anchor('hello', :foo, :a => :b).
        should == '<a href="/two/foo?a=b">hello</a>'
    end

    should 'escape text' do
      One.anchor('<blink> & <a>', :foo).
        should == '<a href="/foo">&lt;blink&gt; &amp; &lt;a&gt;</a>'
    end
  end

  describe 'combining #anchor and #route' do
    should 'not escape twice' do
      One.anchor('foo', One.route(:index, :bar => 'a/b/c')).
        should == '<a href="/index?bar=a%2Fb%2Fc">foo</a>'
    end

    should 'handle complete uris gracefully' do
      One.anchor('foo', 'http://example.com/?foo=bar&baz=qux').
        should == '<a href="http://example.com/?foo=bar&amp;baz=qux">foo</a>'
    end

    should 'be able to route from one node to another' do
      Two.anchor('foo', One.route(:index)).should == '<a href="/index">foo</a>'
      One.anchor('foo', Two.route(:index)).should == '<a href="/two/index">foo</a>'
    end
  end

  describe '#route_self' do
    behaves_like :rack_test
    should 'provide a route to the node of the currently active action' do
      get('/auto_route').body.should == '/elsewhere'
      get('/two/auto_route').body.should == '/two/elsewhere'
    end
  end
end
