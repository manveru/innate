require File.expand_path('../../helper', __FILE__)

Options = Innate::Options

describe Options do
  @options = Innate::Options.new(:spec)

  should 'create option' do
    @options.o('my name', :name, 'manveru')
    @options.name.should == 'manveru'
  end

  should 'create options with meta hash' do
    @options.o('the port', :port, 7000, :cli => '-p')
    @options.port.should == 7000
  end

  should 'get complete hash via #get' do
    @options.get(:port)[:cli].should == '-p'
    @options.get(:port)[:doc].should == 'the port'
  end

  should 'get value via []' do
    @options[:port].should == 7000
  end

  should 'create scope' do
    @options.sub(:deep)
    @options.deep.should.not.be.nil
  end

  should 'create option in scope' do
    @options.deep.o('the browser', :browser, :firefox)
    @options.deep.browser.should == :firefox
  end

  should 'append to scope via dsl' do
    @options.sub(:deep).o('hi mom', :greeting, :mom)
    @options.deep.greeting.should == :mom
  end

  should 'sub in subscope' do
    @options.sub(:deep).sub(:down).o('deep down', :me, :too)
    @options.deep.down.me.should == :too
  end

  should 'get sub-sub option' do
    @options.get(:deep, :down, :me).
      should == {:value => :too, :doc => 'deep down'}
  end

  should 'respond with nil on getting missing option' do
    @options.get(:deep, :down, :you).should.be.nil
  end

  should 'search in higher scope if key not found' do
    @options.deep.port.should == 7000
  end

  should '#set_value to set a nested value directly' do
    @options.set_value([:deep, :down, :me], 'me deep down')
    @options.deep.down.me.should == 'me deep down'
  end

  should 'merge! existing options with other Enumerable' do
    @options.merge!(:port => 4000, :name => 'feagliir')
    @options.port.should == 4000
    @options.name.should == 'feagliir'
  end

  should 'iterate via #each_pair' do
    given_keys = [:deep, :name, :port]
    given_values = [@options[:deep], @options[:name], @options[:port]]

    @options.each_pair do |key, value|
      given_keys.delete(key)
      given_values.delete(value)
    end

    given_keys.should.be.empty
    given_values.should.be.empty
  end

  should 'iterate via #each_option' do
    given_keys = [:deep, :name, :port]
    given_values = [@options.get(:deep), @options.get(:name), @options.get(:port)]

    @options.each_option do |key, option|
      given_keys.delete(key)
      given_values.delete(option)
    end

    given_keys.should.be.empty
    given_values.should.be.empty
  end

  should "raise when trying to assign to key that doesn't exist" do
    lambda{ @options[:foo] = :bar }.should.raise(ArgumentError)
  end

  should "raise when trying to assign to an option that doesn't exist" do
    lambda{ @options.merge!(:foo => :bar) }.should.raise(IndexError)
  end

  should 'pretty_print' do
    require 'pp'
    p = PP.new
    @options.pretty_print(p)
    lines = p.output.split(/\n/)
    lines.find_all{|l|
      /:doc/ === l &&
      /:value/ === l
    }.size.should > 3
  end

  should 'trigger block when option is changed' do
    set = nil
    @options.trigger(:port){|value| set = value }
    set.should.be.nil
    @options.port = 300
    set.should == 300
  end
end
