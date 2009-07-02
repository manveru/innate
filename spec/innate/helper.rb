require File.expand_path('../../helper', __FILE__)
require 'innate/helper'

module Innate
  module Helper
    module SmileHelper
      EXPOSE << self

      def smile
        ':)'
      end
    end

    module FrownHelper
      def frown
        ':('
      end
    end
  end
end

class HelperNodeExpose
  include Innate::Node
  map '/'

  helper :smile_helper, :frown_helper

  def frowny
    "Oh, hi #{frown}"
  end
end

describe HelperNodeExpose do
  should 'expose an action' do
    Innate::Mock.get('/smile').body.should == ':)'
    Innate::Mock.get('/frown').status.should == 404
    Innate::Mock.get('/frowny').body.should == "Oh, hi :("
  end
end

class FooNodeLink
  include Innate::Node
  map '/foo'

  helper :link, :cgi
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
    FNL.a(:index).should == '<a href="/foo/index">index</a>'
    FNL.a('index', :index, :x => :y).should == '<a href="/foo/index?x=y">index</a>'
    FNL.a('duh/bar', 'duh/bar', :x => :y).should == '<a href="/foo/duh/bar?x=y">duh/bar</a>'
    FNL.a('foo', :/, :x => :y).should == '<a href="/foo/?x=y">foo</a>'
  end

  should 'return module when Module is given to #each' do
    Innate::HelpersHelper.each_extend(self, Innate::Helper::Link) do |p|
      p.should == Innate::Helper::Link
    end
  end

  should 'raise if helpers are not found' do
    lambda{
      Innate::HelpersHelper.each(:foo, :bar)
    }.should.raise(LoadError).
      message.should == "Helper foo not found"
  end

  should 'raise if helper is not found' do
    lambda{
      Innate::HelpersHelper.try_require(:foo)
    }.should.raise(LoadError).
      message.should == "Helper foo not found"
  end
end
