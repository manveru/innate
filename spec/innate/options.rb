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

  should 'search in higher scope if key not found' do
    @options.deep.port.should == 7000
  end
end
