require 'spec/helper'
require 'example/session'

describe 'example/session' do
  behaves_like :session

  it 'starts at 0' do
    session do |mock|
      mock.get('/').should =~ /Value is: 0/
    end
  end

  it 'increments the counter' do
    session do |mock|
      mock.get('/increment').should =~ /Value is: 1/
      mock.get('/increment').should =~ /Value is: 2/
      mock.get('/increment').should =~ /Value is: 3/
    end
  end

  it 'decrements the counter' do
    session do |mock|
      mock.get('/decrement').should =~ /Value is: -1/
      mock.get('/decrement').should =~ /Value is: -2/
      mock.get('/decrement').should =~ /Value is: -3/
    end
  end
end
