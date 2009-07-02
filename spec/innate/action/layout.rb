require File.expand_path('../../../helper', __FILE__)

class SpecActionLayout
  include Innate::Node
  map_layouts '/'
end

class SpecActionLayoutMethod < SpecActionLayout
  Innate.node('/from_method', self)
  layout('method_layout')

  def method_layout
    '<pre>#{ @content }</pre>'
  end

  def index
    'Method Layout'
  end

  def foo
    "bar"
  end
end

class SpecActionLayoutFile < SpecActionLayout
  Innate.node('/from_file', self)
  layout('file_layout')

  def index
    "File Layout"
  end
end

class SpecActionLayoutSpecific < SpecActionLayout
  Innate.node('/specific', self)
  layout('file_layout'){|name, wish| name == 'index' }

  def index
    'Specific Layout'
  end

  def without
    "Without wrapper"
  end
end

class SpecActionLayoutDeny < SpecActionLayout
  Innate.node('/deny', self)
  layout('file_layout'){|name, wish| name != 'without' }

  def index
    "Deny Layout"
  end

  def without
    "Without wrapper"
  end
end

class SpecActionLayoutMulti < SpecActionLayout
  Innate.node('/multi', self)
  layout('file_layout'){|name, wish| name =~ /index|second/ }

  def index
    "Multi Layout Index"
  end

  def second
    "Multi Layout Second"
  end

  def without
    "Without wrapper"
  end
end

class SpecIVFromView < SpecActionLayout
  Innate.node('/iv', self)
  layout :multiply

  def index
    '#{ @a = 1 }'
  end

  def multiply
    '#{@content} #{ @a * 2 } #{ @a * 3 }'
  end
end

describe 'Innate::Action#layout' do
  behaves_like :rack_test

  it 'uses a layout method' do
    get('/from_method').body.should == '<pre>Method Layout</pre>'
    get('/from_method/foo').body.should == '<pre>bar</pre>'
  end

  it 'uses a layout file' do
    get('/from_file').body.strip.should == '<p>File Layout</p>'
  end

  it 'denies layout to some actions' do
    get('/deny').body.strip.should == '<p>Deny Layout</p>'
    get('/deny/without').body.strip.should == 'Without wrapper'
  end

  it 'uses layout only for specific action' do
    get('/specific').body.strip.should == '<p>Specific Layout</p>'
    get('/specific/without').body.strip.should == 'Without wrapper'
  end

  it 'uses layout only for specific actions' do
    get('/multi').body.strip.should == '<p>Multi Layout Index</p>'
    get('/multi/second').body.strip.should == '<p>Multi Layout Second</p>'
    get('/multi/without').body.strip.should == 'Without wrapper'
  end

  it 'uses layout only for specific actions' do
    get('/iv').body.strip.should == '1 2 3'
  end
end
