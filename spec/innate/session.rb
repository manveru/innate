require 'spec/helper'

class SessionSpec
  include Innate::Node
  map '/'

  def index
    'No session here'
  end

  def init
    session[:counter] = 0
  end

  def view
    session[:counter]
  end

  def increment
    session[:counter] += 1
  end

  def decrement
    session[:counter] -= 1
  end

  def reset
    session.clear
  end
end

describe 'Innate::Session' do
  def session
    Innate::Mock.session do |session|
      yield(session)
    end
  end

  should 'initiate session as needed' do
    session do |s|
      response = s.get('/')
      response.body.should == 'No session here'
      response['Set-Cookie'].should == nil

      s.get('/init').body.should == '0'

      1.upto(10) do |n|
        s.get('/increment').body.should == n.to_s
      end

      s.get('/reset')
      s.get('/view').body.should == ''
      s.get('/init').body.should == '0'

      -1.downto(-10) do |n|
        s.get('/decrement').body.should == n.to_s
      end
    end
  end
end
