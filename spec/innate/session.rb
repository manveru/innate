require 'spec/helper'

class SpecSession
  Innate.node('/').provide(:html => :none)

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

describe Innate::Session do
  behaves_like :session

  should 'initiate session as needed' do
    session do |mock|
      response = mock.get('/')
      response.body.should == 'No session here'
      response['Set-Cookie'].should == nil

      mock.get('/init').body.should == '0'

      1.upto(10) do |n|
        mock.get('/increment').body.should == n.to_s
      end

      mock.get('/reset')
      mock.get('/view').body.should == ''
      mock.get('/init').body.should == '0'

      -1.downto(-10) do |n|
        mock.get('/decrement').body.should == n.to_s
      end
    end
  end
end
