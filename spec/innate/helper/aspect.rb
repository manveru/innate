require 'spec/helper'

class AspectSpec
  include Innate::Node
  map '/'
  provide :html => :none

  before(:with_before){ $aspect_spec_before += 40 }
  def with_before; $aspect_spec_before += 2; end

  after(:with_after){ $aspect_spec_after  += 40 }
  def with_after; $aspect_spec_after += 2; end

  wrap(:with_wrap){ $aspect_spec_wrap += 20 }
  def with_wrap; $aspect_spec_wrap += 2; end
end

describe Innate::Helper::Aspect do
  behaves_like :mock

  should 'execute before aspect' do
    $aspect_spec_before = 0
    get('/with_before').body.should == '42'
    $aspect_spec_before.should == 42
  end

  should 'execute after asepct' do
    $aspect_spec_after = 0
    get('/with_after').body.should == '2'
    $aspect_spec_after.should == 42
  end

  should 'execute wrap aspects' do
    $aspect_spec_wrap = 0
    get('/with_wrap').body.should == '22'
    $aspect_spec_wrap == 42
  end
end
