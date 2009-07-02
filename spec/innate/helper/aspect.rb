require File.expand_path('../../../helper', __FILE__)

class AspectSpec
  Innate.node('/', self).provide(:html, :None)

  before(:with_before){ $aspect_spec_before += 40 }
  def with_before; $aspect_spec_before += 2; end

  after(:with_after){ $aspect_spec_after  += 40 }
  def with_after; $aspect_spec_after += 2; end

  wrap(:with_wrap){ $aspect_spec_wrap += 20 }
  def with_wrap; $aspect_spec_wrap += 2; end

  before(:with_instance_var){ @foo = 'Hello'; @bar = 'World' }
  def with_instance_var; "#{@foo} #{@bar}"; end
end

class AspectAllSpec
  Innate.node('/all', self).provide(:html, :None)

  before_all{ $aspect_spec_before_all += 40; @foo = 'Hello'; @bar = 'World' }
  after_all{  $aspect_spec_after_all += 40 }
  def before_first; $aspect_spec_before_all +=2 ; end
  def before_second; $aspect_spec_before_all +=2; end
  def with_instance_var_first; "#{@foo} #{@bar}"; end
  def with_instance_var_second; "#{@foo} to the #{@bar}"; end
end

class AspecNoMethodSpec
  Innate.node('/without_method', self)
  include Innate::Node
  map '/without_method'
  map_views '/'
  before_all{ @foo = 'Hello'; @bar = 'World'}
end

describe Innate::Helper::Aspect do
  behaves_like :rack_test

  it 'executes before aspect' do
    $aspect_spec_before = 0
    get('/with_before').body.should == '42'
    $aspect_spec_before.should == 42
  end

  it 'executes after asepct' do
    $aspect_spec_after = 0
    get('/with_after').body.should == '2'
    $aspect_spec_after.should == 42
  end

  it 'executes wrap aspects' do
    $aspect_spec_wrap = 0
    get('/with_wrap').body.should == '22'
    $aspect_spec_wrap == 42
  end

  it 'calls before_all and after_all' do
    $aspect_spec_before_all = $aspect_spec_after_all = 0
    get('/all/before_first').body.should == '42'
    $aspect_spec_before_all.should == 42
    $aspect_spec_after_all.should == 40
    get('/all/before_second').body.should == '84'
    $aspect_spec_before_all.should == 84
    $aspect_spec_after_all.should == 80
  end

  it 'makes instance variables in blocks available to view/method' do
    get('/with_instance_var').body.should == 'Hello World'
    get('/all/with_instance_var_first').body.should == 'Hello World'
    get('/all/with_instance_var_second').body.should == 'Hello to the World'
    get('/without_method/aspect_hello').body.should == "Hello World!"
  end
end
