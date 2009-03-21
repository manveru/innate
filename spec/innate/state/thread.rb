require 'spec/helper'

describe Innate::State::Thread do
  T = Innate::State::Thread

  it 'sets value in current thread with #[]=' do
    t = T.new
    t[:a] = :b
    Thread.current[:a].should == :b
  end

  it 'gets value in current thread with #[]' do
    t = T.new
    Thread.current[:b] = :c
    t[:b].should == :c
  end

  it 'executes block in #wrap' do
    t = T.new
    t.wrap{ :foo }.should == :foo
  end

  it 'reraises exceptions occured in #wrap thread' do
    t = T.new
    Thread.abort_on_exception = false
    lambda{ t.wrap{ raise 'foo' } }.should.raise
  end

  it 'defers execution of passed block in #defer' do
    t = T.new
    t.defer{ :foo }.value.should == :foo
  end

  it 'copies thread variables to thread spawned in #defer' do
    t = T.new
    t[:a] = :b
    t.defer{ Thread.current[:a] }.value.should == :b
  end
end
