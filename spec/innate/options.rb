require 'lib/innate/core_compatibility/basic_object'
require 'lib/innate/options/dsl'

require 'bacon'

Bacon.extend(Bacon::TestUnitOutput)
Bacon.summary_on_exit

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
    @options.get(:deep, :down, :me).should == {:value => :too, :doc => 'deep down'}
  end

  should 'respond with nil on getting missing option' do
    @options.get(:deep, :down, :you).should.be.nil
  end

  should 'search in higher scope if key not found' do
    @options.deep.port.should == 7000
  end

  should 'merge! existing options with other Enumerable' do
    @options.merge!(:port => 4000, :name => 'feagliir')
    @options.port.should == 4000
    @options.name.should == 'feagliir'
  end

  should 'Be Enumerable' do
    keys, values = [], []

    @options.each{|k, v| keys << k; values << v }

    keys.compact.sort_by{|k| k.to_s }.should == [:deep, :name, :port]
    values.compact.size.should == 3
  end

  should "raise when trying to assign to key that doesn't exist" do
    lambda{ @options[:foo] = :bar }.should.raise(ArgumentError)
  end

  should 'pretty_print' do
    require 'pp'
    p = PP.new
    @options.pretty_print(p)
    p.output.should =~ /:value=>4000/
  end
end
