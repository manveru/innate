require 'spec/helper'

class SpecNode
  include Innate::Node

  def foo; end
  def bar; end
  def one(arg) end
  def two(arg1, arg2) end
  def more(*args) end
  def default(arg = nil) end
end

class SpecNodeProvide
  include Innate::Node
  map '/provide'
  provide :css => :none
  provide :sass => :sass

  def foo
    'body{ color: #f00; }'
  end

  def bar
'body
  :color #f00'
  end
end

class SpecNodeProvideTemplate
  include Innate::Node
  map '/provide_template'

  provide :css => :none
  provide :sass => :sass

  view_root File.expand_path(File.join(File.dirname(__FILE__), 'node'))
end

describe 'Innate::Node' do
  def get(*args)
    Innate::Mock.get(*args)
  end

  def action(method, params)
    Innate::Action.create(
      :node => SpecNode, :method => method, :params => params, :exts => []
    )
  end

  def compare(url, hash)
    result = SpecNode.resolve(url)
    hash.each do |key, value|
      result[key.to_s].should == value
    end
  end

  should 'resolve actions with methods' do
    SpecNode.resolve('/').should.be.nil
    SpecNode.resolve('/index').should.be.nil

    compare '/foo', :method => 'foo', :params => []
    SpecNode.resolve('/foo/one/two').should.be.nil

    compare '/bar', :method => 'bar', :params => []
    SpecNode.resolve('/bar/one').should.be.nil

    SpecNode.resolve('/one').should.be.nil
    compare '/one/1', :method => 'one', :params => ['1']
    SpecNode.resolve('/one/1/2').should.be.nil
    SpecNode.resolve('/one/1/2/3').should.be.nil

    SpecNode.resolve('/two').should.be.nil
    SpecNode.resolve('/two/1').should.be.nil
    compare '/two/1/2', :method => 'two', :params => %w[1 2]
    SpecNode.resolve('/two/1/2/3').should.be.nil

    compare '/more', :method => 'more', :params => []
    compare '/more/1', :method => 'more', :params => %w[1]
    compare '/more/1/2', :method => 'more', :params => %w[1 2]
    compare '/more/1/2/3', :method => 'more', :params => %w[1 2 3]

    compare '/default', :method => 'default', :params => []
    compare '/default/1', :method => 'default', :params => %w[1]

    # NOTE: these are actually bound to fail when called, but we cannot
    #       introspect enough to anticipate this failure
    compare '/default/1/2', :method => 'default', :params => %w[1 2]
    compare '/default/1/2/3', :method => 'default', :params => %w[1 2 3]
  end

  should 'resolve actions, and return correct content-type on provides' do
    got = get('/provide/foo.css')
    got.body.strip.should == SpecNodeProvide.new.foo
    got.headers['Content-Type'].should == 'text/css'

    got = get('/provide/bar.sass')
    got.body.strip.should == "body {\n  color: #f00; }"
    got.headers['Content-Type'].should == 'text/css'
  end

  should 'fulfill wish with templates' do
    got = get('/provide_template/bar.css')
    got.headers['Content-Type'].should == 'text/css'
    got.body.strip.should == "body { background: #f00; }"
  end

  should 'fulfill wish with templates' do
    got = get('/provide_template/foo.css')
    got.headers['Content-Type'].should == 'text/css'
    got.body.strip.should == "body {\n  background: #f00; }"
  end
end
