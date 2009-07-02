require File.expand_path('../../helper', __FILE__)

class SpecSession
  Innate.node('/').provide(:html, :None)

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
  behaves_like :rack_test

  should 'initiate session as needed' do
    get '/'
    last_response.body.should == 'No session here'
    last_response['Set-Cookie'].should == nil

    get('/init')
    last_response.body.should == '0'

    1.upto(10) do |n|
      get('/increment').body.should == n.to_s
    end

    get('/reset')
    get('/view').body.should == ''
    get('/init').body.should == '0'

    -1.downto(-10) do |n|
      get('/decrement').body.should == n.to_s
    end
  end

  should 'expose sid method' do
    Innate::Current.session.sid.should.not.be.empty
  end
end
