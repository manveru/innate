require 'spec/helper'
require 'innate/helper'

module Innate
  module Helper
    module SmileHelper
      EXPOSE << self

      def smile
        ':)'
      end
    end

    module NoSmileHelper
      def no_smile
        ':('
      end
    end
  end
end

class HelperNodeExpose
  include Innate::Node
  map '/'

  helper :smile_helper, :no_smile_helper
end

describe HelperNodeExpose do
  should 'expose an action' do
    Innate::Mock.get('/smile').body.should == ':)'
    Innate::Mock.get('/no_smile').status.should == 404
  end
end

class FooNodeLink
  include Innate::Node
  map '/foo'

  class_helper :link, :cgi
end

describe Innate::Helper::Link do
  FNL = FooNodeLink
  should 'construct URI from ::r' do
    FNL.r(:index).should == URI('/foo/index')
    FNL.r(:/).should == URI('/foo/')
    FNL.r(:index, :foo => :bar).should == URI('/foo/index?foo=bar')

    uri = FNL.r(:index, :a => :b, :x => :y)
    uri.query.split(';').sort.should == %w[a=b x=y]
  end

  should 'construct link from ::a' do
    FNL.a(:index).should == "<a href='/foo/index'>index</a>"
    FNL.a(:index, :x => :y).should == "<a href='/foo/index?x=y'>index</a>"
    FNL.a('duh/bar', :x => :y).should == "<a href='/foo/duh/bar?x=y'>duh/bar</a>"
    FNL.a('home', :href => FNL.r(:home)).should == "<a href='/foo/home'>home</a>"
  end
end
