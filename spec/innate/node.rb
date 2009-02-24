require 'spec/helper'

Innate.options.app.root = File.dirname(__FILE__)
Innate.options.app.view = ''
Innate.options.app.layout = 'node'

class SpecNode
  Innate.node('/').provide(:html => :erb, :erb => :none)

  def foo; end
  def bar; end
  def one(arg) end
  def two(arg1, arg2) end
  def more(*args) end
  def default(arg = nil) end
end

class SpecNodeProvide
  Innate.node('/provide').provide(:html => :erb, :erb => :none)

  def foo
    '<%= 21 * 2 %>'
  end

  def bar
    '<%= 84 / 2 %>'
  end
end

class SpecNodeProvideTemplate
  Innate.node('/provide_template')
  provide(:html => :erb, :erb => :none, :yaml => :yaml, :json => :json)

  view_root 'node'
end

class SpecNodeSub < SpecNode
  map '/sub'

  def bar(arg) end
end

class SpecNodeWithLayout < SpecNodeProvide
  layout 'with_layout'
  map '/layout'
end

class SpecNodeWithLayoutView < SpecNodeProvide
  view_root 'node/another_layout'
  layout 'another_layout'
  map '/another_layout'
end

class SpecNodeWithLayoutMethod < SpecNodeProvide
  map '/layout_method'
  layout 'layout_method'

  def layout_method
    '<div class="content"><%= @content %></div>'
  end
end

class SpecNodeIndex
  Innate.node('/spec_index')

  def index
    "I have no parameters"
  end
end

class SpecNodeAliasView < SpecNodeProvideTemplate
  map '/alias_view'
  view_root 'node'

  alias_view :aliased, :bar
end

describe 'Innate::Node' do
  behaves_like :mock

  def compare(url, hash)
    result = SpecNode.resolve(url)
    result.should.not.be.nil
    hash.each do |key, value|
      result[key.to_s].should == value
    end
  end

  def assert_wish(url, body, content_type)
    got = get(url)
    got.body.strip.should == body
    got.headers['Content-Type'].should == content_type
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

  should 'inherit action methods from superclasses' do
    SpecNodeSub.resolve('/foo').should.not.be.nil
    SpecNodeSub.resolve('/foo/one/two').should.be.nil
  end

  should 'select correct method from subclasses' do
    SpecNodeSub.resolve('/bar/one').should.not.be.nil
    SpecNodeSub.resolve('/bar').should.be.nil
  end

  should 'provide html if no wish given' do
    assert_wish('/provide/foo', '42', 'text/html')
    assert_wish('/provide/bar', '42', 'text/html')
  end

  should 'provide html as wished' do
    assert_wish('/provide/foo.html', '42', 'text/html')
    assert_wish('/provide/bar.html', '42', 'text/html')
  end

  should 'provide erb as wished' do
    assert_wish('/provide/foo.erb', "<%= 21 * 2 %>", 'text/html')
    assert_wish('/provide/bar.erb', "<%= 84 / 2 %>", 'text/html')
  end

  should 'fulfill wish with templates' do
    assert_wish('/provide_template/bar.html', "<h1>Hello, World!</h1>",
                'text/html')
    assert_wish('/provide_template/bar.erb', "<h1>Hello, World!</h1>",
                'text/html')

    expected = '0123456789'
    assert_wish('/provide_template/foo.html', expected, 'text/html')
    # assert_wish('/provide_template/foo.erb', expected, 'text/plain')
  end

  should 'respond with 404 if no action was found' do
    got = Innate::Mock.get('/does_not_exist')
    got.status.should == 404
    got.body.should == 'No action found at: "/does_not_exist"'
    got['Content-Type'].should == 'text/plain'
  end

  should 'respond with yaml' do
    assert_wish('/provide_template/bar.yaml', "--- |\n<h1>Hello, World!</h1>",
                'text/yaml')
  end

  should 'respond with json' do
    assert_wish('/provide_template/bar.json', '"<h1>Hello, World!<\\/h1>\\n"',
                'application/json')
  end

  should 'wrap with layout' do
    got = Innate::Mock.get('/layout/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">\n  42\n</div>\n)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout with view_root' do
    got = Innate::Mock.get('/another_layout/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">\n  42\n</div>\n)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout from method' do
    got = Innate::Mock.get('/layout_method/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">42</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'not get an action with wrong parameters' do
    got = Innate::Mock.get('/spec_index/bar')
    got.status.should == 404
    got.body.should == 'No action found at: "/bar"'
  end

  should 'get an action view if there is no method' do
    got = Innate::Mock.get('/provide_template/only_view')
    got.status.should == 200
    got.body.strip.should == "Only template"
  end

  should 'not get an action view with params if there is no method' do
    got = Innate::Mock.get('/provide_template/only_view/param')
    got.status.should == 404
    got.body.strip.should == 'No action found at: "/only_view/param"'
  end

  should 'use alias_view' do
    assert_wish('/alias_view/aliased', "<h1>Hello, World!</h1>", 'text/html')
  end
end
