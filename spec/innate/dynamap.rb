require File.expand_path('../../helper', __FILE__)

describe Innate::DynaMap do
  @app = lambda{|env| [200, {}, ['pass']] }

  should 'raise if nothing is mapped' do
    lambda{ Innate::DynaMap.call({}) }.should.raise(RuntimeError)
  end

  should 'not raise if nothing is mapped' do
    Innate.map('/', &@app)
    Innate::DynaMap.call('SCRIPT_NAME' => '/').should == [200, {}, ['pass']]
  end

  should 'return mapped object' do
    Innate.at('/').should == @app
  end

  should 'return path to object' do
    Innate.to(@app).should == '/'
  end
end
