require File.expand_path('../../helper', __FILE__)
require File.expand_path('../../../example/session', __FILE__)

describe 'example/session' do
  behaves_like :rack_test

  it 'starts at 0' do
    get('/').body.should =~ /Value is: 0/
  end

  it 'increments the counter' do
    get('/increment').body.should =~ /Value is: 1/
    get('/increment').body.should =~ /Value is: 2/
    get('/increment').body.should =~ /Value is: 3/
  end

  it 'decrements the counter' do
    get('/decrement').body.should =~ /Value is: 2/
    get('/decrement').body.should =~ /Value is: 1/
    get('/decrement').body.should =~ /Value is: 0/
  end
end
