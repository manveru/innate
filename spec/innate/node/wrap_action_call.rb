require File.expand_path('../../../helper', __FILE__)

SPEC_WRAP_LOG = []

class SpecWrapActionCall
  Innate.node '/'

  def first; end
  def second; end
  def third; end

  private

  def wrap_before(action)
    SPEC_WRAP_LOG << [:before, action.name]
    yield
  end

  def wrap_after(action)
    SPEC_WRAP_LOG << [:after, action.name]
    yield
  end
end

class SpecWrapActionCallStop
  Innate.node '/stop'

  def index; 'Hello'; end

  def wrap_pass(action)
    yield
  end

  def wrap_stop(action)
    'No Hello'
  end
end


describe 'Node#wrap_action_call' do
  behaves_like :rack_test

  it 'executes our wrapper' do
    SPEC_WRAP_LOG.clear
    SpecWrapActionCall.add_action_wrapper(2.0, :wrap_after)

    get('/first')
    SPEC_WRAP_LOG.should == [[:after, 'first']]

    get('/second')
    SPEC_WRAP_LOG.should == [[:after, 'first'], [:after, 'second']]

    get('/third')
    SPEC_WRAP_LOG.should == [[:after, 'first'], [:after, 'second'], [:after, 'third']]
  end

  it 'executes wrappers in correct order' do
    SPEC_WRAP_LOG.clear
    SpecWrapActionCall.add_action_wrapper(1.0, :wrap_before)

    get('/first')
    SPEC_WRAP_LOG.should == [[:before, 'first'], [:after, 'first']]

    get('/second')
    SPEC_WRAP_LOG.should == [
      [:before, 'first'], [:after, 'first'],
      [:before, 'second'], [:after, 'second']]

    get('/third')
    SPEC_WRAP_LOG.should == [
      [:before, 'first'], [:after, 'first'],
      [:before, 'second'], [:after, 'second'],
      [:before, 'third'], [:after, 'third']]
  end

  it 'stops in the chain when not yielded' do
    SpecWrapActionCallStop.add_action_wrapper(1.0, :wrap_pass)
    get('/stop').body.should == 'Hello'

    SpecWrapActionCallStop.add_action_wrapper(2.0, :wrap_stop)
    get('/stop').body.should == 'No Hello'
  end
end
