require 'spec/helper'

describe 'Innate::State::Fiber' do
  begin
    require 'fiber'
  rescue LoadError
    it('needs fiber'){ should.flunk('needed fiber') }
    exit
  end

  F = Innate::State::Fiber

  it 'sets value in current thread with #[]=' do
    Innate::Fiber.new{
      t = F.new
      t[:a] = :b
      Fiber.current[:a].should == :b
    }.resume
  end

  it 'gets value in current thread with #[]' do
    Innate::Fiber.new{
      t = F.new
      Fiber.current[:b] = :c
      t[:b].should == :c
    }.resume
  end

  it 'executes block in #wrap' do
    Innate::Fiber.new{
      t = F.new
      t.wrap{ :foo }.should == :foo
    }.resume
  end

  it 'reraises exceptions occured in #wrap thread' do
    Innate::Fiber.new{
      t = F.new
      Thread.abort_on_exception = false
      lambda{ t.wrap{ raise 'foo' } }.should.raise
    }.resume
  end

  it 'defers execution of passed block in #defer' do
    Innate::Fiber.new{
      t = F.new
      t.defer{ :foo }.value.should == :foo
    }.resume
  end

  it 'copies thread variables to thread spawned in #defer' do
    Innate::Fiber.new{
      t = F.new
      t[:a] = :b
      t.defer{ Fiber.current[:a] }.value.should == :b
    }.resume
  end
end
