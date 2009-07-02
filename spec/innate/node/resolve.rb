require File.expand_path('../../../helper', __FILE__)

class SpecNodeResolve
  Innate.node('/')

  def foo; end
  def bar; end
  def one(arg) end
  def two(arg1, arg2) end
  def more(*args) end
  def default(arg = nil) end
end

class SpecNodeResolveSub < SpecNodeResolve
  map '/sub'

  def bar(arg) end
end

class SpecNodeResolveIndex
  Innate.node('/arg')

  def index(arg) end
end

describe 'Node.resolve' do
  def compare(url, hash)
    result = SpecNodeResolve.resolve(url)
    result.should.not.be.nil
    hash.each do |key, value|
      result[key.to_s].should == value
    end
  end

  should 'resolve actions with methods' do
    SpecNodeResolve.resolve('/').should.be.nil
    SpecNodeResolve.resolve('/index').should.be.nil

    compare '/foo', :method => 'foo', :params => []
    SpecNodeResolve.resolve('/foo/one/two').should.be.nil

    compare '/bar', :method => 'bar', :params => []
    SpecNodeResolve.resolve('/bar/one').should.be.nil

    SpecNodeResolve.resolve('/one').should.be.nil
    compare '/one/1', :method => 'one', :params => ['1']
    SpecNodeResolve.resolve('/one/1/2').should.be.nil
    SpecNodeResolve.resolve('/one/1/2/3').should.be.nil

    SpecNodeResolve.resolve('/two').should.be.nil
    SpecNodeResolve.resolve('/two/1').should.be.nil
    compare '/two/1/2', :method => 'two', :params => %w[1 2]
    SpecNodeResolve.resolve('/two/1/2/3').should.be.nil

    compare '/more', :method => 'more', :params => []
    compare '/more/1', :method => 'more', :params => %w[1]
    compare '/more/1/2', :method => 'more', :params => %w[1 2]
    compare '/more/1/2/3', :method => 'more', :params => %w[1 2 3]

    compare '/default', :method => 'default', :params => []
    compare '/default/1', :method => 'default', :params => %w[1]

    # NOTE: these are actually bound to fail when called, but we cannot
    #       introspect enough to anticipate this failure
    compare '/default/1/2', :method => 'default', :params => %w[1 2]
    compare '/default/1/2/3', :method => 'default', :params => %w[1 2 3]
  end

  should 'inherit action methods from superclasses' do
    SpecNodeResolveSub.resolve('/foo').should.not.be.nil
    SpecNodeResolveSub.resolve('/foo/one/two').should.be.nil
  end

  should 'select correct method from subclasses' do
    SpecNodeResolveSub.resolve('/bar/one').should.not.be.nil
    SpecNodeResolveSub.resolve('/bar').should.be.nil
  end

  it "doesn't select index as action with index parameter if arity is 1" do
    SpecNodeResolveIndex.resolve('/index').should.be.nil
  end
end
