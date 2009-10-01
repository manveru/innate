require File.expand_path('../../../helper', __FILE__)

Innate.options.merge!(:views => 'view', :layouts => 'view')

class SpecNode
  Innate.node('/')

  def foo; end
  def bar; end
  def one(arg) end
  def two(arg1, arg2) end
  def more(*args) end
  def default(arg = nil) end

  def cat1__cat11
    'cat1: cat11'
  end

  def cat1__cat11__cat111
    'cat1: cat11: cat111'
  end

  def cat3_cat33
    'The wrong 33rd cat.'
  end
end

class SpecNodeProvide
  Innate.node('/provide')

  def foo
    '#{21 * 2}'
  end

  def bar
    '#{84 / 2}'
  end
end

class SpecNodeProvideTemplate
  Innate.node('/provide_template')

  map_views '/'
end

class SpecNodeSub < SpecNode
  map '/sub'

  def bar(arg) end
end

class SpecNodeWithLayout < SpecNodeProvide
  map '/layout'
  layout 'with_layout'

  map_layouts '/'
end

class SpecNodeWithLayoutView < SpecNodeProvide
  map '/another_layout'
  layout 'another_layout'

  map_views 'node/another_layout'
  map_layouts 'another_layout'
end

class SpecNodeWithLayoutMethod < SpecNodeProvide
  map '/layout_method'
  layout 'layout_method'

  def layout_method
    '<div class="content">#{@content}</div>'
  end
end

class SpecNodeWithLayoutMethodSymbol < SpecNodeProvide
  map '/layout_method_symbol'
  layout :layout_method

  def layout_method
    '<div class="content">#{@content}</div>'
  end
end

class SpecNodeWithLayoutMethodSymbolAndBlock < SpecNodeProvide
  map '/layout_method_symbol_block'
  layout(:layout_method) { |wish,path| true }

  def layout_method
    '<div class="content">#{@content}</div>'
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
  map_views '/'

  alias_view :aliased, :bar
end

describe 'Innate::Node' do
  behaves_like :rack_test

  should 'respond with 404 if no action was found' do
    got = get('/does_not_exist')
    got.status.should == 404
    got.body.should == 'No action found at: "/does_not_exist"'
    got['Content-Type'].should == 'text/plain'
  end

  should 'wrap with layout' do
    got = get('/layout/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">42</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout with view_root' do
    got = get('/another_layout/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">\n  42\n</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout from method' do
    got = get('/layout_method/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">42</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout from method specified as a symbol' do
    got = get('/layout_method_symbol/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">42</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'find layout from method specified as a symbol and a filter block' do
    got = get('/layout_method_symbol_block/bar')
    got.status.should == 200
    got.body.should == %(<div class="content">42</div>)
    got['Content-Type'].should == 'text/html'
  end

  should 'not get an action with wrong parameters' do
    got = get('/spec_index/bar')
    got.status.should == 404
    got.body.should == 'No action found at: "/bar"'
  end

  should 'get an action view if there is no method' do
    got = get('/provide_template/only_view')
    got.status.should == 200
    got.body.strip.should == "Only template"
    got['Content-Type'].should == 'text/html'
  end

  should 'not get an action view with params if there is no method' do
    got = get('/provide_template/only_view/param')
    got.status.should == 404
    got.body.strip.should == 'No action found at: "/only_view/param"'
  end

  should 'use alias_view' do
    got = get('/alias_view/aliased')
    got.status.should == 200
    got.body.strip.should == "<h1>Hello, World!</h1>"
    got['Content-Type'].should == 'text/html'
  end

  it "does double underscore lookup for method only" do
    got = get('/cat1/cat11')
    got.body.should == 'cat1: cat11'
  end

  it "does double double underscore lookup for method only" do
    got = get('/cat1/cat11/cat111')
    got.body.should == 'cat1: cat11: cat111'
  end

  it "resolves double underscore for template only" do
    got = get('/cat2/cat22')
    got.body.should == 'The 22nd cat.'
  end

  it "resolves double underscore for template and method" do
    got = get('/cat3/cat33')
    got.body.should == 'The right 33rd cat.'
  end

  it 'resolves normal template in subnode ' do
    got = get('/sub/baz')
    got.body.should == 'This is baz, cheer up!'
  end

  it 'resolves nested template in subnode' do
    got = get('/sub/foo/baz')
    got.body.should == 'This is foo/baz, cheer up!'
  end
end
